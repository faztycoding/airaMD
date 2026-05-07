---
description: Run the final client demo and handoff workflow for airaMD
---

ขั้นตอนการเตรียม + ส่งมอบ airaMD ให้ลูกค้า ใช้คำสั่งนี้ก่อน demo ทุกครั้ง

## ขั้นตอน

### 1. ตรวจสุขภาพ codebase
// turbo
1. Run `flutter analyze` ใน `airamd_app/` — ต้อง 0 issues
// turbo
2. Run `flutter test` ใน `airamd_app/` — ทุก test ต้อง pass

### 3. ตรวจฐานข้อมูล Supabase
3. เปิด Supabase Studio → SQL editor
4. Paste และรัน `supabase/verify_migrations.sql`
5. ตรวจทุก SELECT คืนค่าตาม "Expected" ที่ระบุใน comment
   - ถ้าฟังก์ชัน / index / trigger ใดขาดหาย → รัน `supabase db push` หรือ paste migration นั้นซ้ำ
   - Migrations ทั้งหมด idempotent ปลอดภัย

### 6. Seed/verify demo data
6. ตรวจว่ามีอย่างน้อย:
   - 1 clinic (`Beauty Glow Clinic`)
   - 3 staff (owner + doctor + receptionist) ผูกกับ Supabase Auth user
   - 5–10 patients ที่ HN ขึ้นต้น `C-2026-`
   - 1–2 active courses
   - 2–3 future appointments

### 7. Build production IPA
7. Run:
```bash
flutter build ipa --release \
  --dart-define=ENV=prod \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=SENTRY_DSN=<dsn-or-empty> \
  --export-options-plist=ios/ExportOptions.plist
```
8. ติดตั้ง IPA ลงบน iPad ของลูกค้า
9. ทดสอบ smoke flow ตาม "Smoke test" ใน `docs/CLIENT_HANDOFF.md` (8 ขั้น)

### 10. Final review
10. ทบทวน `docs/DEMO_WALKTHROUGH.md` — script ที่จะใช้พรีเซ้นต์
11. ทบทวน `docs/FEATURE_MATRIX.md` — เผื่อโดนลูกค้าถามฟีเจอร์
12. Print/ PDF `docs/CLIENT_HANDOFF.md` ถ้าลูกค้าอยากเก็บ
13. บันทึก env vars (SUPABASE_URL/KEY/DSN) ลง 1Password / secret manager ของลูกค้า

### 14. หลังส่งมอบ
14. Tag git release: `git tag -a v1.0.0-handoff -m "Client handoff"`
15. Push tag: `git push origin v1.0.0-handoff`
16. Update `progress.txt` (ถ้ามี) สรุปสิ่งที่ส่ง
