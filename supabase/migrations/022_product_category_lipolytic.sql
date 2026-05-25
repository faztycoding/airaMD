-- Migration 022: Add LIPOLYTIC value to product_category enum
--
-- Phase 5 introduces fat-dissolving / body-contouring solutions
-- (Fat Bomb Face/Body, V Face/Body Solution). These were seeded
-- under 'OTHER' in migration 021; this migration adds a proper
-- LIPOLYTIC category and re-tags the seeded rows.
--
-- Safe to re-run: ADD VALUE IF NOT EXISTS is idempotent (PG 12+).

BEGIN;

-- 1. Extend the enum
ALTER TYPE product_category ADD VALUE IF NOT EXISTS 'LIPOLYTIC';

COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- 2. Re-tag seeded lipolytic rows (separate txn — new enum value cannot
--    be used in the same transaction it was added in)
-- ─────────────────────────────────────────────────────────────────────

BEGIN;

UPDATE products
   SET category = 'LIPOLYTIC'::product_category
 WHERE category = 'OTHER'::product_category
   AND lower(name) IN (
     'fat bomb face',
     'fat bomb body',
     'v face solution',
     'v body solution'
   );

COMMIT;
