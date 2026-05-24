-- ═══════════════════════════════════════════════════════════════════════════
-- airaMD Production DB Audit Runbook (Round 4 pre-launch)
-- Generated: 2026-05-25
--
-- HOW TO USE:
--   1. เปิด Supabase Dashboard → SQL Editor (PRODUCTION project)
--   2. Paste แต่ละ block "AUDIT-N" ทีละอัน → Run → ดูผล
--   3. ถ้าตรงตาม "EXPECT" → ✅ ผ่าน
--   4. ถ้าไม่ตรง → ดู FIX block ที่ตรงกัน
--
-- ⚠️  All queries are READ-ONLY except FIX-* blocks (clearly marked).
-- ═══════════════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-1: ทุก table ที่ airaMD ใช้ต้องมี + RLS ต้องเปิด
-- EXPECT: 20 rows, ทุกตัว rls_status = '✅ RLS ON'
-- ───────────────────────────────────────────────────────────────────────────
WITH expected(tbl) AS (VALUES
  ('appointments'),('audit_logs'),('clinics'),('consent_form_templates'),
  ('consent_forms'),('courses'),('digital_notepads'),('face_diagrams'),
  ('financial_records'),('inventory_transactions'),('message_logs'),
  ('patient_photos'),('patients'),('products'),('push_tokens'),('services'),
  ('staff'),('staff_schedules'),('treatment_records'),('treatment_rules')
)
SELECT
  e.tbl AS table_name,
  CASE WHEN c.relname IS NULL THEN '❌ MISSING'
       WHEN c.relrowsecurity THEN '✅ RLS ON'
       ELSE '⚠️  RLS OFF' END AS rls_status
FROM expected e
LEFT JOIN pg_class c
  ON c.relname = e.tbl
  AND c.relnamespace = 'public'::regnamespace
ORDER BY e.tbl;


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-2: Migration 020 (machines_used JSONB) applied
-- EXPECT: 1 row — jsonb, NOT NULL, default '[]'::jsonb
-- ───────────────────────────────────────────────────────────────────────────
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'treatment_records'
  AND column_name = 'machines_used';


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-3: ไม่มี orphan reference ไปยัง tables ที่ลบไป (11 ตัว)
-- EXPECT: 3 sections ทุก section "(0 rows)"
-- ───────────────────────────────────────────────────────────────────────────

-- 3a. Foreign keys
SELECT '🔗 FK' AS kind, conname, conrelid::regclass AS tbl, pg_get_constraintdef(oid) AS def
FROM pg_constraint
WHERE contype = 'f'
  AND pg_get_constraintdef(oid) ~* 'questions|exam_session|exam_set|student_group|tutorial_progress|user_question_stat|user_errors|translation_log|translation_error|leaderboard_view';

-- 3b. Functions / procedures
SELECT '🧮 FUNC' AS kind, n.nspname || '.' || p.proname AS func, NULL AS def
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND pg_get_functiondef(p.oid) ~* '\m(questions|exam_sessions|exam_sets|student_groups|student_group_memberships|tutorial_progress|user_question_stats|user_errors|translation_logs|translation_errors|leaderboard_view)\M';

-- 3c. Views
SELECT '👁️ VIEW' AS kind, schemaname || '.' || viewname AS view_name, NULL AS def
FROM pg_views
WHERE schemaname = 'public'
  AND definition ~* '\m(questions|exam_sessions|exam_sets|student_groups|tutorial_progress|leaderboard_view)\M';


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-4: Critical indexes (clinic_id, patient_id)
-- EXPECT: has_clinic_idx = true ทุก row, has_patient_idx = true ทุก row
-- ───────────────────────────────────────────────────────────────────────────
WITH tables_with_clinic AS (
  SELECT DISTINCT table_name
  FROM information_schema.columns
  WHERE table_schema = 'public' AND column_name = 'clinic_id'
)
SELECT
  t.table_name,
  EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE tablename = t.table_name
      AND schemaname = 'public'
      AND indexdef ILIKE '%clinic_id%'
  ) AS has_clinic_idx
FROM tables_with_clinic t
ORDER BY t.table_name;


WITH tables_with_patient AS (
  SELECT DISTINCT table_name
  FROM information_schema.columns
  WHERE table_schema = 'public' AND column_name = 'patient_id'
)
SELECT
  t.table_name,
  EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE tablename = t.table_name
      AND schemaname = 'public'
      AND indexdef ILIKE '%patient_id%'
  ) AS has_patient_idx
FROM tables_with_patient t
ORDER BY t.table_name;


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-5: Required RPCs / functions
-- EXPECT: record_treatment_atomic, bump_treatment_version ทั้งคู่อยู่
-- ───────────────────────────────────────────────────────────────────────────
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


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-6: Storage buckets (4 buckets, ไม่ public)
-- EXPECT: 4 rows, public = false
-- ───────────────────────────────────────────────────────────────────────────
SELECT id, name, public, created_at::date
FROM storage.buckets
WHERE id IN ('consent_signatures','face_diagrams','notepads','patient_photos')
ORDER BY id;


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-7: Storage bucket RLS policies
-- EXPECT: แต่ละ bucket มี policies (SELECT/INSERT/UPDATE/DELETE)
-- ───────────────────────────────────────────────────────────────────────────
SELECT bucket_id,
       COUNT(*) AS policy_count,
       string_agg(DISTINCT cmd, ', ') AS commands
