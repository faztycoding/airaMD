-- ═══════════════════════════════════════════════════════════════════════════
-- airaMD Audit Runbook v2 (READ-ONLY)
--
-- ⚠️  วิธีรัน: paste แค่ "1 AUDIT ต่อครั้ง" แล้วกด Run
--             อย่ารันทั้งไฟล์พร้อมกัน — Supabase editor จะ error
--
-- แต่ละ AUDIT ถูกออกแบบให้ standalone — เลือกตั้งแต่ "-- AUDIT-N:" จนถึง ";"
-- ═══════════════════════════════════════════════════════════════════════════


-- AUDIT-1: tables exist + RLS enabled  ────────────────────────────────────────
-- EXPECT: 20 rows, rls_status = '✅ RLS ON' ทุกตัว
SELECT
  e.tbl AS table_name,
  COALESCE(
    CASE WHEN c.relrowsecurity THEN '✅ RLS ON' ELSE '⚠️  RLS OFF' END,
    '❌ MISSING'
  ) AS rls_status
FROM (VALUES
  ('appointments'),('audit_logs'),('clinics'),('consent_form_templates'),
  ('consent_forms'),('courses'),('digital_notepads'),('face_diagrams'),
  ('financial_records'),('inventory_transactions'),('message_logs'),
  ('patient_photos'),('patients'),('products'),('push_tokens'),('services'),
  ('staff'),('staff_schedules'),('treatment_records'),('treatment_rules')
) AS e(tbl)
LEFT JOIN pg_class c
  ON c.relname = e.tbl AND c.relnamespace = 'public'::regnamespace
ORDER BY e.tbl;


-- AUDIT-2: migration 020 (machines_used)  ─────────────────────────────────────
-- EXPECT: 1 row — jsonb, NOT NULL, default '[]'::jsonb
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'treatment_records'
  AND column_name  = 'machines_used';


-- AUDIT-3a: orphan FK referencing dropped tables  ─────────────────────────────
-- EXPECT: 0 rows
SELECT conname, conrelid::regclass AS tbl, pg_get_constraintdef(oid) AS def
FROM pg_constraint
WHERE contype = 'f'
  AND pg_get_constraintdef(oid) ~* '(questions|exam_session|exam_set|student_group|tutorial_progress|user_question_stat|user_errors|translation_log|translation_error|leaderboard_view)';


-- AUDIT-3b: orphan functions referencing dropped tables  ──────────────────────
-- EXPECT: 0 rows
SELECT n.nspname AS schema, p.proname AS function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND pg_get_functiondef(p.oid) ~* '\m(questions|exam_sessions|exam_sets|student_groups|student_group_memberships|tutorial_progress|user_question_stats|user_errors|translation_logs|translation_errors|leaderboard_view)\M';


-- AUDIT-3c: orphan views  ─────────────────────────────────────────────────────
-- EXPECT: 0 rows
SELECT schemaname, viewname
FROM pg_views
WHERE schemaname = 'public'
  AND definition ~* '\m(questions|exam_sessions|exam_sets|student_groups|tutorial_progress|leaderboard_view)\M';


-- AUDIT-4a: clinic_id index coverage  ─────────────────────────────────────────
-- EXPECT: has_clinic_idx = true ทุก row
SELECT
  c.table_name,
  EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = c.table_name
      AND indexdef ILIKE '%clinic_id%'
  ) AS has_clinic_idx
FROM (
  SELECT DISTINCT table_name
  FROM information_schema.columns
  WHERE table_schema = 'public' AND column_name = 'clinic_id'
) c
ORDER BY c.table_name;


-- AUDIT-4b: patient_id index coverage  ────────────────────────────────────────
-- EXPECT: has_patient_idx = true ทุก row
SELECT
  c.table_name,
  EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = c.table_name
      AND indexdef ILIKE '%patient_id%'
  ) AS has_patient_idx
FROM (
  SELECT DISTINCT table_name
  FROM information_schema.columns
  WHERE table_schema = 'public' AND column_name = 'patient_id'
) c
ORDER BY c.table_name;


