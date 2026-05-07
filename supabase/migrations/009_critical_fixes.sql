-- ============================================================
-- Migration 009: Critical fixes from internal review
--
-- Addresses:
--   1. HN generation race condition          (Critical)
--   2. Stock deduction race condition         (Critical)
--   3. Treatment + inventory atomic write     (Critical)
--   4. PIN hash format enforcement            (Critical)
--   5. Financial amount + course session      (High)
--   6. RLS performance & supporting indexes   (High)
--   7. GIN indexes on TEXT[] columns          (High)
--   8. Course sessions auto-create trigger    (High)
--   9. Optimistic-concurrency version column  (High)
--  10. N+1 eliminator RPCs (today revenue,    (High)
--      patient profile aggregator)
--  11. ilike escape helper                    (High)
--
-- All statements idempotent (safe to re-run).
-- ============================================================

-- ============================================================
-- 1. HN generation — race-safe via advisory transaction lock
--    Reference: skills supabase-postgres-best-practices/lock-advisory.md
-- ============================================================

CREATE OR REPLACE FUNCTION generate_patient_hn()
RETURNS TRIGGER AS $$
DECLARE
  current_year INT;
  next_num INT;
BEGIN
  IF NEW.hn IS NOT NULL THEN
    RETURN NEW;
  END IF;

  current_year := EXTRACT(YEAR FROM COALESCE(NEW.created_at, now()))::INT;

  -- Serialise concurrent inserts within the same (clinic, year) bucket.
  -- The lock is automatically released when the surrounding transaction
  -- commits or rolls back, so it cannot leak.
  PERFORM pg_advisory_xact_lock(
    hashtextextended(NEW.clinic_id::text || ':' || current_year::text, 0)
  );

  SELECT COALESCE(
           MAX(
             CASE
               WHEN hn ~ ('^C-' || current_year::TEXT || '-[0-9]+$')
               THEN CAST(SUBSTRING(hn FROM ('^C-' || current_year::TEXT || '-([0-9]+)$')) AS INT)
               ELSE 0
             END
           ),
           0
         ) + 1
    INTO next_num
    FROM patients
   WHERE clinic_id = NEW.clinic_id;

  NEW.hn := 'C-' || current_year::TEXT || '-' || LPAD(next_num::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 2. Atomic stock deduction RPC
--    Replaces client-side read-modify-write pattern.
--    Returns the new stock_quantity, or raises on insufficient stock.
-- ============================================================

CREATE OR REPLACE FUNCTION deduct_stock_atomic(
  p_product_id UUID,
  p_quantity   NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY INVOKER  -- runs with caller's RLS scope
AS $$
DECLARE
  v_new_qty NUMERIC;
BEGIN
  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'quantity_must_be_positive'
      USING ERRCODE = '22023', HINT = 'Quantity must be > 0';
  END IF;

  UPDATE products
     SET stock_quantity = stock_quantity - p_quantity
   WHERE id = p_product_id
     AND stock_quantity >= p_quantity
   RETURNING stock_quantity INTO v_new_qty;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'insufficient_stock'
      USING ERRCODE = 'P0001',
            HINT = 'Stock is below requested quantity or product not found';
  END IF;

  RETURN v_new_qty;
END;
$$;

COMMENT ON FUNCTION deduct_stock_atomic IS
  'Atomically deduct stock from a product. Raises insufficient_stock if quantity > current stock.';

-- ============================================================
-- 3. Treatment + inventory atomic save RPC
--    Wraps the multi-table write in a single Postgres transaction.
--    Inventory format:
--      [{"product_id": "uuid", "quantity": 1.5, "unit": "ml",
--        "transaction_type": "USED", "batch_no": "...", "notes": "..."}]
--    Returns the inserted treatment_record row as JSONB.
-- ============================================================

CREATE OR REPLACE FUNCTION record_treatment_atomic(
  p_treatment JSONB,
  p_inventory JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_treatment treatment_records%ROWTYPE;
  v_op        JSONB;
  v_qty       NUMERIC;
  v_product   UUID;
  v_tx_type   inventory_transaction_type;
BEGIN
  -- Insert treatment record. We list every input-settable column explicitly
  -- (and use COALESCE to fall back to column defaults for the auto-managed
  -- ones) so callers who supply a client-generated UUID still get to keep it
  -- — important for the offline-first flow where audit logs and follow-up
  -- references already point at that UUID. Using `SELECT *` would NULL out
  -- the auto-managed columns and break NOT NULL constraints.
  INSERT INTO treatment_records (
    id,
    clinic_id, patient_id, doctor_id, appointment_id,
    date, category, treatment_name,
    chief_complaint, objective, assessment, plan,
    vitals, device, energy, pulse_spot, total_shots,
    products_used, actual_units_used,
    response_to_previous, adverse_events, instructions,
    follow_up_date, follow_up_time, diagram_url,
    notes, commission_status
  )
  SELECT
    COALESCE(r.id, gen_random_uuid()),
    r.clinic_id, r.patient_id, r.doctor_id, r.appointment_id,
    r.date, r.category, r.treatment_name,
    r.chief_complaint, r.objective, r.assessment, r.plan,
    r.vitals, r.device, r.energy, r.pulse_spot, r.total_shots,
    r.products_used, r.actual_units_used,
    r.response_to_previous, r.adverse_events, r.instructions,
    r.follow_up_date, r.follow_up_time, r.diagram_url,
    r.notes, r.commission_status
  FROM jsonb_populate_record(NULL::treatment_records, p_treatment) AS r
  RETURNING * INTO v_treatment;

  -- Walk inventory ops
  IF jsonb_typeof(p_inventory) = 'array' THEN
    FOR v_op IN SELECT * FROM jsonb_array_elements(p_inventory)
    LOOP
      v_product := (v_op->>'product_id')::UUID;
      v_qty     := (v_op->>'quantity')::NUMERIC;
      v_tx_type := COALESCE((v_op->>'transaction_type')::inventory_transaction_type,
                            'USED'::inventory_transaction_type);

      -- Atomic stock deduct only for USED / WASTAGE
      IF v_tx_type IN ('USED', 'WASTAGE') THEN
        PERFORM deduct_stock_atomic(v_product, v_qty);
      ELSIF v_tx_type = 'STOCK_IN' THEN
        UPDATE products SET stock_quantity = stock_quantity + v_qty
         WHERE id = v_product;
      END IF;

      INSERT INTO inventory_transactions (
        clinic_id, product_id, treatment_record_id, patient_id,
        transaction_type, quantity, unit, batch_no, notes, created_by
      ) VALUES (
        v_treatment.clinic_id,
        v_product,
        v_treatment.id,
        v_treatment.patient_id,
        v_tx_type,
        v_qty,
        v_op->>'unit',
        v_op->>'batch_no',
        v_op->>'notes',
        NULLIF(v_op->>'created_by', '')::UUID
      );
    END LOOP;
  END IF;

  RETURN to_jsonb(v_treatment);
END;
$$;

COMMENT ON FUNCTION record_treatment_atomic IS
  'Insert a treatment_records row plus its inventory_transactions in a single transaction. Stock checks use deduct_stock_atomic.';

-- ============================================================
-- 4. PIN hash format enforcement
--    Only bcrypt-format strings are allowed in pin_hash.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'staff_pin_hash_format'
       AND conrelid = 'public.staff'::regclass
  ) THEN
    -- bcrypt produces $2a$/$2b$/$2y$ prefixes; allow NULL (no PIN set yet)
    ALTER TABLE staff
      ADD CONSTRAINT staff_pin_hash_format
      CHECK (pin_hash IS NULL OR pin_hash ~ '^\$2[aby]\$[0-9]{2}\$');
  END IF;
END $$;

-- ============================================================
-- 5. Financial amount + course session integrity
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'financial_records_amount_nonneg'
       AND conrelid = 'public.financial_records'::regclass
  ) THEN
    ALTER TABLE financial_records
      ADD CONSTRAINT financial_records_amount_nonneg CHECK (amount >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'course_sessions_unique_number'
       AND conrelid = 'public.course_sessions'::regclass
  ) THEN
    ALTER TABLE course_sessions
      ADD CONSTRAINT course_sessions_unique_number
      UNIQUE (course_id, session_number);
  END IF;
END $$;

-- ============================================================
-- 6. RLS performance — wrap auth.uid() in SELECT for caching
--    Reference: skills security-rls-performance.md
-- ============================================================

CREATE OR REPLACE FUNCTION get_my_clinic_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  -- Wrapping auth.uid() in (SELECT ...) lets the planner treat it as a
  -- one-shot initplan instead of evaluating per row.
  -- Adding is_active filter prevents terminated staff from accessing data.
  SELECT clinic_id
    FROM staff
   WHERE user_id = (SELECT auth.uid())
     AND is_active = true
$$;

CREATE OR REPLACE FUNCTION get_my_role(p_clinic_id UUID)
RETURNS staff_role
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role
    FROM staff
   WHERE user_id = (SELECT auth.uid())
     AND clinic_id = p_clinic_id
     AND is_active = true
   LIMIT 1
$$;

-- Composite index supporting the function bodies above.
CREATE INDEX IF NOT EXISTS idx_staff_user_active
  ON staff(user_id, is_active)
  WHERE is_active = true;

-- ============================================================
-- 7. GIN indexes for TEXT[] columns used by safety checks
--    Without these, ANY(...) / && / @> on arrays do seq scans.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_patient_drug_allergies
  ON patients USING GIN (drug_allergies);

CREATE INDEX IF NOT EXISTS idx_patient_medical_conditions
  ON patients USING GIN (medical_conditions);

CREATE INDEX IF NOT EXISTS idx_patient_current_medications
  ON patients USING GIN (current_medications);

-- ============================================================
-- 8. Course sessions auto-create trigger
--    Generates one row per session when a course is inserted.
-- ============================================================

CREATE OR REPLACE FUNCTION populate_course_sessions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO course_sessions (clinic_id, course_id, session_number, is_bonus)
  SELECT
    NEW.clinic_id,
    NEW.id,
    gs.n,
    gs.n > NEW.sessions_bought      -- bonus sessions come after the bought ones
  FROM generate_series(1, NEW.sessions_bought + NEW.sessions_bonus) AS gs(n)
  ON CONFLICT (course_id, session_number) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS courses_populate_sessions ON courses;
CREATE TRIGGER courses_populate_sessions
  AFTER INSERT ON courses
  FOR EACH ROW EXECUTE FUNCTION populate_course_sessions();

-- ============================================================
-- 9. Optimistic-concurrency version column on treatment_records
--    Clients pass the version they last saw on UPDATE; mismatch raises.
-- ============================================================

ALTER TABLE treatment_records
  ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;

CREATE OR REPLACE FUNCTION bump_treatment_version()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- If the caller supplied an explicit version it must match the current row.
  IF NEW.version IS NOT NULL
     AND NEW.version <> OLD.version
     AND NEW.version <> OLD.version + 1
  THEN
    RAISE EXCEPTION 'version_conflict'
      USING ERRCODE = 'P0002',
            HINT   = 'treatment_records.version mismatch — refetch and retry';
  END IF;

  NEW.version := OLD.version + 1;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS treatment_records_version ON treatment_records;
CREATE TRIGGER treatment_records_version
  BEFORE UPDATE ON treatment_records
  FOR EACH ROW EXECUTE FUNCTION bump_treatment_version();

-- ============================================================
-- 10. Reporting RPCs — eliminate N+1 from client
-- ============================================================

-- Today's revenue: SQL-side SUM instead of client looping.
CREATE OR REPLACE FUNCTION get_today_revenue(p_clinic_id UUID)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(
    CASE
      WHEN type = 'PAYMENT' THEN amount
      WHEN type = 'REFUND'  THEN -amount
      ELSE 0
    END
  ), 0)::NUMERIC
    FROM financial_records
   WHERE clinic_id = p_clinic_id
     AND created_at >= date_trunc('day', now())
     AND created_at <  date_trunc('day', now()) + interval '1 day'
