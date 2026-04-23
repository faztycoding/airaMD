-- ============================================================
-- Migration 007: Add current_medications to patients
-- Tracks supplements, vitamins, OTC drugs patient is currently taking
-- Used by SafetyCheckService to warn about interactions
-- ============================================================

ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS current_medications TEXT[] DEFAULT '{}';

COMMENT ON COLUMN patients.current_medications IS
  'List of supplements, vitamins, and OTC medications the patient is currently taking. Used for safety warnings (e.g., fish oil before injectables, vitamin E before laser).';
