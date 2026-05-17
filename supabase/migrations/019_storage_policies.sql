-- Migration 019: Storage RLS policies for clinic-scoped buckets
--
-- All file paths follow the convention: {clinic_id}/{patient_id}/{file_name}
-- so we extract the leading UUID from `name` and check it against the
-- staff member's clinics via get_my_clinic_ids().
--
-- Buckets governed: patient-photos, face-diagrams, consent-signatures,
--                   consent-pdfs, notepads.
--
-- Idempotent — drops policies first then re-creates so the migration can
-- be re-run after a schema reset.

DO $$
DECLARE
  bucket_id TEXT;
BEGIN
  FOREACH bucket_id IN ARRAY ARRAY[
    'patient-photos',
    'face-diagrams',
    'consent-signatures',
    'consent-pdfs',
    'notepads'
  ]
  LOOP
    -- Drop existing policies (idempotent re-apply)
    EXECUTE format(
      'DROP POLICY IF EXISTS "%s_clinic_read" ON storage.objects',
      bucket_id
    );
    EXECUTE format(
      'DROP POLICY IF EXISTS "%s_clinic_write" ON storage.objects',
      bucket_id
    );
    EXECUTE format(
      'DROP POLICY IF EXISTS "%s_clinic_update" ON storage.objects',
      bucket_id
    );
    EXECUTE format(
      'DROP POLICY IF EXISTS "%s_clinic_delete" ON storage.objects',
      bucket_id
    );
  END LOOP;
END $$;

-- ─── patient-photos ───────────────────────────────────────────
CREATE POLICY "patient-photos_clinic_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'patient-photos'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "patient-photos_clinic_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'patient-photos'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "patient-photos_clinic_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'patient-photos'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "patient-photos_clinic_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'patient-photos'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

-- ─── face-diagrams ────────────────────────────────────────────
CREATE POLICY "face-diagrams_clinic_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'face-diagrams'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "face-diagrams_clinic_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'face-diagrams'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "face-diagrams_clinic_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'face-diagrams'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "face-diagrams_clinic_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'face-diagrams'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

-- ─── consent-signatures ───────────────────────────────────────
CREATE POLICY "consent-signatures_clinic_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'consent-signatures'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "consent-signatures_clinic_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'consent-signatures'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "consent-signatures_clinic_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'consent-signatures'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "consent-signatures_clinic_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'consent-signatures'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

-- ─── consent-pdfs ─────────────────────────────────────────────
CREATE POLICY "consent-pdfs_clinic_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'consent-pdfs'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "consent-pdfs_clinic_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'consent-pdfs'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "consent-pdfs_clinic_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'consent-pdfs'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "consent-pdfs_clinic_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'consent-pdfs'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

-- ─── notepads ─────────────────────────────────────────────────
CREATE POLICY "notepads_clinic_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'notepads'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "notepads_clinic_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'notepads'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "notepads_clinic_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'notepads'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "notepads_clinic_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'notepads'
    AND (split_part(name, '/', 1))::uuid IN (SELECT get_my_clinic_ids())
  );
