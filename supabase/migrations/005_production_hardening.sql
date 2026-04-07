-- ============================================================
-- PRODUCTION HARDENING
-- 1. Additional performance indexes
-- 2. Storage bucket RLS policies
-- 3. Role-based RLS (server-side RBAC)
-- ============================================================

-- ============================================================
-- 1. ADDITIONAL INDEXES (tables that were missing)
-- ============================================================

-- Consent forms: lookup by clinic + treatment
CREATE INDEX IF NOT EXISTS idx_consent_forms_clinic
  ON consent_forms(clinic_id);
CREATE INDEX IF NOT EXISTS idx_consent_forms_treatment
  ON consent_forms(treatment_record_id);

-- Face diagrams: lookup by clinic
CREATE INDEX IF NOT EXISTS idx_diagrams_clinic
  ON face_diagrams(clinic_id);

-- Digital notepads: lookup by clinic
CREATE INDEX IF NOT EXISTS idx_notepads_clinic
  ON digital_notepads(clinic_id);

-- Course sessions: lookup by clinic
CREATE INDEX IF NOT EXISTS idx_course_sessions_clinic
  ON course_sessions(clinic_id);

-- Treatment rules: lookup (already unique on clinic_id + type, but add for scans)
CREATE INDEX IF NOT EXISTS idx_treatment_rules_clinic
  ON treatment_rules(clinic_id);

-- Financial records: date-based lookups for reports
CREATE INDEX IF NOT EXISTS idx_financial_created
  ON financial_records(clinic_id, created_at DESC);

-- Appointments: status filter
CREATE INDEX IF NOT EXISTS idx_appt_status
  ON appointments(clinic_id, status);

-- Treatment records: category filter
CREATE INDEX IF NOT EXISTS idx_treatment_category
  ON treatment_records(clinic_id, category);

-- Message logs: sent_at for reporting
CREATE INDEX IF NOT EXISTS idx_messages_sent
  ON message_logs(clinic_id, sent_at DESC);

-- Products: expiry date for alerts
CREATE INDEX IF NOT EXISTS idx_products_expiry
  ON products(clinic_id, expiry_date)
  WHERE expiry_date IS NOT NULL;

-- Products: low stock alert
CREATE INDEX IF NOT EXISTS idx_products_low_stock
  ON products(clinic_id, stock_quantity)
  WHERE min_stock_alert IS NOT NULL;

-- ============================================================
-- 2. STORAGE BUCKET RLS POLICIES
-- (Run via Supabase Dashboard > Storage > Policies if not using SQL)
-- ============================================================

-- Helper: check if user belongs to a clinic that owns the file path
-- Storage paths follow: {clinic_id}/{patient_id}/...
CREATE OR REPLACE FUNCTION storage.is_own_clinic_path(bucket TEXT, path TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  path_clinic_id UUID;
BEGIN
  -- Extract clinic_id from first path segment: "clinic_id/..."
  path_clinic_id := SPLIT_PART(path, '/', 1)::UUID;
  RETURN path_clinic_id IN (SELECT get_my_clinic_ids());
EXCEPTION
  WHEN OTHERS THEN RETURN FALSE;
END;
$$;

-- patient-photos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('patient-photos', 'patient-photos', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Clinic staff can read patient photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'patient-photos'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can upload patient photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'patient-photos'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can delete patient photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'patient-photos'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

-- face-diagrams bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('face-diagrams', 'face-diagrams', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Clinic staff can read face diagrams"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'face-diagrams'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can upload face diagrams"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'face-diagrams'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can delete face diagrams"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'face-diagrams'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

-- consent-signatures bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('consent-signatures', 'consent-signatures', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Clinic staff can read consent signatures"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'consent-signatures'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can upload consent signatures"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'consent-signatures'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

-- consent-pdfs bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('consent-pdfs', 'consent-pdfs', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Clinic staff can read consent pdfs"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'consent-pdfs'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can upload consent pdfs"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'consent-pdfs'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

-- notepads bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('notepads', 'notepads', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Clinic staff can read notepads"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'notepads'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

CREATE POLICY "Clinic staff can upload notepads"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'notepads'
    AND storage.is_own_clinic_path(bucket_id, name)
  );

-- ============================================================
-- 3. ROLE-BASED RLS — Server-side RBAC
-- Receptionist cannot write to clinical/financial tables
-- ============================================================

-- Helper: get current user's role for a given clinic
CREATE OR REPLACE FUNCTION get_my_role(p_clinic_id UUID)
RETURNS staff_role
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM staff
  WHERE user_id = auth.uid()
    AND clinic_id = p_clinic_id
    AND is_active = true
  LIMIT 1
$$;

-- Treatment records: receptionist can read but not write
DROP POLICY IF EXISTS "Treatment records access own clinic" ON treatment_records;
CREATE POLICY "Treatment records read own clinic" ON treatment_records
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Treatment records write clinical staff" ON treatment_records
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Treatment records update clinical staff" ON treatment_records
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Treatment records delete clinical staff" ON treatment_records
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- Financial records: receptionist can read but not write
DROP POLICY IF EXISTS "Financial records access own clinic" ON financial_records;
CREATE POLICY "Financial records read own clinic" ON financial_records
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Financial records write authorized" ON financial_records
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Financial records update authorized" ON financial_records
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Financial records delete owner only" ON financial_records
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- Staff management: only owner can modify staff
DROP POLICY IF EXISTS "Staff access own clinic" ON staff;
CREATE POLICY "Staff read own clinic" ON staff
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Staff write owner only" ON staff
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Staff update owner only" ON staff
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND (
      get_my_role(clinic_id) = 'OWNER'
      OR user_id = auth.uid()  -- staff can update own profile
    )
  );

CREATE POLICY "Staff delete owner only" ON staff
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- Audit logs: all can read, only system writes (no direct insert policy)
DROP POLICY IF EXISTS "Audit logs access own clinic" ON audit_logs;
CREATE POLICY "Audit logs read own clinic" ON audit_logs
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Audit logs write own clinic" ON audit_logs
  FOR INSERT WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));
