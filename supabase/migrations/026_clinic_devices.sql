-- ============================================================
-- 026_clinic_devices.sql
-- Clinic-managed device/machine list (e.g. Ulthera Prime, Ultraformer III,
-- Oligio) used as quick-pick presets in the treatment form. The OWNER manages
-- the list in Settings; defaults are seeded per-clinic from the app.
-- ============================================================

CREATE TABLE IF NOT EXISTS clinic_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'LASER', -- mirrors TreatmentCategory.dbValue
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clinic_devices_clinic ON clinic_devices(clinic_id);

ALTER TABLE clinic_devices ENABLE ROW LEVEL SECURITY;

-- Read: any member of the clinic. Write: OWNER only.
DROP POLICY IF EXISTS "Devices read own clinic" ON clinic_devices;
CREATE POLICY "Devices read own clinic" ON clinic_devices
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

DROP POLICY IF EXISTS "Devices write owner" ON clinic_devices;
CREATE POLICY "Devices write owner" ON clinic_devices
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

DROP POLICY IF EXISTS "Devices update owner" ON clinic_devices;
CREATE POLICY "Devices update owner" ON clinic_devices
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

DROP POLICY IF EXISTS "Devices delete owner" ON clinic_devices;
CREATE POLICY "Devices delete owner" ON clinic_devices
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );
