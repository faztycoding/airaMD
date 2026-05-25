# เอกสารส่งมอบให้ลูกค้า — Build 16 (Final)

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

## Round 5 — Audit ครบทุกข้อ (Build 16)

ตรวจสอบครบทั้ง 8 ข้อที่ลูกค้าแจ้ง พบว่าเกือบทุกข้อถูก implement ไว้แล้ว มีแก้ไขเพิ่มเติม 1 จุด:

| ข้อ | รายการ | สถานะ |
|-----|--------|--------|
| 1 | Apple Pencil pressure sensitivity ใน Face Diagram | ✅ แก้ไขใน Build 16 |
| 2 | Camera capture (ไม่ใช่แค่ Gallery) | ✅ มีอยู่แล้ว |
| 3 | เครื่อง + พารามิเตอร์ ใน treatment record | ✅ มีอยู่แล้ว (Build 12) |
| 4 | Doctor name + เลข ว. | ✅ มีอยู่แล้ว |
| 5 | Course price 2 formats (ต่อ session + ต่อ course) | ✅ มีอยู่แล้ว |
| 6 | Tab แนวตั้ง + Dermatology grouping | ✅ มีอยู่แล้ว |
| 7 | Appointment ↔ Treatment record link | ✅ มีอยู่แล้ว |
| 8 | Status field ออกจาก patient header | ✅ มีอยู่แล้ว (Build 12) |

**รายละเอียด item 1:** `_Stroke` เปลี่ยนจาก `List<Offset>` เป็น `List<PointVector>` — ส่ง `event.pressure` จาก Apple Pencil เข้า perfect_freehand โดยตรง เส้นบางเมื่อกดเบา หนาเมื่อกดแรง แผนภาพเก่าที่บันทึกไว้ก่อนหน้านี้ backward-compatible (default pressure = 0.5)

## Checklist ก่อน handoff

### โค้ด
- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 209 tests pass
- [x] Version `1.0.0+16`
- [x] Migrations 008–023 พร้อม apply

### ฐานข้อมูล
- [x] Migrations 008–015 (production hardening + atomic RPCs)
- [x] Migrations 016–020 (treatment templates, machines_used, courses)
- [x] Migrations 021–023 (master catalog seed, lipolytic category, treatment templates)
- [ ] รัน `supabase db push` บน project ของลูกค้าเพื่อ apply migrations ที่ยังค้างอยู่
- [ ] Verify smoke flow: login → save 1 treatment → confirm `treatment_records` + `inventory_transactions` atomic

### Build & Deploy
```bash
# Build IPA release
/path/to/flutter build ipa --release \
  --dart-define=ENV=prod \
  --dart-define=SUPABASE_URL=<URL> \
  --dart-define=SUPABASE_ANON_KEY=<KEY> \
  --export-options-plist=ios/ExportOptions.plist
```
- [ ] DEVELOPMENT_TEAM = `H43SK9D7D3` ตรงกับ Apple Developer account ของลูกค้า
- [ ] Upload ผ่าน Transporter → TestFlight → Install บน iPad

### Smoke test ที่แนะนำ
1. Login owner → สร้าง patient → HN = `C-2026-XXXXX`
2. สร้าง appointment → เปิด → บันทึก treatment (ใส่ products + machines)
3. ตรวจ profile screen → treatment + outstanding ทันที
4. ตรวจ inventory → stock ถูกตัดเป๊ะ
5. วาดใน Face Diagram ด้วย Apple Pencil → เส้นหนาบางตามแรงกด
6. Logout → switch receptionist → settings ไม่เปิดได้

---

## การโอนความเป็นเจ้าของ (Ownership Transfer)

### 1. GitHub Repository

**ตัวเลือก A — Transfer repo ให้ account ของลูกค้า (แนะนำ):**
1. ไปที่ `https://github.com/faztycoding/airaMD/settings`
2. เลื่อนลงมาส่วน **"Danger Zone"** → กด **"Transfer ownership"**
3. ใส่ชื่อ repo `airaMD` เพื่อยืนยัน → ใส่ GitHub username ของลูกค้า
4. ลูกค้าจะได้รับ email ยืนยัน → accept → repo ย้ายไปอยู่ใต้ account ของลูกค้า

**ตัวเลือก B — เพิ่มลูกค้าเป็น Collaborator (ถ้ายังไม่โอน):**
1. ไปที่ `https://github.com/faztycoding/airaMD/settings/access`
2. กด **"Add people"** → ใส่ GitHub username ของลูกค้า → เลือก role **"Admin"**

### 2. Supabase Project

**โอน project ให้ organization ของลูกค้า:**
1. เข้า [supabase.com/dashboard](https://supabase.com/dashboard) → เลือก project `airaMD`
2. ไปที่ **Settings → General → Transfer project**
3. เลือก organization ของลูกค้าเป็นปลายทาง (ลูกค้าต้องมี account Supabase ก่อน)
4. กด **"Transfer"** → ยืนยัน

**ถ้าลูกค้ายังไม่มี Supabase account:**
1. ให้ลูกค้าสมัคร [supabase.com](https://supabase.com) ก่อน
2. ไปที่ **Settings → Team** → invite email ของลูกค้าเป็น **"Owner"**
3. ลูกค้า accept → แล้วค่อย transfer project

**Credentials ที่ต้องส่งให้ลูกค้า (เก็บใน Password Manager):**
- `SUPABASE_URL` — ดูได้จาก Settings → API → Project URL
- `SUPABASE_ANON_KEY` — ดูได้จาก Settings → API → anon/public key
- `Service Role Key` — ดูได้จาก Settings → API → service_role key (ใช้สำหรับ admin tasks เท่านั้น)
- อีเมล + รหัสผ่าน Supabase dashboard ของ project นี้

### 3. Apple Developer Account

ถ้า bundle ID `com.airamd.app` อยู่ใน Apple Developer account ของทีมพัฒนา:
1. เพิ่ม Apple ID ของลูกค้าเป็น **Account Holder** หรือ **Admin** ที่ developer.apple.com
2. หรือสร้าง Certificate + Provisioning Profile ใหม่ภายใต้ account ของลูกค้า แล้ว rebuild IPA

---

## เอกสาร
- [x] `docs/DEMO_WALKTHROUGH.md`
- [x] `docs/FEATURE_MATRIX.md`
- [x] `docs/CLIENT_HANDOFF.md` (ไฟล์นี้)

## กรอบการยอมรับงาน

ระบบอยู่ในสถานะ **พร้อม production** สำหรับคลินิกขนาดเล็ก-กลาง:

- พร้อม deploy และใช้งานจริง
- ครบทุกข้อ feedback ที่ลูกค้าแจ้ง
- RBAC, audit log, atomic transactions พร้อม

สิ่งที่ต่อยอดได้ในอนาคต (ไม่ใช่ blocker): lot-based stock deduction, supplier workflow, LINE bot integration, advanced analytics
