-- Migration 024: Add Harmonica + Juvelook to product catalog
--
-- Client (May 31, 2026) reported these biostimulators were missing from
-- the catalog ("ลืมอัพเดทยา"). Verified against prod via service role:
-- Belluxi / Radiesse / Sculptra already seed in all 3 clinics (migration
-- 021), but Harmonica and Juvelook were never seeded anywhere.
--
--   - Harmonica (HArmonyCa) — CaHA + HA hybrid collagen biostimulator
--   - Juvelook            — PDLLA + HA collagen stimulator
--
-- Both classified BIOSTIMULATOR (consistent with Sculptra/Radiesse).
-- Default prices are Thai-clinic midpoints — the doctor can override
-- per-row in the Products screen (same philosophy as migration 021).
--
-- Idempotent:
--   - Inserts per clinic only where (clinic_id, lower(name)) is absent.
--   - Safe to re-run; no duplicates. Applies to ALL clinics.

BEGIN;

INSERT INTO products
  (clinic_id, name, brand, category, unit, default_price, stock_quantity, is_active)
SELECT c.id, p.name, p.brand, p.category::product_category, p.unit, p.default_price, 0, true
FROM clinics c
CROSS JOIN (VALUES
  ('Harmonica', 'Allergan', 'BIOSTIMULATOR', 'syringe', 17000.00),
  ('Juvelook',  'Vaim',     'BIOSTIMULATOR', 'vial',    10000.00)
) AS p(name, brand, category, unit, default_price)
WHERE NOT EXISTS (
  SELECT 1 FROM products
  WHERE clinic_id = c.id AND lower(name) = lower(p.name)
);

COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- Verification (run separately after applying):
--
--   SELECT clinic_id, name, category, default_price
--     FROM products
--    WHERE lower(name) IN ('harmonica', 'juvelook')
--    ORDER BY name, clinic_id;
--   -- Expected: 2 rows per clinic (one Harmonica + one Juvelook each).
-- ─────────────────────────────────────────────────────────────────────
