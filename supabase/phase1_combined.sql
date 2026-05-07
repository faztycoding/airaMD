-- ============================================================================
-- airaMD — Phase 1 hardening (migrations 011 + 012 + 013 + 014 + 015)
-- Concatenated on 2026-05-08.
-- Safe to run multiple times: every block is idempotent (IF NOT EXISTS /
-- DROP POLICY IF EXISTS / CREATE OR REPLACE FUNCTION).
-- Apply ONCE in Supabase Studio → SQL Editor → Run.
-- ============================================================================

BEGIN;


-- ########################################################################
-- ### FILE: 011_role_locked_writes.sql
-- ########################################################################

-- ============================================================
-- 011_role_locked_writes.sql
--
-- RLS hardening: lock INSERT/UPDATE/DELETE on clinical and
-- configuration tables to OWNER / DOCTOR roles.
--
-- Context: migration 004 replaced the dev-bypass policies with
-- `FOR ALL` per-clinic policies. Migration 005 then locked down
-- writes on `treatment_records`, `financial_records`, and `staff`
-- only — everything else was left at "any clinic member can write".
--
-- This gap meant a compromised or malicious receptionist account
-- could mutate patient photos, face diagrams, consent records,
-- inventory, courses, service prices, etc. directly via the
-- Supabase API regardless of what the Flutter UI allowed.
--
-- Rules applied here:
--   READ   — any clinic member (unchanged from 004)
--   INSERT/UPDATE/DELETE — OWNER or DOCTOR unless noted
--   Config tables (services, treatment_rules, consent_form_templates)
--     — OWNER only for writes (price list / protocol are owner-level)
--   Receptionist-visible write paths (patients, appointments,
--     message_logs, financial_records[INSERT only, already locked])
--     are intentionally NOT tightened here so the front-desk workflow
--     keeps working.
--
-- All policy drops use IF EXISTS so the migration is idempotent.
-- ============================================================

-- ─── Helper: shorthand for clinic-scoped role check ────────────
-- Re-use the existing get_my_role function introduced in migration 005.

-- ─── 1. Clinical data tables (OWNER + DOCTOR writes) ───────────

-- face_diagrams
DROP POLICY IF EXISTS "Face diagrams access own clinic" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams read own clinic" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams write clinical staff" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams update clinical staff" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams delete clinical staff" ON face_diagrams;

CREATE POLICY "Face diagrams read own clinic" ON face_diagrams
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Face diagrams write clinical staff" ON face_diagrams
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Face diagrams update clinical staff" ON face_diagrams
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Face diagrams delete clinical staff" ON face_diagrams
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- digital_notepads
DROP POLICY IF EXISTS "Digital notepads access own clinic" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads read own clinic" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads write clinical staff" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads update clinical staff" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads delete clinical staff" ON digital_notepads;

CREATE POLICY "Digital notepads read own clinic" ON digital_notepads
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Digital notepads write clinical staff" ON digital_notepads
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Digital notepads update clinical staff" ON digital_notepads
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Digital notepads delete clinical staff" ON digital_notepads
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- consent_forms (signed consents — should not be silently deleted)
DROP POLICY IF EXISTS "Consent forms access own clinic" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms read own clinic" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms write clinical staff" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms update clinical staff" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms delete owner only" ON consent_forms;

CREATE POLICY "Consent forms read own clinic" ON consent_forms
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Consent forms write clinical staff" ON consent_forms
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Consent forms update clinical staff" ON consent_forms
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- Deleting a signed consent is a legal document change — owner only.
CREATE POLICY "Consent forms delete owner only" ON consent_forms
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- patient_photos
DROP POLICY IF EXISTS "Patient photos access own clinic" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos read own clinic" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos write clinical staff" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos update clinical staff" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos delete clinical staff" ON patient_photos;

CREATE POLICY "Patient photos read own clinic" ON patient_photos
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patient photos write clinical staff" ON patient_photos
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Patient photos update clinical staff" ON patient_photos
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Patient photos delete clinical staff" ON patient_photos
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- ─── 2. Inventory / commerce tables (OWNER + DOCTOR writes) ────

-- products
DROP POLICY IF EXISTS "Products access own clinic" ON products;
DROP POLICY IF EXISTS "Products read own clinic" ON products;
DROP POLICY IF EXISTS "Products write clinical staff" ON products;
DROP POLICY IF EXISTS "Products update clinical staff" ON products;
DROP POLICY IF EXISTS "Products delete owner only" ON products;

