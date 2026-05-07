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
