-- ============================================================
-- 029: Fix settle_charge created_by FK violation
--
-- Bug: 028's settle_charge inserted the PAYMENT row with
--      created_by = auth.uid(). But financial_records.created_by
--      REFERENCES staff(id) — NOT auth.users(id). auth.uid()
--      returns the auth user id, which is never equal to staff.id,
--      so every settlement failed with:
--        insert or update on table "financial_records"
--        violates foreign key constraint
--        "financial_records_created_by_fkey"
--
-- Fix: resolve the caller's staff.id (user_id = auth.uid() within the
--      charge's clinic) and store that. Falls back to NULL when no
--      matching staff row exists (the column is nullable), so the
--      payment is never blocked.
-- ============================================================

CREATE OR REPLACE FUNCTION settle_charge(
  p_record_id UUID,
  p_amount    NUMERIC,
  p_method    TEXT DEFAULT NULL
)
RETURNS financial_records
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row       financial_records;
  v_remaining NUMERIC;
  v_new_paid  NUMERIC;
  v_staff_id  UUID;
BEGIN
  -- Auth gate: only signed-in users may settle charges.
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required'
      USING ERRCODE = '42501';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'payment amount must be positive'
      USING ERRCODE = 'P0001';
  END IF;

  -- Acquire row-level lock to serialise concurrent payment attempts.
  SELECT * INTO v_row
    FROM financial_records
   WHERE id = p_record_id
     FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'financial record % not found', p_record_id
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT v_row.is_outstanding THEN
    RAISE EXCEPTION 'record_already_paid: record % is fully settled', p_record_id
      USING ERRCODE = 'P0001';
  END IF;

  v_remaining := v_row.amount - v_row.amount_paid;

  IF p_amount > v_remaining THEN
    RAISE EXCEPTION 'payment_exceeds_remaining: requested % but only % remaining',
      p_amount, v_remaining
      USING ERRCODE = 'P0001';
  END IF;

  v_new_paid := v_row.amount_paid + p_amount;

  -- Resolve the staff row for the caller within the charge's clinic.
  -- created_by REFERENCES staff(id); auth.uid() is an auth.users id and
  -- would violate the FK, so map it to the matching staff.id (or NULL).
  SELECT id INTO v_staff_id
    FROM staff
   WHERE user_id = auth.uid()
     AND clinic_id = v_row.clinic_id
   LIMIT 1;

  -- Persist the settlement on the charge row.
  UPDATE financial_records
     SET amount_paid    = v_new_paid,
         is_outstanding = CASE
                            WHEN v_new_paid >= v_row.amount THEN false
                            ELSE true
                          END
   WHERE id = p_record_id
   RETURNING * INTO v_row;

  -- Insert a matching PAYMENT record in the same transaction so the
  -- patient's history shows each individual payment installment.
  INSERT INTO financial_records (
    id, clinic_id, patient_id,
    treatment_record_id, course_id,
    type, amount, payment_method,
    description, is_outstanding,
    created_by
  ) VALUES (
    gen_random_uuid(),
    v_row.clinic_id,
    v_row.patient_id,
    v_row.treatment_record_id,
    v_row.course_id,
    'PAYMENT',
    p_amount,
    CASE
      WHEN p_method IS NOT NULL AND p_method <> ''
      THEN p_method::payment_method
      ELSE NULL
    END,
    'ชำระ: ' || COALESCE(v_row.description, 'ยอดค้าง'),
    false,
    v_staff_id
  );

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION settle_charge(UUID, NUMERIC, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION settle_charge(UUID, NUMERIC, TEXT) TO authenticated;

COMMENT ON FUNCTION settle_charge(UUID, NUMERIC, TEXT) IS
  'Atomic partial-payment settlement: increments amount_paid, clears is_outstanding when fully paid, '
  'and inserts a matching PAYMENT record in one transaction. '
  'created_by stores the caller''s staff.id (resolved from auth.uid()), NULL when no staff row matches. '
  'Prevents concurrent double-payment via row-level lock. '
  'Supersedes the 028 version which incorrectly stored auth.uid() (FK violation).';