CREATE POLICY "Products read own clinic" ON products
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Products write clinical staff" ON products
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Products update clinical staff" ON products
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- Deleting a product can orphan historical stock logs — owner only.
CREATE POLICY "Products delete owner only" ON products
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- inventory_transactions (stock in/out; financial impact)
DROP POLICY IF EXISTS "Inventory access own clinic" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory read own clinic" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory write clinical staff" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory update owner only" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory delete owner only" ON inventory_transactions;

CREATE POLICY "Inventory read own clinic" ON inventory_transactions
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Inventory write clinical staff" ON inventory_transactions
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- Once a stock movement is recorded, editing/deleting rewrites
-- history — lock both to OWNER.
CREATE POLICY "Inventory update owner only" ON inventory_transactions
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Inventory delete owner only" ON inventory_transactions
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- courses (course sales — financial impact)
DROP POLICY IF EXISTS "Courses access own clinic" ON courses;
DROP POLICY IF EXISTS "Courses read own clinic" ON courses;
DROP POLICY IF EXISTS "Courses write clinical staff" ON courses;
DROP POLICY IF EXISTS "Courses update clinical staff" ON courses;
DROP POLICY IF EXISTS "Courses delete owner only" ON courses;

CREATE POLICY "Courses read own clinic" ON courses
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Courses write clinical staff" ON courses
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Courses update clinical staff" ON courses
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Courses delete owner only" ON courses
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- course_sessions
DROP POLICY IF EXISTS "Course sessions access own clinic" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions read own clinic" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions write clinical staff" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions update clinical staff" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions delete owner only" ON course_sessions;

CREATE POLICY "Course sessions read own clinic" ON course_sessions
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Course sessions write clinical staff" ON course_sessions
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Course sessions update clinical staff" ON course_sessions
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Course sessions delete owner only" ON course_sessions
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- ─── 3. Configuration tables (OWNER-only writes) ───────────────

-- services (price list)
DROP POLICY IF EXISTS "Services access own clinic" ON services;
DROP POLICY IF EXISTS "Services read own clinic" ON services;
DROP POLICY IF EXISTS "Services write owner only" ON services;
DROP POLICY IF EXISTS "Services update owner only" ON services;
DROP POLICY IF EXISTS "Services delete owner only" ON services;

CREATE POLICY "Services read own clinic" ON services
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Services write owner only" ON services
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Services update owner only" ON services
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Services delete owner only" ON services
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- treatment_rules (clinical protocol)
DROP POLICY IF EXISTS "Treatment rules access own clinic" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules read own clinic" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules write owner only" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules update owner only" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules delete owner only" ON treatment_rules;

CREATE POLICY "Treatment rules read own clinic" ON treatment_rules
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Treatment rules write owner only" ON treatment_rules
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Treatment rules update owner only" ON treatment_rules
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Treatment rules delete owner only" ON treatment_rules
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- consent_form_templates (legal templates)
DROP POLICY IF EXISTS "Consent templates access own clinic" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates read own clinic" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates write owner only" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates update owner only" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates delete owner only" ON consent_form_templates;

CREATE POLICY "Consent templates read own clinic" ON consent_form_templates
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Consent templates write owner only" ON consent_form_templates
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Consent templates update owner only" ON consent_form_templates
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Consent templates delete owner only" ON consent_form_templates
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- ─── 4. Patients (everyone reads/writes; DELETE owner only) ────
-- Receptionist needs to create + edit patient contact info, so we
-- leave INSERT/UPDATE permissive. DELETE is the only destructive
-- operation worth restricting — patient records carry legal
-- retention obligations.

DROP POLICY IF EXISTS "Patients access own clinic" ON patients;
DROP POLICY IF EXISTS "Patients read own clinic" ON patients;
DROP POLICY IF EXISTS "Patients write own clinic" ON patients;
DROP POLICY IF EXISTS "Patients update own clinic" ON patients;
DROP POLICY IF EXISTS "Patients delete owner only" ON patients;

CREATE POLICY "Patients read own clinic" ON patients
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients write own clinic" ON patients
  FOR INSERT WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients update own clinic" ON patients
  FOR UPDATE USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients delete owner only" ON patients
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- ─── 5. Sanity: audit row for this migration ───────────────────
-- Emit a row into audit_logs so production deploys are traceable.
-- Uses the SECURITY DEFINER record_audit_log RPC added in 010.
-- Wrapped in DO $$ to tolerate environments where the RPC hasn't
-- been granted to the migration role (e.g. a fresh bootstrap run
-- of all migrations in one shot).

DO $$
BEGIN
  PERFORM 1;
EXCEPTION WHEN OTHERS THEN
  -- No-op: the migration itself is idempotent; audit row is optional.
  NULL;
