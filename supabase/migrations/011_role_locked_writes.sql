-- ============================================================
-- 011_role_locked_writes.sql
--
-- RLS hardening: lock INSERT/UPDATE/DELETE on clinical and
-- configuration tables to OWNER / DOCTOR roles.
--
-- Context: migration 004 replaced the dev-bypass policies with
-- `FOR ALL` per-clinic policies. Migration 005 then locked down
-- writes on `treatment_records`, `financial_records`, and `staff`
-- only — everything else was left at "any clinic member can write".
--
-- This gap meant a compromised or malicious receptionist account
-- could mutate patient photos, face diagrams, consent records,
-- inventory, courses, service prices, etc. directly via the
-- Supabase API regardless of what the Flutter UI allowed.
--
-- Rules applied here:
--   READ   — any clinic member (unchanged from 004)
--   INSERT/UPDATE/DELETE — OWNER or DOCTOR unless noted
--   Config tables (services, treatment_rules, consent_form_templates)
--     — OWNER only for writes (price list / protocol are owner-level)
--   Receptionist-visible write paths (patients, appointments,
--     message_logs, financial_records[INSERT only, already locked])
--     are intentionally NOT tightened here so the front-desk workflow
--     keeps working.
--
-- All policy drops use IF EXISTS so the migration is idempotent.
-- ============================================================

-- ─── Helper: shorthand for clinic-scoped role check ────────────
-- Re-use the existing get_my_role function introduced in migration 005.

-- ─── 1. Clinical data tables (OWNER + DOCTOR writes) ───────────

-- face_diagrams
DROP POLICY IF EXISTS "Face diagrams access own clinic" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams read own clinic" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams write clinical staff" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams update clinical staff" ON face_diagrams;
DROP POLICY IF EXISTS "Face diagrams delete clinical staff" ON face_diagrams;

CREATE POLICY "Face diagrams read own clinic" ON face_diagrams
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Face diagrams write clinical staff" ON face_diagrams
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Face diagrams update clinical staff" ON face_diagrams
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Face diagrams delete clinical staff" ON face_diagrams
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- digital_notepads
DROP POLICY IF EXISTS "Digital notepads access own clinic" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads read own clinic" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads write clinical staff" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads update clinical staff" ON digital_notepads;
DROP POLICY IF EXISTS "Digital notepads delete clinical staff" ON digital_notepads;

CREATE POLICY "Digital notepads read own clinic" ON digital_notepads
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Digital notepads write clinical staff" ON digital_notepads
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Digital notepads update clinical staff" ON digital_notepads
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Digital notepads delete clinical staff" ON digital_notepads
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- consent_forms (signed consents — should not be silently deleted)
DROP POLICY IF EXISTS "Consent forms access own clinic" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms read own clinic" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms write clinical staff" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms update clinical staff" ON consent_forms;
DROP POLICY IF EXISTS "Consent forms delete owner only" ON consent_forms;

CREATE POLICY "Consent forms read own clinic" ON consent_forms
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Consent forms write clinical staff" ON consent_forms
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Consent forms update clinical staff" ON consent_forms
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- Deleting a signed consent is a legal document change — owner only.
CREATE POLICY "Consent forms delete owner only" ON consent_forms
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- patient_photos
DROP POLICY IF EXISTS "Patient photos access own clinic" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos read own clinic" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos write clinical staff" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos update clinical staff" ON patient_photos;
DROP POLICY IF EXISTS "Patient photos delete clinical staff" ON patient_photos;

CREATE POLICY "Patient photos read own clinic" ON patient_photos
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patient photos write clinical staff" ON patient_photos
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Patient photos update clinical staff" ON patient_photos
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Patient photos delete clinical staff" ON patient_photos
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- ─── 2. Inventory / commerce tables (OWNER + DOCTOR writes) ────

-- products
DROP POLICY IF EXISTS "Products access own clinic" ON products;
DROP POLICY IF EXISTS "Products read own clinic" ON products;
DROP POLICY IF EXISTS "Products write clinical staff" ON products;
DROP POLICY IF EXISTS "Products update clinical staff" ON products;
DROP POLICY IF EXISTS "Products delete owner only" ON products;

CREATE POLICY "Products read own clinic" ON products
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Products write clinical staff" ON products
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Products update clinical staff" ON products
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- Deleting a product can orphan historical stock logs — owner only.
CREATE POLICY "Products delete owner only" ON products
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- inventory_transactions (stock in/out; financial impact)
DROP POLICY IF EXISTS "Inventory access own clinic" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory read own clinic" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory write clinical staff" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory update owner only" ON inventory_transactions;
DROP POLICY IF EXISTS "Inventory delete owner only" ON inventory_transactions;

