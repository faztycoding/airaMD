-- ============================================================
-- PRODUCTION: Drop DEV RLS bypass policies
-- Run this AFTER all staff have real auth.users accounts
-- ============================================================

-- Drop all DEV bypass policies
DROP POLICY IF EXISTS "DEV: allow all" ON clinics;
DROP POLICY IF EXISTS "DEV: allow all" ON staff;
DROP POLICY IF EXISTS "DEV: allow all" ON staff_schedules;
DROP POLICY IF EXISTS "DEV: allow all" ON patients;
DROP POLICY IF EXISTS "DEV: allow all" ON appointments;
DROP POLICY IF EXISTS "DEV: allow all" ON services;
DROP POLICY IF EXISTS "DEV: allow all" ON treatment_records;
DROP POLICY IF EXISTS "DEV: allow all" ON patient_photos;
DROP POLICY IF EXISTS "DEV: allow all" ON face_diagrams;
DROP POLICY IF EXISTS "DEV: allow all" ON consent_form_templates;
DROP POLICY IF EXISTS "DEV: allow all" ON consent_forms;
DROP POLICY IF EXISTS "DEV: allow all" ON products;
DROP POLICY IF EXISTS "DEV: allow all" ON inventory_transactions;
DROP POLICY IF EXISTS "DEV: allow all" ON courses;
DROP POLICY IF EXISTS "DEV: allow all" ON course_sessions;
DROP POLICY IF EXISTS "DEV: allow all" ON financial_records;
DROP POLICY IF EXISTS "DEV: allow all" ON message_logs;
DROP POLICY IF EXISTS "DEV: allow all" ON audit_logs;
DROP POLICY IF EXISTS "DEV: allow all" ON digital_notepads;
DROP POLICY IF EXISTS "DEV: allow all" ON treatment_rules;

-- ============================================================
-- Upgrade existing policies to include WITH CHECK for inserts
-- (The original 001 schema only had USING, not WITH CHECK)
-- ============================================================

-- Drop old FOR ALL policies and recreate with WITH CHECK
DROP POLICY IF EXISTS "Staff access own clinic" ON staff;
DROP POLICY IF EXISTS "Patients access own clinic" ON patients;
DROP POLICY IF EXISTS "Appointments access own clinic" ON appointments;
DROP POLICY IF EXISTS "Services access own clinic" ON services;
DROP POLICY IF EXISTS "Treatment records access own clinic" ON treatment_records;
DROP POLICY IF EXISTS "Photos access own clinic" ON patient_photos;
DROP POLICY IF EXISTS "Diagrams access own clinic" ON face_diagrams;
DROP POLICY IF EXISTS "Consent templates access own clinic" ON consent_form_templates;
DROP POLICY IF EXISTS "Consent forms access own clinic" ON consent_forms;
DROP POLICY IF EXISTS "Products access own clinic" ON products;
DROP POLICY IF EXISTS "Inventory tx access own clinic" ON inventory_transactions;
DROP POLICY IF EXISTS "Courses access own clinic" ON courses;
DROP POLICY IF EXISTS "Course sessions access own clinic" ON course_sessions;
DROP POLICY IF EXISTS "Financial records access own clinic" ON financial_records;
DROP POLICY IF EXISTS "Message logs access own clinic" ON message_logs;
DROP POLICY IF EXISTS "Audit logs access own clinic" ON audit_logs;
DROP POLICY IF EXISTS "Notepads access own clinic" ON digital_notepads;
DROP POLICY IF EXISTS "Schedules access own clinic" ON staff_schedules;
DROP POLICY IF EXISTS "Treatment rules access own clinic" ON treatment_rules;
DROP POLICY IF EXISTS "Clinics access own" ON clinics;

-- Recreate with USING + WITH CHECK (so inserts are also restricted)
CREATE POLICY "Staff access own clinic" ON staff
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Patients access own clinic" ON patients
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Appointments access own clinic" ON appointments
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Services access own clinic" ON services
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Treatment records access own clinic" ON treatment_records
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Photos access own clinic" ON patient_photos
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Diagrams access own clinic" ON face_diagrams
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Consent templates access own clinic" ON consent_form_templates
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Consent forms access own clinic" ON consent_forms
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Products access own clinic" ON products
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Inventory tx access own clinic" ON inventory_transactions
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Courses access own clinic" ON courses
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Course sessions access own clinic" ON course_sessions
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Financial records access own clinic" ON financial_records
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Message logs access own clinic" ON message_logs
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Audit logs access own clinic" ON audit_logs
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Notepads access own clinic" ON digital_notepads
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Schedules access own clinic" ON staff_schedules
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Treatment rules access own clinic" ON treatment_rules
  FOR ALL USING (clinic_id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (clinic_id IN (SELECT get_my_clinic_ids()));

CREATE POLICY "Clinics access own" ON clinics
  FOR ALL USING (id IN (SELECT get_my_clinic_ids()))
  WITH CHECK (id IN (SELECT get_my_clinic_ids()));

-- ============================================================
-- Special policy: Allow new user signup to create clinic + staff
-- (user has no clinic yet, so get_my_clinic_ids() returns empty)
-- ============================================================

-- Allow authenticated users to insert a new clinic (for first-time signup)
CREATE POLICY "Allow new clinic creation" ON clinics
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Allow authenticated users to insert their own staff record
CREATE POLICY "Allow self staff creation" ON staff
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );

-- ============================================================
-- Push tokens: users can manage their own tokens
-- ============================================================
DROP POLICY IF EXISTS push_tokens_own ON push_tokens;
DROP POLICY IF EXISTS "Users manage own push tokens" ON push_tokens;
CREATE POLICY "Users manage own push tokens" ON push_tokens
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
