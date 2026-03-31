-- ============================================================
-- DEV MODE: Temporary RLS bypass for development
-- Run this in Supabase SQL Editor AFTER running 001_initial_schema.sql
-- REMOVE before production deployment!
-- ============================================================

-- Allow anonymous read/write access to all tables during development
CREATE POLICY "DEV: allow all" ON clinics FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON staff FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON staff_schedules FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON patients FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON appointments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON services FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON treatment_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON patient_photos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON face_diagrams FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON consent_form_templates FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON consent_forms FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON products FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON inventory_transactions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON courses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON course_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON financial_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON message_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON audit_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON digital_notepads FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "DEV: allow all" ON treatment_rules FOR ALL USING (true) WITH CHECK (true);
