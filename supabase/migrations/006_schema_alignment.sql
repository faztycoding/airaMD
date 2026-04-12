-- ============================================================
-- Migration 006: Align DB schema with Dart models
-- Fixes 3 mismatches found during final review
-- ============================================================

-- ============================================================
-- 1. PATIENTS: Add is_active column (for soft-delete)
-- ============================================================
ALTER TABLE patients ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_patient_active
  ON patients(clinic_id, is_active)
  WHERE is_active = true;

-- ============================================================
-- 2. CONSENT_FORMS: Add missing columns (procedure, consented_items, notes)
-- ============================================================
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS procedure TEXT;
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS consented_items TEXT[] DEFAULT '{}';
ALTER TABLE consent_forms ADD COLUMN IF NOT EXISTS notes TEXT;

-- ============================================================
-- 3. DIAGRAM_VIEW enum: Add LEFT_SIDE and RIGHT_SIDE values
-- ============================================================
ALTER TYPE diagram_view ADD VALUE IF NOT EXISTS 'LEFT_SIDE';
ALTER TYPE diagram_view ADD VALUE IF NOT EXISTS 'RIGHT_SIDE';

-- ============================================================
-- 4. STORAGE: Create clinic-assets bucket (public — logos, etc.)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('clinic-assets', 'clinic-assets', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Clinic staff can read clinic assets"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'clinic-assets');

CREATE POLICY "Clinic staff can upload clinic assets"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'clinic-assets'
    AND public.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can delete clinic assets"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'clinic-assets'
    AND public.is_own_clinic_path(bucket_id, name)
  );