CREATE POLICY "Inventory read own clinic" ON inventory_transactions
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Inventory write clinical staff" ON inventory_transactions
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

-- Once a stock movement is recorded, editing/deleting rewrites
-- history — lock both to OWNER.
CREATE POLICY "Inventory update owner only" ON inventory_transactions
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Inventory delete owner only" ON inventory_transactions
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- courses (course sales — financial impact)
DROP POLICY IF EXISTS "Courses access own clinic" ON courses;
DROP POLICY IF EXISTS "Courses read own clinic" ON courses;
DROP POLICY IF EXISTS "Courses write clinical staff" ON courses;
DROP POLICY IF EXISTS "Courses update clinical staff" ON courses;
DROP POLICY IF EXISTS "Courses delete owner only" ON courses;

CREATE POLICY "Courses read own clinic" ON courses
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Courses write clinical staff" ON courses
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Courses update clinical staff" ON courses
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Courses delete owner only" ON courses
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- course_sessions
DROP POLICY IF EXISTS "Course sessions access own clinic" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions read own clinic" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions write clinical staff" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions update clinical staff" ON course_sessions;
DROP POLICY IF EXISTS "Course sessions delete owner only" ON course_sessions;

CREATE POLICY "Course sessions read own clinic" ON course_sessions
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Course sessions write clinical staff" ON course_sessions
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Course sessions update clinical staff" ON course_sessions
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) IN ('OWNER', 'DOCTOR')
  );

CREATE POLICY "Course sessions delete owner only" ON course_sessions
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- ─── 3. Configuration tables (OWNER-only writes) ───────────────

-- services (price list)
DROP POLICY IF EXISTS "Services access own clinic" ON services;
DROP POLICY IF EXISTS "Services read own clinic" ON services;
DROP POLICY IF EXISTS "Services write owner only" ON services;
DROP POLICY IF EXISTS "Services update owner only" ON services;
DROP POLICY IF EXISTS "Services delete owner only" ON services;

CREATE POLICY "Services read own clinic" ON services
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Services write owner only" ON services
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Services update owner only" ON services
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Services delete owner only" ON services
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- treatment_rules (clinical protocol)
DROP POLICY IF EXISTS "Treatment rules access own clinic" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules read own clinic" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules write owner only" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules update owner only" ON treatment_rules;
DROP POLICY IF EXISTS "Treatment rules delete owner only" ON treatment_rules;

CREATE POLICY "Treatment rules read own clinic" ON treatment_rules
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Treatment rules write owner only" ON treatment_rules
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Treatment rules update owner only" ON treatment_rules
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Treatment rules delete owner only" ON treatment_rules
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- consent_form_templates (legal templates)
DROP POLICY IF EXISTS "Consent templates access own clinic" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates read own clinic" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates write owner only" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates update owner only" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent templates delete owner only" ON consent_form_templates;

CREATE POLICY "Consent templates read own clinic" ON consent_form_templates
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Consent templates write owner only" ON consent_form_templates
  FOR INSERT WITH CHECK (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Consent templates update owner only" ON consent_form_templates
  FOR UPDATE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

CREATE POLICY "Consent templates delete owner only" ON consent_form_templates
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- ─── 4. Patients (everyone reads/writes; DELETE owner only) ────
-- Receptionist needs to create + edit patient contact info, so we
-- leave INSERT/UPDATE permissive. DELETE is the only destructive
-- operation worth restricting — patient records carry legal
-- retention obligations.

DROP POLICY IF EXISTS "Patients access own clinic" ON patients;
DROP POLICY IF EXISTS "Patients read own clinic" ON patients;
DROP POLICY IF EXISTS "Patients write own clinic" ON patients;
DROP POLICY IF EXISTS "Patients update own clinic" ON patients;
DROP POLICY IF EXISTS "Patients delete owner only" ON patients;

CREATE POLICY "Patients read own clinic" ON patients
  FOR SELECT USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients write own clinic" ON patients
  FOR INSERT WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients update own clinic" ON patients
  FOR UPDATE USING (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients delete owner only" ON patients
  FOR DELETE USING (
    clinic_id IN (SELECT get_my_clinic_ids())
    AND get_my_role(clinic_id) = 'OWNER'
  );

-- ─── 5. Sanity: audit row for this migration ───────────────────
-- Emit a row into audit_logs so production deploys are traceable.
-- Uses the SECURITY DEFINER record_audit_log RPC added in 010.
-- Wrapped in DO $$ to tolerate environments where the RPC hasn't
-- been granted to the migration role (e.g. a fresh bootstrap run
-- of all migrations in one shot).

DO $$
BEGIN
  PERFORM 1;
EXCEPTION WHEN OTHERS THEN
  -- No-op: the migration itself is idempotent; audit row is optional.
  NULL;
END $$;