-- AUDIT-5: required RPCs / functions  ─────────────────────────────────────────
-- EXPECT: record_treatment_atomic + bump_treatment_version (อย่างน้อย)
SELECT proname, pronargs, prorettype::regtype AS returns
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'record_treatment_atomic',
    'bump_treatment_version',
    'use_course_atomic',
    'create_owner_atomic'
  )
ORDER BY proname;


-- AUDIT-6: storage buckets present  ───────────────────────────────────────────
-- EXPECT: 4 rows — consent_signatures, face_diagrams, notepads, patient_photos
SELECT id, name, public, created_at::date AS created
FROM storage.buckets
WHERE id IN ('consent_signatures','face_diagrams','notepads','patient_photos')
ORDER BY id;


-- AUDIT-7: storage RLS policies (simple count by bucket)  ─────────────────────
-- EXPECT: ทุก bucket มี ≥1 policy
SELECT
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename  = 'objects'
ORDER BY policyname;


-- AUDIT-8: triggers on auth.users  ────────────────────────────────────────────
-- EXPECT: ดูว่า trigger ใช้ function อะไร — ไม่ควรอ้างถึง dropped tables
SELECT tgname, tgfoid::regproc AS function_name
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND NOT tgisinternal
ORDER BY tgname;


-- AUDIT-9: RLS policy scope check (critical tables)  ──────────────────────────
-- EXPECT: ไม่มี '⚠️ PUBLIC' — ทุกแถวควรเป็น clinic-scoped หรือ user-scoped
SELECT
  tablename,
  policyname,
  cmd,
  CASE WHEN qual ILIKE '%clinic_id%'        THEN '✅ clinic-scoped'
       WHEN qual ILIKE '%auth.uid()%'       THEN '🟡 user-scoped'
       WHEN qual = 'true' OR qual IS NULL   THEN '⚠️ PUBLIC'
       ELSE '?  inspect manually' END AS scope
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'patients','treatment_records','appointments','financial_records',
    'staff','consent_forms','inventory_transactions','products','services','courses'
  )
ORDER BY tablename, cmd;


-- AUDIT-10: migration coverage (sentinel objects from each migration)  ────────
-- EXPECT: status = '✅' ทุก row
SELECT c.migration, c.item, c.kind,
  CASE c.kind
    WHEN 'table'    THEN (SELECT '✅' FROM pg_class WHERE relname = c.item AND relnamespace='public'::regnamespace LIMIT 1)
    WHEN 'column'   THEN (
      SELECT '✅' FROM information_schema.columns
      WHERE table_schema='public'
        AND table_name  = split_part(c.item,'.',1)
        AND column_name = split_part(c.item,'.',2)
      LIMIT 1)
    WHEN 'function' THEN (SELECT '✅' FROM pg_proc WHERE proname = c.item AND pronamespace='public'::regnamespace LIMIT 1)
  END AS status
FROM (VALUES
  ('001_initial_schema',           'patients',                                'table'),
  ('001_initial_schema',           'clinics',                                 'table'),
  ('002_update_preferred_channel', 'patients.preferred_channel',              'column'),
  ('003_push_tokens',              'push_tokens',                             'table'),
  ('007_add_current_medications',  'patients.current_medications',            'column'),
  ('008_hn_year_prefix',           'patients.hn',                             'column'),
  ('009_critical_fixes',           'record_treatment_atomic',                 'function'),
  ('013_patients_soft_delete',     'patients.deleted_at',                     'column'),
  ('014_inventory_atomic',         'inventory_transactions',                  'table'),
  ('015_course_atomic_use',        'use_course_atomic',                       'function'),
  ('016_treatment_appointment_link','treatment_records.follow_up_appointment_id','column'),
  ('017_staff_license_number',    'staff.license_number',                     'column'),
  ('018_course_products_used',    'courses.products_used',                    'column'),
  ('020_treatment_machines_used', 'treatment_records.machines_used',          'column')
) AS c(migration, item, kind)
ORDER BY c.migration;
