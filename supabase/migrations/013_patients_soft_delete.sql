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
