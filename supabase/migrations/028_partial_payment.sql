-- ============================================================
-- 028: Partial-payment support for financial_records
--
-- 1. Adds amount_paid column (idempotent — ADD COLUMN IF NOT EXISTS).
-- 2. Backfills settled charges so their remaining balance shows 0.
-- 3. Creates settle_charge() RPC:
--      • Row-locks the charge to prevent concurrent double-pays.
--      • Increments amount_paid by the requested amount.
--      • Flips is_outstanding=false when fully settled.
--      • Inserts the matching PAYMENT record in the same txn.
-- ============================================================

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(12,2) NOT NULL DEFAULT 0;

-- Backfill: charges already marked paid get amount_paid = amount
-- so outstandingRemaining shows as 0 for historic records.
UPDATE financial_records
   SET amount_paid = amount
 WHERE type = 'CHARGE'
   AND is_outstanding = false
   AND amount_paid = 0;

-- ─── settle_charge RPC ────────────────────────────────────────
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
    auth.uid()
  );

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION settle_charge(UUID, NUMERIC, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION settle_charge(UUID, NUMERIC, TEXT) TO authenticated;

COMMENT ON FUNCTION settle_charge(UUID, NUMERIC, TEXT) IS
  'Atomic partial-payment settlement: increments amount_paid, clears is_outstanding when fully paid, '
  'and inserts a matching PAYMENT record in one transaction. '
  'Prevents concurrent double-payment via row-level lock. '
  'Modelled after use_course_session (migration 015).';
