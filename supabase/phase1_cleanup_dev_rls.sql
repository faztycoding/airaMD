-- ============================================================================
-- airaMD — DEV RLS bypass cleanup
--
-- The initial dev environment was seeded with `supabase/dev_rls_bypass.sql`
-- which created `"DEV: allow all" ... FOR ALL USING (true) WITH CHECK (true)`
-- policies on every table. Postgres RLS evaluates policies as a logical OR,
-- so the existence of these "allow all" policies means every other
-- role-gated policy added in migrations 004/005/011 is effectively bypassed.
--
-- Migration 004 drops these, but some Supabase projects skipped 004
-- (applied only 001 + later migrations). Re-running `dev_rls_bypass.sql`
-- also re-creates them. This script removes them unconditionally and is
-- safe to run multiple times — `IF EXISTS` handles already-cleaned tables.
-- ============================================================================

BEGIN;

-- Every table that dev_rls_bypass.sql touched.
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

COMMIT;

-- ─── Verify: no "DEV: allow all" policies remain ──────────────────────────
SELECT tablename, policyname
FROM pg_policies
WHERE policyname ILIKE 'DEV%'
ORDER BY tablename;
-- Expected: 0 rows.

-- ─── Sanity: every sensitive table now has ONLY role-gated policies ──────
SELECT tablename,
       COUNT(*)                            AS total_policies,
       COUNT(*) FILTER (WHERE policyname ILIKE 'DEV%') AS dev_policies
FROM pg_policies
WHERE tablename IN (
  'clinics','staff','staff_schedules','patients','appointments',
  'services','treatment_records','patient_photos','face_diagrams',
  'consent_form_templates','consent_forms','products','inventory_transactions',
  'courses','course_sessions','financial_records','message_logs',
  'audit_logs','digital_notepads','treatment_rules'
)
GROUP BY tablename
ORDER BY tablename;
-- Expected: dev_policies = 0 on every row.
