-- ============================================================
-- 025_consent_worldclass.sql
-- World-class consent forms:
--   • Template versioning
--   • Multi-party signing (patient + doctor + witness)
--   • Risk acknowledgement, typed-name confirmation, audit fields
--   • Immutability: signed consents cannot be edited (legal record)
-- ============================================================

-- 1. Template versioning ----------------------------------------------------
ALTER TABLE consent_form_templates
  ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;

-- 2. consent_forms: multi-party signing + acknowledgements + audit ----------
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS doctor_id UUID REFERENCES staff(id);
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS doctor_signature_url TEXT;
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS witness_signature_url TEXT;
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS signed_name_typed TEXT;
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS template_version INT;
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS acknowledged_items TEXT[] DEFAULT '{}';
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS device_info TEXT;

-- 3. Immutability -----------------------------------------------------------
-- A signed consent is a legal document. Remove the UPDATE policy so RLS blocks
-- any edit after insert. INSERT (clinical staff) + SELECT (clinic members)
-- remain; DELETE stays owner-only (defined in 011_role_locked_writes.sql).
DROP POLICY IF EXISTS "Consent forms update clinical staff" ON consent_forms;

-- 4. Storage bucket for archived consent PDFs -------------------------------
-- Storage RLS policies for 'consent-pdfs' already exist (migration 019).
-- 019 only defined the policies, not the bucket row itself — create it here.
-- Path convention: {clinic_id}/{patient_id}/{form_id}.pdf
INSERT INTO storage.buckets (id, name, public)
VALUES ('consent-pdfs', 'consent-pdfs', false)
ON CONFLICT (id) DO NOTHING;