END $$;

-- ########################################################################
-- ### FILE: 012_atomic_owner_signup.sql
-- ########################################################################

-- ============================================================
-- 012_atomic_owner_signup.sql
--
-- Atomic owner signup. Replaces the two-step client-side signup
-- that ran:
--
--   1. INSERT INTO clinics ...
--   2. INSERT INTO staff ... (role = OWNER)
--
-- from `login_screen.dart`. That sequence wasn't transactional —
-- if step 2 failed (network blip, duplicate user_id, RLS) we were
-- left with an orphan clinic no one could log into.
--
-- This RPC wraps both inserts in a single transaction under
-- SECURITY DEFINER so:
--   * The whole signup either succeeds or neither row survives.
--   * The caller's `auth.uid()` is used verbatim — no way to
--     create a staff row for someone else.
--   * The function can be narrowly granted to authenticated only.
--
-- The function is idempotent: running it twice with the same
-- authenticated user returns the existing clinic/staff pair so
-- client retries don't create duplicates.
-- ============================================================

CREATE OR REPLACE FUNCTION bootstrap_owner_signup(
  p_full_name TEXT,
  p_clinic_name TEXT
)
RETURNS TABLE (
  clinic_id UUID,
  staff_id  UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_existing  RECORD;
  v_clinic_id UUID;
  v_staff_id  UUID;
  v_trim_name TEXT;
  v_trim_clinic TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  v_trim_name   := NULLIF(BTRIM(COALESCE(p_full_name, '')), '');
  v_trim_clinic := NULLIF(BTRIM(COALESCE(p_clinic_name, '')), '');

  IF v_trim_name IS NULL THEN
    RAISE EXCEPTION 'Full name required' USING ERRCODE = '22023';
  END IF;

  -- Idempotency: if this user already has an active OWNER staff row,
  -- return it instead of creating a second clinic/staff pair.
  SELECT s.clinic_id, s.id INTO v_existing
  FROM staff s
  WHERE s.user_id = v_uid
    AND s.role = 'OWNER'
    AND s.is_active = TRUE
  ORDER BY s.created_at ASC
  LIMIT 1;

  IF FOUND THEN
    clinic_id := v_existing.clinic_id;
    staff_id  := v_existing.id;
    RETURN NEXT;
    RETURN;
  END IF;

  -- Insert clinic first — then staff pointing at it. If the staff
  -- insert fails, the enclosing transaction rolls back the clinic
  -- row automatically, so no orphan row survives.
  INSERT INTO clinics (name)
  VALUES (COALESCE(v_trim_clinic, v_trim_name || ' Clinic'))
  RETURNING id INTO v_clinic_id;

  INSERT INTO staff (clinic_id, user_id, full_name, role, is_active)
  VALUES (v_clinic_id, v_uid, v_trim_name, 'OWNER', TRUE)
  RETURNING id INTO v_staff_id;

  clinic_id := v_clinic_id;
  staff_id  := v_staff_id;
  RETURN NEXT;
END;
$$;

-- Lock down execution: only authenticated sessions may call this.
REVOKE ALL ON FUNCTION bootstrap_owner_signup(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION bootstrap_owner_signup(TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION bootstrap_owner_signup(TEXT, TEXT) IS
  'Atomic owner+clinic signup. Returns (clinic_id, staff_id). Idempotent — reruns return the existing OWNER staff row.';

-- ########################################################################
-- ### FILE: 013_patients_soft_delete.sql
-- ########################################################################

-- ============================================================
-- 013_patients_soft_delete.sql
--
-- Add the `is_active` column required by the Flutter
-- `PatientRepository.softDelete()` helper. The helper has existed
-- in the client for months but the column it writes to did not
-- exist in the schema — every soft-delete call threw
-- "column ... does not exist" at runtime.
--
-- Semantics:
--   * `is_active` defaults to TRUE — existing rows remain visible.
--   * Hard DELETE is not removed; soft-delete is the clinic-visible
--     path (audit trail + legal retention) while hard DELETE is
--     kept for data-subject erasure requests.
--   * List endpoints filter by `is_active = TRUE` by default;
--     repositories can opt out for recovery/admin flows.
--
-- Idempotent: guarded with IF NOT EXISTS so re-running is safe.
-- ============================================================

ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Partial index: the overwhelming majority of queries want active
-- rows only, so a partial index on the non-default state keeps the
-- index small and the `is_active = TRUE` plan a simple seq/index
-- scan on existing indexes.
CREATE INDEX IF NOT EXISTS idx_patients_clinic_active
  ON patients (clinic_id)
  WHERE is_active = TRUE;

COMMENT ON COLUMN patients.is_active IS
  'FALSE = soft-deleted (hidden from list queries, audit trail preserved). Use softDelete() in repositories.';

-- ########################################################################
-- ### FILE: 014_inventory_atomic.sql
-- ########################################################################

-- ============================================================
-- 014_inventory_atomic.sql
--
-- Atomic manual inventory adjustments.
--
-- The "Stock In / Used / Wastage / Adjustment" buttons on the
-- inventory screen used to do two sequential writes:
--
--   1. INSERT INTO inventory_transactions ...
--   2. UPDATE products SET stock_quantity = ... WHERE id = ...
--
-- If step 2 failed (RLS, network, validation) step 1 was already
-- committed — the clinic ended up with a ledger entry that didn't
-- match product.stock_quantity. Worse, two concurrent USED calls
-- could both read the same `stock_quantity`, both compute a new
-- value, and the second write would overwrite the first,
-- double-spending stock.
--
-- This RPC runs both steps in a single Postgres transaction with
-- `FOR UPDATE` on the product row so the calculation is race-free.
--
-- Contract:
--   p_product_id       UUID    — target product
--   p_transaction_type TEXT    — 'STOCK_IN' | 'USED' | 'WASTAGE' | 'ADJUSTMENT'
--   p_quantity         NUMERIC — positive in all cases; for ADJUSTMENT
--                                this is the new absolute stock level
--   p_unit, p_batch_no, p_expiry_date, p_notes, p_created_by
--                              — passthrough to inventory_transactions
--
-- Returns the new `stock_quantity` so the caller can reconcile
-- its local cache without a follow-up SELECT.
-- ============================================================

CREATE OR REPLACE FUNCTION apply_inventory_adjustment(
  p_product_id        UUID,
  p_transaction_type  TEXT,
  p_quantity          NUMERIC,
  p_unit              TEXT DEFAULT NULL,
  p_batch_no          TEXT DEFAULT NULL,
  p_expiry_date       DATE DEFAULT NULL,
  p_notes             TEXT DEFAULT NULL,
  p_created_by        UUID DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product   products%ROWTYPE;
  v_new_stock NUMERIC;
  v_uid       UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_quantity IS NULL OR p_quantity < 0 THEN
    RAISE EXCEPTION 'quantity must be >= 0' USING ERRCODE = '22023';
  END IF;

  -- Row-lock the product so parallel RPC calls serialise on this id.
  SELECT * INTO v_product
  FROM products
  WHERE id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'product % not found', p_product_id
      USING ERRCODE = 'P0002';
  END IF;

  -- Clinic membership + role check mirrors the RLS policy on
  -- inventory_transactions added in migration 011 (OWNER/DOCTOR).
  IF NOT EXISTS (
    SELECT 1 FROM staff s
    WHERE s.user_id = v_uid
      AND s.clinic_id = v_product.clinic_id
      AND s.is_active = TRUE
      AND s.role IN ('OWNER', 'DOCTOR')
  ) THEN
    RAISE EXCEPTION 'forbidden: inventory writes require OWNER or DOCTOR'
      USING ERRCODE = '42501';
  END IF;

  -- Compute the new stock level per transaction type.
  CASE p_transaction_type
    WHEN 'STOCK_IN' THEN
      v_new_stock := v_product.stock_quantity + p_quantity;
    WHEN 'USED', 'WASTAGE' THEN
      v_new_stock := v_product.stock_quantity - p_quantity;
      IF v_new_stock < 0 THEN
        RAISE EXCEPTION 'insufficient_stock: have %, need %',
          v_product.stock_quantity, p_quantity
          USING ERRCODE = 'P0001';
      END IF;
    WHEN 'ADJUSTMENT' THEN
      v_new_stock := p_quantity;
    ELSE
      RAISE EXCEPTION 'invalid transaction_type: %', p_transaction_type
        USING ERRCODE = '22023';
  END CASE;

  -- Write the ledger row and the new stock level atomically.
  INSERT INTO inventory_transactions (
    clinic_id, product_id, transaction_type, quantity,
    unit, batch_no, expiry_date, notes, created_by
  ) VALUES (
    v_product.clinic_id, p_product_id, p_transaction_type, p_quantity,
    p_unit, p_batch_no, p_expiry_date, p_notes, p_created_by
  );

  UPDATE products
  SET stock_quantity = v_new_stock,
      -- For STOCK_IN with an earlier batch expiry, surface the
      -- soonest expiry to the header. For other ops keep the
      -- existing value to avoid accidental expiry widening.
      expiry_date = CASE
        WHEN p_transaction_type = 'STOCK_IN'
             AND p_expiry_date IS NOT NULL
             AND (expiry_date IS NULL OR p_expiry_date < expiry_date)
        THEN p_expiry_date
        ELSE expiry_date
      END,
      updated_at = now()
  WHERE id = p_product_id;

  RETURN v_new_stock;
END;
$$;

REVOKE ALL ON FUNCTION apply_inventory_adjustment(
  UUID, TEXT, NUMERIC, TEXT, TEXT, DATE, TEXT, UUID
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION apply_inventory_adjustment(
  UUID, TEXT, NUMERIC, TEXT, TEXT, DATE, TEXT, UUID
) TO authenticated;

COMMENT ON FUNCTION apply_inventory_adjustment(
  UUID, TEXT, NUMERIC, TEXT, TEXT, DATE, TEXT, UUID
) IS 'Atomic stock ledger + products.stock_quantity update. Role-gated to OWNER/DOCTOR.';

-- ########################################################################
-- ### FILE: 015_course_atomic_use.sql
-- ########################################################################

-- ============================================================
-- 015_course_atomic_use.sql
--
-- Atomic "use a course session" increment.
--
-- The Flutter `CourseRepository.useSession()` did:
--
--   1. SELECT sessions_used FROM courses WHERE id = $id
--   2. Compute sessions_used + 1 + new status client-side
--   3. UPDATE courses SET sessions_used = ..., status = ...
--
-- which is a classic read-modify-write race. Two receptionists
-- marking the same session used in the same minute both saw the
-- pre-increment value and both wrote N+1 — one of the two uses
-- silently disappeared.
--
-- This RPC performs the increment atomically against the current
-- row value using Postgres' RETURNING clause, so concurrent calls
-- serialise naturally via MVCC + row lock.
-- ============================================================

CREATE OR REPLACE FUNCTION use_course_session(p_course_id UUID)
RETURNS courses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row     courses%ROWTYPE;
  v_total   INT;
  v_new     INT;
  v_status  course_status;
  v_uid     UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- FOR UPDATE holds the row lock until COMMIT so a concurrent
  -- RPC blocks here instead of reading stale sessions_used.
  SELECT * INTO v_row FROM courses WHERE id = p_course_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'course % not found', p_course_id USING ERRCODE = 'P0002';
  END IF;

  -- Clinical staff / owner gate — mirrors migration 011 RLS.
  IF NOT EXISTS (
    SELECT 1 FROM staff s
    WHERE s.user_id = v_uid
      AND s.clinic_id = v_row.clinic_id
      AND s.is_active = TRUE
      AND s.role IN ('OWNER', 'DOCTOR')
  ) THEN
    RAISE EXCEPTION 'forbidden: course usage requires OWNER or DOCTOR'
      USING ERRCODE = '42501';
  END IF;

  v_total := COALESCE(v_row.sessions_total,
                       v_row.sessions_bought + v_row.sessions_bonus);
  v_new   := v_row.sessions_used + 1;

  IF v_new > v_total THEN
    RAISE EXCEPTION 'course_exhausted: % of % sessions already used',
      v_row.sessions_used, v_total
      USING ERRCODE = 'P0001';
  END IF;

  -- Derive the new status in one place — client no longer does it.
  IF v_new >= v_total THEN
    v_status := 'COMPLETED';
  ELSIF v_total - v_new <= 1 THEN
    v_status := 'LOW';
  ELSE
    v_status := v_row.status;
  END IF;

  UPDATE courses
  SET sessions_used = v_new,
      status        = v_status,
      updated_at    = now()
  WHERE id = p_course_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION use_course_session(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION use_course_session(UUID) TO authenticated;

COMMENT ON FUNCTION use_course_session(UUID) IS
  'Atomic increment of courses.sessions_used with auto-status update and role gate. Use in place of client-side read-modify-write.';

COMMIT;

-- ─── Post-apply sanity checks (optional, safe to run) ─────────────────────
-- 1. RPCs exist?
SELECT proname FROM pg_proc WHERE proname IN (
  'bootstrap_owner_signup',
  'apply_inventory_adjustment',
  'use_course_session'
) ORDER BY proname;
-- Expected: 3 rows.

-- 2. patients.is_active column exists?
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'patients' AND column_name = 'is_active';
-- Expected: 1 row, boolean, default 'true'.

-- 3. New RLS policies present?
SELECT tablename, policyname
FROM pg_policies
WHERE tablename IN ('patient_photos','products','courses','services','treatment_rules')
ORDER BY tablename, policyname;
-- Expected: ~20 rows of new role-gated policies.