$$;

COMMENT ON FUNCTION get_today_revenue IS
  'Sum of payments minus refunds for today, computed in a single SQL pass.';

-- Patient full profile aggregator: returns all related rows in one round trip.
-- Used by the patient profile screen instead of N independent queries.
CREATE OR REPLACE FUNCTION get_patient_full(p_patient_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'patient',           to_jsonb(p),
    'recent_treatments', COALESCE((
      SELECT jsonb_agg(t ORDER BY t.date DESC)
        FROM (
          SELECT * FROM treatment_records
           WHERE patient_id = p.id
           ORDER BY date DESC
           LIMIT 50
        ) t
    ), '[]'::jsonb),
    'recent_appointments', COALESCE((
      SELECT jsonb_agg(a ORDER BY a.date DESC)
        FROM (
          SELECT * FROM appointments
           WHERE patient_id = p.id
           ORDER BY date DESC, start_time DESC
           LIMIT 30
        ) a
    ), '[]'::jsonb),
    'courses', COALESCE((
      SELECT jsonb_agg(c)
        FROM courses c
       WHERE c.patient_id = p.id
    ), '[]'::jsonb),
    'outstanding_total', COALESCE((
      SELECT SUM(
        CASE WHEN type = 'CHARGE' THEN amount
             WHEN type = 'PAYMENT' THEN -amount
             WHEN type = 'REFUND'  THEN amount
             ELSE 0
        END
      )
        FROM financial_records
       WHERE patient_id = p.id
         AND is_outstanding = true
    ), 0)
  )
    FROM patients p
   WHERE p.id = p_patient_id
$$;

COMMENT ON FUNCTION get_patient_full IS
  'Single-call aggregator that returns the patient row plus their recent treatments, appointments, courses, and outstanding balance. Replaces 4-5 sequential round trips from the patient profile screen.';

-- ============================================================
-- 11. ilike escape helper — prevents wildcard injection from search inputs
-- ============================================================

CREATE OR REPLACE FUNCTION escape_like(s TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT regexp_replace(COALESCE(s, ''), '([\\%_])', '\\\1', 'g')
$$;

COMMENT ON FUNCTION escape_like IS
  'Escape backslash, percent, and underscore for safe inclusion in LIKE/ILIKE patterns.';
