# กัน Supabase ไม่ให้ Pause (ฟรี)

Supabase Free tier จะ **pause หลังไม่มี API activity 7 วัน** → DNS หยุด resolve → แอป login ไม่ได้
("SocketException: Failed host lookup"). วิธีกันคือ ping endpoint สม่ำเสมอ

## วิธีหลัก: cron-job.org (แนะนำ — เสถียรสุด ฟรี)

External cron เสถียรกว่า GitHub Actions มาก (GitHub มักดีเลย์/ข้าม scheduled run)

### ขั้นตอน (ทำครั้งเดียว ~5 นาที)

1. สมัคร/login ที่ **https://cron-job.org** (ฟรี)
2. กด **Create cronjob**
3. ตั้งค่าดังนี้:

   | ช่อง | ค่า |
   |------|-----|
   | **Title** | `airaMD Supabase keep-alive` |
   | **URL** | `https://pzqjqqaekxmfdlrxbgmk.supabase.co/auth/v1/settings` |
   | **Schedule** | Every 6 hours (หรือ "Every 8 hours" ก็พอ) |

4. เปิดหัวข้อ **Advanced / Headers** → Add request header:

   | Key | Value |
   |-----|-------|
   | `apikey` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6cWpxcWFla3htZmRscnhiZ21rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyOTUzNTAsImV4cCI6MjA4OTg3MTM1MH0.-1GEjKobBky0psImnCkhBZcaFzO3RQZ4gDyQV0MOUeM` |

5. **Save** → กด **Run now** ทดสอบ → ต้องได้ **HTTP 200**
6. ( option) เปิด **Notifications** ให้ส่งอีเมลเตือนเมื่อ job fail → รู้ทันทีถ้า project มีปัญหา

เสร็จแล้ว — cron-job.org จะ ping ทุก 6 ชม. timer 7 วันจะไม่มีทางถึง project ไม่ pause อีก

## วิธีสำรอง: GitHub Actions (มีอยู่แล้ว)

ไฟล์ `.github/workflows/keep-alive.yml` ping ทุก 6 ชม. แต่ต้องตั้ง **Actions secrets** ก่อนถึงจะทำงาน:

1. ไปที่ `https://github.com/faztycoding/airaMD/settings/secrets/actions`
2. กด **New repository secret** เพิ่ม 2 ตัว:
   - `SUPABASE_URL` = `https://pzqjqqaekxmfdlrxbgmk.supabase.co`
   - `SUPABASE_ANON_KEY` = (anon key ด้านบน)
3. ไปแท็บ **Actions** → เปิด workflow **Supabase Keep-Alive** → กด **Run workflow** ทดสอบ → ต้องเขียว

> ⚠️ ข้อจำกัด GitHub: scheduled workflow จะถูก **auto-disable หลัง 60 วันที่ repo ไม่มี commit** —
> นี่คือเหตุผลที่ใช้ cron-job.org เป็นตัวหลัก

## เช็กว่ายัง awake อยู่ไหม (รันบนเครื่องได้)

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  -H "apikey: <ANON_KEY>" \
  https://pzqjqqaekxmfdlrxbgmk.supabase.co/auth/v1/settings
# 200 = awake, 000 = paused/unreachable
```

## ทางที่ดีที่สุดระยะยาว

ระบบนี้เก็บข้อมูลคนไข้จริง — ถ้างบไหว **Supabase Pro ($25/เดือน)** คุ้มกว่า:
ไม่ pause เลย + daily backup 7 วัน + ไม่ต้องพึ่ง keep-alive hack
