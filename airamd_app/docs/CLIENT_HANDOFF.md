# เอกสารส่งมอบให้ลูกค้า

## สรุปการส่งมอบ

รีลีสนี้ทำให้ระบบคลินิกอยู่ในสถานะที่พร้อมสำหรับลูกค้าอย่างชัดเจน โดยโฟกัสตามขอบเขตที่ตกลงไว้ในบรีฟปัจจุบัน

## สิ่งที่พร้อมใช้งานแล้วตอนนี้

### Workflow ด้าน Clinical
- การลงทะเบียนและแก้ไขข้อมูลผู้รับบริการ
- การตรวจสอบข้อมูลติดต่อและข้อมูลระบุตัวตนที่เข้มขึ้น
- การนัดหมายพร้อมการ assign แพทย์ผู้รับผิดชอบ
- บันทึกการรักษาที่เชื่อม doctor ownership, SOAP notes, follow-up planning และการใช้สินค้าที่คำนึงถึงความปลอดภัย
- การเข้าถึง consent form และ digital notepad สำหรับ role ด้าน clinical

### Workflow ด้านปฏิบัติการ
- รับเข้า เบิกใช้ สูญเสีย และปรับยอด inventory
- การตัดสต็อกแบบทศนิยมจากการรักษา
- การมองเห็น batch และ expiry ในประวัติ inventory
- บริบทของ low-stock และ expiry ที่ช่วยให้ใช้งานจริงได้ง่ายขึ้น

### Workflow ด้านการสื่อสาร
- การบันทึกประวัติข้อความ
- ปุ่มลัด LINE / WhatsApp / โทรออก
- UI ที่รับรู้บริบทของช่องทางติดต่อที่มีจริง

### Workflow ด้านรายได้และการเงิน
- การบันทึกรับชำระและรายการค้างชำระ
- การติดตามยอด outstanding
- การเข้าถึงข้อมูลทางการเงินเฉพาะ role ที่ได้รับอนุญาต

### การดูแลระบบและ Governance
- หน้า settings ใช้ข้อมูลพนักงานจริงใน profile card
- audit log ครอบคลุม workflow สำคัญ
- การมองเห็น UI และการป้องกัน route ตามสิทธิ์ในหน้าที่มีความอ่อนไหว

## สิ่งที่ปรับปรุงสำคัญในรอบสุดท้าย

- doctor ownership เชื่อมต่อจาก appointment ไปถึง treatment
- มี appointment completion loop หลังบันทึก treatment
- route ของการสร้างและแก้ไขผู้รับบริการถูก harden มากขึ้น
- empty states และ save feedback ดูสะอาดและพรีเมียมขึ้น
- inventory มี traceability ดีขึ้นโดยไม่ต้องเพิ่มความเสี่ยงจากการรื้อ schema ใหญ่

### Audit Hardening (รอบ 1)
- RBAC fallback เปลี่ยนเป็น deny-by-default (receptionist) ป้องกันการเข้าถึงข้อมูลความลับกรณี staff ยังโหลดไม่เสร็จ
- PatientForm null clinicId safety แสดง feedback แทน crash
- Financial validation ครอบคลุม empty, invalid, non-positive, >10M
- Inventory validation ครอบคลุม stock deduction guard + wastage
- SettingsScreen inject auth providers แทน Supabase.instance ตรง
- ลด Supabase.instance ใน auth gate, login, storage screens, services เหลือ 5 จุด (infrastructure)
- Treatment post-save แยกเป็น TreatmentPostSaveService ที่ test ได้

### Production Hardening (รอบล่าสุด — May 2026)

**ฐานข้อมูล (Migrations 008–010)**
- `008_hn_year_prefix.sql` — HN format `C-YYYY-NNNNN` รีเซ็ต sequence ต่อคลินิกต่อปี
- `009_critical_fixes.sql`
  - Race-safe HN generation ผ่าน `pg_advisory_xact_lock`
  - Atomic stock deduction RPC (`deduct_stock_atomic`)
  - Atomic treatment + inventory write RPC (`record_treatment_atomic`)
  - PIN hash format CHECK (bcrypt prefix only)
  - Financial amount ≥ 0 + course session UNIQUE constraints
  - RLS performance — `auth.uid()` cached via subquery, partial index
  - GIN indexes on `drug_allergies`, `medical_conditions`, `current_medications`
  - Course sessions auto-create trigger
  - Optimistic concurrency `version` column + trigger บน `treatment_records`
  - N+1 eliminator RPCs: `get_today_revenue(clinic_id)`, `get_patient_full(patient_id)`
- `010_audit_secure_writes.sql` — REVOKE direct INSERT บน `audit_logs` ทุก write ผ่าน `record_audit_log` SECURITY DEFINER RPC ที่บังคับ `user_id` + `timestamp` server-side (กัน spoofing)

**Flutter (Round 2-3)**
- `RepositoryException` sealed hierarchy (`InsufficientStockException`, `InvalidQuantityException`, `NotFoundException`, `VersionConflictException`)
- Treatment save ใช้ `record_treatment_atomic` — partial-state class ของบั๊กหายไปเลย
- Offline queue รองรับ RPC action: ถ้าออฟไลน์ตอน save treatment จะ queue RPC params ตัวเดิมไว้ replay ตอนเชื่อมต่อ → ยังคง atomic เสมอ
- `PatientProfileBundle` typed model + `get_patient_full` RPC ลด round trip จาก 4-5 → 1
- Patient list pagination — `paginatedPatientsProvider` + infinite scroll sentinel
- Environment-aware `AppConfig` (dev/staging/prod) ผูกกับ AutoSyncEngine retry/cache TTL
- AiraTapEffect รองรับ accessibility semantics (label/hint/button/enabled) → screen reader อ่านปุ่มทุกที่ในแอป
- `CrashReporter` boilerplate (Sentry-shape API) — รอ DSN เพื่อ enable