FROM (
  SELECT (regexp_match(p.qual, 'bucket_id\s*=\s*''([^'']+)'''))[1] AS bucket_id, p.cmd
  FROM pg_policies p
  WHERE schemaname = 'storage' AND tablename = 'objects'
) x
WHERE bucket_id IN ('consent_signatures','face_diagrams','notepads','patient_photos')
GROUP BY bucket_id
ORDER BY bucket_id;


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-8: Triggers on auth.users (สำคัญ — ผูก profile/staff)
-- EXPECT: ดูว่ามี trigger อะไรอยู่ และไม่อ้างถึง dropped tables
-- ───────────────────────────────────────────────────────────────────────────
SELECT tgname, tgfoid::regproc AS function_name, pg_get_triggerdef(oid) AS definition
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND NOT tgisinternal
ORDER BY tgname;


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-9: RLS Policy spot-check (critical tables)
-- EXPECT: ทุก policy มี clinic_id หรือ patient_id filter (ไม่กว้าง USING(true))
-- ───────────────────────────────────────────────────────────────────────────
SELECT tablename, policyname, cmd,
       CASE WHEN qual ILIKE '%clinic_id%' THEN '✅ clinic-scoped'
            WHEN qual ILIKE '%auth.uid()%' THEN '🟡 user-scoped'
            WHEN qual = 'true' THEN '⚠️ PUBLIC'
            ELSE '?  inspect manually' END AS scope,
       qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'patients','treatment_records','appointments',
    'financial_records','staff','consent_forms',
    'inventory_transactions','products','services','courses'
  )
ORDER BY tablename, cmd;


-- ───────────────────────────────────────────────────────────────────────────
-- AUDIT-10: เช็คว่า migrations 001-020 ใส่ครบ
-- (ดูจากการมี table/column ที่ migration นั้นๆ สร้าง — supabase ไม่มี migration log
--  ในตัว ถ้าใช้ dashboard SQL editor)
-- EXPECT: ทุก row มีของจริง
-- ───────────────────────────────────────────────────────────────────────────
WITH checks(migration, item, kind) AS (VALUES
  ('001_initial_schema',          'patients',                       'table'),
  ('001_initial_schema',          'clinics',                        'table'),
  ('002_update_preferred_channel','patients.preferred_channel',     'column'),
  ('003_push_tokens',             'push_tokens',                    'table'),
  ('007_add_current_medications', 'patients.current_medications',   'column'),
  ('008_hn_year_prefix',          'patients.hn',                    'column'),
  ('009_critical_fixes',          'record_treatment_atomic',        'function'),
  ('013_patients_soft_delete',    'patients.deleted_at',            'column'),
  ('014_inventory_atomic',        'inventory_transactions',         'table'),
  ('015_course_atomic_use',       'use_course_atomic',              'function'),
  ('016_treatment_appointment_link','treatment_records.follow_up_appointment_id','column'),
  ('017_staff_license_number',    'staff.license_number',           'column'),
  ('018_course_products_used',    'courses.products_used',          'column'),
  ('020_treatment_machines_used', 'treatment_records.machines_used','column')
)
SELECT c.migration, c.item, c.kind,
  CASE c.kind
    WHEN 'table'    THEN (SELECT '✅' FROM pg_class WHERE relname = c.item AND relnamespace='public'::regnamespace LIMIT 1)
    WHEN 'column'   THEN (
      SELECT '✅' FROM information_schema.columns
      WHERE table_schema='public'
        AND table_name = split_part(c.item,'.',1)
        AND column_name = split_part(c.item,'.',2)
      LIMIT 1)
    WHEN 'function' THEN (SELECT '✅' FROM pg_proc WHERE proname = c.item AND pronamespace='public'::regnamespace LIMIT 1)
  END AS status
FROM checks c
ORDER BY c.migration, c.item;


-- ═══════════════════════════════════════════════════════════════════════════
-- FIX BLOCKS — รันเฉพาะกรณีพบปัญหาจาก AUDIT ข้างบน
-- ═══════════════════════════════════════════════════════════════════════════

/* FIX-RLS: ถ้า AUDIT-1 เจอ table RLS OFF → ทำตามรูปนี้
   ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;
*/

/* FIX-IDX-CLINIC: ถ้า AUDIT-4 เจอ has_clinic_idx = false → สร้าง index
   CREATE INDEX IF NOT EXISTS idx_<table>_clinic_id ON public.<table>(clinic_id);
*/

/* FIX-IDX-PATIENT: ถ้า AUDIT-4 เจอ has_patient_idx = false → สร้าง index
   CREATE INDEX IF NOT EXISTS idx_<table>_patient_id ON public.<table>(patient_id);
*/

/* FIX-MIGRATION-020: ถ้า AUDIT-2 ไม่มีผลลัพธ์
   ALTER TABLE treatment_records
     ADD COLUMN IF NOT EXISTS machines_used JSONB NOT NULL DEFAULT '[]'::jsonb;
*/

/* FIX-ORPHAN-FK: ถ้า AUDIT-3a เจอ FK ที่อ้างถึง dropped table
   ALTER TABLE <table> DROP CONSTRAINT IF EXISTS <constraint_name>;
*/
