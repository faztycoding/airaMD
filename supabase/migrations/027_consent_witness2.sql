-- ============================================================
-- 027_consent_witness2.sql
-- The clinic's paper consent form (บลิส คลินิก) has TWO witness signature
-- blocks. Add a second witness name + signature so the digital form matches
-- the legal document exactly.
-- Idempotent: safe to re-run.
-- ============================================================

ALTER TABLE consent_forms
  ADD COLUMN IF NOT EXISTS witness2_name TEXT;

ALTER TABLE consent_forms
  ADD COLUMN IF NOT EXISTS witness2_signature_url TEXT;