## แนวทางการสื่อสารกับลูกค้า

### ควรวาง positioning ของระบบว่าเป็น
- แพลตฟอร์ม workflow สำหรับคลินิก
- ระบบนัดหมายและการรักษาที่เข้าใจ doctor ownership
- workspace สำหรับ front-office และ clinical ที่มีการควบคุมตามบทบาทผู้ใช้งาน

### จุดแข็งที่ควรเน้น
- ความชัดเจนของ ownership
- ความปลอดภัยเชิงปฏิบัติการ
- ขอบเขตสิทธิ์ที่น่าเชื่อถือ
- UX ที่พร้อมใช้ในงานประจำวันของทีมคลินิก

## สิ่งที่เป็น future enhancement

สิ่งเหล่านี้เป็นโอกาสในการขยายผลิตภัณฑ์ต่อ ไม่ใช่ blocker ของบรีฟปัจจุบัน:

- การตัดสต็อกตาม lot จริงในระดับ batch
- workflow ด้าน supplier / PO / GRN
- workflow คืนของให้ supplier
- policy การจัดการนัดหมายของ receptionist ที่ละเอียดขึ้น
- analytics ด้าน batch และการ forecast inventory ขั้นสูง

## Checklist ก่อน handoff

### โค้ด
- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 191 tests pass
- [x] CI workflow แก้ working dir เป็น `airamd_app` + Flutter 3.41.0
- [x] Migrations 008, 009, 010 idempotent (ปลอดภัยกรณีรันซ้ำ)

### ฐานข้อมูล (ลูกค้ารัน supabase db push แล้ว)
- [x] Migration 008 applied
- [x] Migration 009 applied
- [x] Migration 010 applied
- [ ] Verify smoke flow: login → save 1 treatment → confirm `treatment_records` + `inventory_transactions` + stock deduction พร้อมกัน 1 transaction
- [ ] Verify `audit_logs` row เกิดขึ้นทุกครั้งที่มี write action สำคัญ (`user_id` ตรงกับ staff ที่ลงชื่อเข้าใช้)
- [ ] Verify direct `INSERT INTO audit_logs` จาก client ถูก reject (HTTP 401/403)

### Demo & data
- [x] Seed file: `supabase/seed.sql` (clinic + treatment_rules + ~25 products + ~15 services + consent forms)
- [ ] เพิ่ม owner staff + doctor staff + receptionist staff อย่างน้อย 1 ราย (สร้างจาก Supabase Auth → INSERT ลง `staff` ผูก `user_id`)
- [ ] สร้าง 5–10 patients ด้วย HN format ใหม่ (`C-2026-00001` ขึ้นไป) ผ่าน UI หรือ seed
- [ ] สร้าง 1–2 courses + 2–3 appointments เพื่อให้ profile screen มี content จริง
- [ ] ตรวจสอบ deep link messaging (LINE/WhatsApp/โทร) บนอุปกรณ์ที่ใช้เดโม

### Build & Deploy
- [ ] iOS — `flutter build ipa --release --dart-define=ENV=prod --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=SENTRY_DSN=... --export-options-plist=ios/ExportOptions.plist`
- [ ] Verify code signing (DEVELOPMENT_TEAM = `H43SK9D7D3`) ตรงกับ Apple Developer account ของลูกค้า
- [ ] Install บน iPad ของลูกค้า → smoke test ทำ workflow หลัก (patient → appointment → treatment → financial)
- [ ] Push `--dart-define=ENV=prod` แทน `dev` ก่อน build production

### เอกสาร
- [x] `docs/DEMO_WALKTHROUGH.md` — script เดโมหน้าจอต่อหน้าจอ
- [x] `docs/FEATURE_MATRIX.md` — matrix ของฟีเจอร์ทั้งหมด
- [x] `docs/CLIENT_HANDOFF.md` (ไฟล์นี้)
- [ ] บันทึก SUPABASE_URL + ANON_KEY + DSN (ถ้ามี) ที่ใช้จริงไว้ใน 1Password หรือ secret manager ของลูกค้า

### Smoke test ที่แนะนำให้ทำก่อนเริ่ม demo
1. Login ด้วย staff owner
2. สร้าง patient ใหม่ → ดูว่า HN format = `C-2026-XXXXX` (ปีปัจจุบัน)
3. สร้าง appointment ให้ patient นั้น
4. เปิด appointment → กด "Save Treatment" → ใส่ products used (ที่มี stock) → save
5. ตรวจ patient profile screen → ต้องเห็น treatment + outstanding ทันที (single-call bundle)
6. ตรวจ inventory → stock ของ product ที่ใช้ถูกตัดเป๊ะ
7. ลอง save treatment ที่ใช้ product เกิน stock → ต้อง toast InsufficientStockException + ไม่สร้าง partial row
8. Logout → switch เป็น receptionist → confirm settings page ไม่เปิดได้

## กรอบการยอมรับงาน

สำหรับบรีฟปัจจุบัน ระบบควรถูกนำเสนอว่าอยู่ในสถานะ:

- พร้อมสำหรับ stakeholder demo
- พร้อมสำหรับ client review
- พร้อมสำหรับ structured QA และ pilot feedback

อย่างไรก็ตาม ยังไม่ควรวาง positioning ว่าเป็น enterprise inventory platform แบบขยายเต็มรูปแบบ เพราะฟีเจอร์ใน phase ถัดไปถูกแยกออกจากขอบเขตการส่งมอบปัจจุบันอย่างตั้งใจแล้ว
