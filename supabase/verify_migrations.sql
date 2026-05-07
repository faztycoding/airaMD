-- ============================================================
-- AiraMD — Pre-Demo Migration Verification Script
--
-- Purpose:
--   ตรวจสอบว่า migrations 008, 009, 010 ถูก apply ครบและพร้อมใช้งาน
--   ก่อนนำเสนอ demo ให้ลูกค้า
--
-- How to run:
--   psql -h <supabase-host> -U postgres -d postgres -f verify_migrations.sql
--   หรือ paste ใน Supabase Studio SQL editor
--
-- Expected output:
--   ทุก SELECT ต้องคืนค่า expected ตามที่ระบุ comment ด้านขวา
--   ถ้ามีอะไรไม่ตรงให้รัน migration ที่เกี่ยวข้องซ้ำ (idempotent)
-- ============================================================

-- ─── 1. ตรวจสอบฟังก์ชัน ───────────────────────────────────────
SELECT routine_name, security_type
  FROM information_schema.routines
 WHERE routine_schema = 'public'
   AND routine_name IN (
     'generate_patient_hn',          -- migration 008/009
     'deduct_stock_atomic',          -- migration 009
     'record_treatment_atomic',      -- migration 009
     'get_my_clinic_ids',            -- migration 009 (RLS perf)
     'get_my_role',                  -- migration 009 (RLS perf)
     'populate_course_sessions',     -- migration 009
     'bump_treatment_version',       -- migration 009
     'get_today_revenue',            -- migration 009
     'get_patient_full',             -- migration 009
     'escape_like',                  -- migration 009
     'record_audit_log'              -- migration 010
   )
 ORDER BY routine_name;
-- Expected: 11 rows. record_audit_log + get_my_clinic_ids + get_my_role
-- ต้องมี security_type = 'DEFINER' ที่เหลือเป็น 'INVOKER'

-- ─── 2. ตรวจ version column บน treatment_records ─────────────
SELECT column_name, data_type, column_default, is_nullable
  FROM information_schema.columns
 WHERE table_schema = 'public'
   AND table_name = 'treatment_records'
   AND column_name = 'version';
-- Expected: 1 row, integer, default '1', NO

-- ─── 3. ตรวจ trigger ─────────────────────────────────────────
SELECT trigger_name, event_manipulation, event_object_table
  FROM information_schema.triggers
 WHERE event_object_schema = 'public'
   AND trigger_name IN (
     'courses_populate_sessions',
     'treatment_records_version'
   )
 ORDER BY trigger_name;
-- Expected: 2 rows (INSERT + UPDATE respectively)

-- ─── 4. ตรวจ CHECK constraints ────────────────────────────────
SELECT conname, conrelid::regclass AS table_name
  FROM pg_constraint
 WHERE conname IN (
     'staff_pin_hash_format',
     'financial_records_amount_nonneg',
     'course_sessions_unique_number'
   )
 ORDER BY conname;
-- Expected: 3 rows

-- ─── 5. ตรวจ GIN indexes ─────────────────────────────────────
SELECT indexname, tablename
  FROM pg_indexes
 WHERE schemaname = 'public'
   AND indexname IN (
     'idx_patients_drug_allergies_gin',
     'idx_patients_medical_conditions_gin',
     'idx_patients_current_medications_gin',
     'idx_staff_user_active'
   )
 ORDER BY indexname;
-- Expected: 4 rows

-- ─── 6. ตรวจว่า audit_logs ถูก lock down (REVOKE) ─────────────
SELECT grantee, privilege_type
  FROM information_schema.role_table_grants
 WHERE table_schema = 'public'
   AND table_name = 'audit_logs'
   AND grantee = 'authenticated'
 ORDER BY privilege_type;
-- Expected: 1 row only — privilege_type = 'SELECT'
-- ถ้าเห็น INSERT/UPDATE/DELETE ของ authenticated = migration 010 ยังไม่ apply!

-- ─── 7. ตรวจว่า RPC `record_audit_log` GRANT EXECUTE ให้ authenticated ─
SELECT routine_name, grantee, privilege_type
  FROM information_schema.routine_privileges
 WHERE routine_schema = 'public'
   AND routine_name = 'record_audit_log'
   AND grantee = 'authenticated';
-- Expected: 1 row, EXECUTE

-- ─── 8. Smoke test: ลอง deduct stock บน product ปลอม ──────────
-- (ถ้ายังไม่มี product, skip ส่วนนี้)
DO $$
DECLARE
  test_product_id UUID;
BEGIN
  SELECT id INTO test_product_id
    FROM products
   WHERE stock_quantity > 10
   LIMIT 1;

  IF test_product_id IS NULL THEN
    RAISE NOTICE 'No product available for smoke test — skipping.';
    RETURN;
  END IF;

  -- Deduct 0.001 (จะ rollback อยู่แล้วเพราะอยู่ใน DO $$)
  PERFORM deduct_stock_atomic(test_product_id, 0.001);
  RAISE NOTICE 'deduct_stock_atomic OK on product %', test_product_id;
  -- Roll back โดยการ raise exception (DO block ไม่ commit)
  RAISE EXCEPTION 'rollback_after_smoke_test';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM = 'rollback_after_smoke_test' THEN
      RAISE NOTICE 'Smoke test passed — rolled back OK';
    ELSE
      RAISE NOTICE 'Smoke test FAILED: %', SQLERRM;
    END IF;
END $$;

-- ─── 9. ตรวจจำนวน HN ที่ใช้ format ใหม่ vs เก่า ─────────────────
SELECT
  CASE
    WHEN hn ~ '^C-\d{4}-\d{5}$' THEN 'new (C-YYYY-NNNNN)'
    WHEN hn ~ '^C-\d{5}$'       THEN 'legacy (C-NNNNN)'
    ELSE 'other'
  END AS format,
  COUNT(*) AS n
  FROM patients
 GROUP BY 1
 ORDER BY 1;
-- Patients ที่สร้างหลัง migration 008 ต้องเป็น "new"
-- Patients เก่ายังคงเป็น "legacy" ไม่กระทบฟังก์ชัน

-- ─── 10. ตรวจ migration ล่าสุดที่ Supabase ทำ track ───────────
-- (ถ้าใช้ supabase CLI; ถ้าไม่ตาราง schema_migrations อาจไม่มี)
SELECT version, name
  FROM supabase_migrations.schema_migrations
 ORDER BY version DESC
 LIMIT 5;
-- Expected: บรรทัดบนสุดควรเป็น "010_audit_secure_writes"

-- ============================================================
-- สรุป: ถ้าทุกข้อข้างต้นคืนค่าตาม Expected → พร้อม demo ได้เลย
-- ถ้ามีอะไรไม่ตรง → รัน supabase db push อีกครั้ง หรือ paste
-- ไฟล์ migration ที่เกี่ยวข้องลงใน Supabase Studio (idempotent)
-- ============================================================
