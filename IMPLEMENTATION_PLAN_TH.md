# airaMD — แอปจัดการคลินิก
## แผนการพัฒนาฉบับสมบูรณ์

**ชื่อแอป:** airaMD  
**แพลตฟอร์ม:** Flutter (iPad/Tablet เป็นหลัก, มือถือรอง)  
**แบ็กเอนด์:** Supabase (Auth + PostgreSQL + Storage + Edge Functions)  
**งบประมาณ:** ฿30,000  
**ระยะเวลา:** 6–8 สัปดาห์  
**ธีมการออกแบบ:** โทนสีเบจ/น้ำตาลอบอุ่น หรูหรา (อ้างอิง: Smart Home App UI — ดูรูปที่ 1)  
**ภาษา:** ไทย (หลัก) / อังกฤษ  
**การส่งมอบ:** ซอร์สโค้ดทั้งหมด + โอนกรรมสิทธิ์บัญชีทั้งหมดให้ลูกค้า  

---

## สารบัญ

1. [ภาพรวมโปรเจกต์](#1-ภาพรวมโปรเจกต์)
2. [ระบบดีไซน์และธีม](#2-ระบบดีไซน์และธีม)
3. [โครงสร้างฐานข้อมูล (Supabase)](#3-โครงสร้างฐานข้อมูล-supabase)
4. [เฟส 1 — Digital Clinic](#4-เฟส-1--digital-clinic)
5. [เฟส 2 — Business Logic](#5-เฟส-2--business-logic)
6. [เฟส 3 — Smart System](#6-เฟส-3--smart-system)
7. [ส่วนที่ใช้ร่วมกันทั้งระบบ](#7-ส่วนที่ใช้ร่วมกันทั้งระบบ)
8. [โครงสร้างโปรเจกต์ Flutter](#8-โครงสร้างโปรเจกต์-flutter)
9. [แพ็กเกจที่ใช้](#9-แพ็กเกจที่ใช้)
10. [เช็คลิสต์การส่งมอบตาม Milestone](#10-เช็คลิสต์การส่งมอบตาม-milestone)

---

## 1. ภาพรวมโปรเจกต์

airaMD คือแอปจัดการคลินิกสำหรับคลินิกเสริมความงามขนาดเล็ก คุณหมอ (ลูกค้า) มีพนักงาน 2 คน และวางแผนใช้แอปภายในคลินิกบน iPad/Tablet ในอนาคตอาจขึ้น App Store/Play Store และขยายเป็นระบบหลายคลินิก (SaaS)

### ผู้มีส่วนเกี่ยวข้อง
- **แพทย์ (เจ้าของ):** เข้าถึงข้อมูลทั้งหมด, ตั้งค่า, และหน้าแอดมิน
- **พนักงาน (อนาคต):** เข้าถึงได้จำกัดตามสิทธิ์บทบาท

### โมดูลหลัก
1. จัดการผู้ป่วย (EMR ครบวงจร)
2. ระบบนัดหมายและปฏิทิน (พร้อมจัดตารางเวรแพทย์)
3. บันทึกการรักษา (SOAP notes — แบบไหลลื่น ไม่ใช่ช่องตาราง)
4. วาดไดอะแกรมบนใบหน้า (ใช้นิ้ว/สไตลัสวาดบนรูปใบหน้าผู้ป่วย)
5. เปรียบเทียบรูป Before/After (ซูม/แพนพร้อมกัน, แสดง 4 ช่อง)
6. ใบยินยอม + ลายเซ็นดิจิทัล
7. ระบบคอร์ส (ซื้อ X แถม Y, ติดตามครั้ง, วันหมดอายุ)
8. ระบบการเงิน (ยอดสะสม, ค้างชำระ, ประวัติการจ่ายเงิน)
9. จัดการราคา (ราคาเริ่มต้นแก้ไขได้ต่อสินค้า/บริการ)
10. ควบคุมสต็อก (แปลงหน่วย, หักสต็อกทศนิยม, วันหมดอายุ)
11. ระบบเตือนก่อนทำหัตถการ (เช็คระยะห่าง, ข้อห้าม, ยาที่แพ้)
12. ส่งข้อความ LINE / WhatsApp (เทมเพลต: นัดหมาย, ดูแลหลังทำ, โปรโมชัน)
13. Push Notifications (แจ้งเตือนนัดหมาย)
14. ความปลอดภัย (ล็อก PIN, สแกนนิ้ว/หน้า, สิทธิ์ตามบทบาท)
15. กระดาษโน้ตดิจิทัล (หน้าว่างสำหรับเขียน/วาดอิสระ)
16. สถานะซิงค์ออฟไลน์
17. หน้านโยบายความเป็นส่วนตัว (ตาม PDPA)
18. รองรับหลายภาษา (ไทย/อังกฤษ)

---

## 2. ระบบดีไซน์และธีม

### ชุดสี (อ้างอิงรูปที่ 1 — ธีมอบอุ่น/หรูหรา Smart Home UI)
```
สีหลักเข้ม:       #6B4F3A (wood-dk)
สีหลักกลาง:      #8B6650 (wood-mid)
สีหลักอ่อน:       #B8957A (wood-lt)
สีหลักซีด:        #D4B89A (wood-pale)
สีหลักจาง:        #EDD9C4 (wood-wash)
พื้นหลัง:          #F7F0E8 (cream)
พื้นหลังเข้ม:      #EDE4D8 (cream-dk)
พื้นผิว:           #FAF5EE (parchment)
การ์ด:             #FFFCF8 (white)
ตัวอักษรหลัก:      #2D1F14 (charcoal)
ตัวอักษรรอง:       #9A7D6A (muted)
สีเน้นเขียว:       #7A9070 (sage)
สีเน้นแดง:         #B86848 (terra)
สีเน้นทอง:         #C4922A (gold)
```

### ตัวอักษร (Typography)
- **หัวข้อ:** Cormorant Garamond (เซอริฟ, สง่างาม)
- **เนื้อหา/UI:** DM Sans (สะอาด, ทันสมัย)
- **ขนาดตัวอักษร:** ปรับตามขนาดจอ iPad (ปุ่มใหญ่สำหรับสัมผัส, อ่านง่ายในระยะแขน)

### หลักการออกแบบ UI
- **เลย์เอาต์แบบการ์ด** มีมุมโค้งใหญ่ (border-radius 18–24px)
- **เงาแบบ Glassmorphism-lite:** `0 4px 20px rgba(107,79,58,0.10)`
- **แอนิเมชันนุ่มนวล** (fade-up ตอนเปลี่ยนหน้า, scale ตอนกดการ์ด)
- **ปรับแต่งสำหรับ iPad** เป้าหมายสัมผัสขั้นต่ำ 44×44pt
- **แถบนำทางด้านล่าง** 4 แท็บ: แดชบอร์ด, ผู้ป่วย, ปฏิทิน, ตั้งค่า
- **หน้าโปรไฟล์** เลื่อนเข้าจากขวา (เต็มจอ)
- **ฟอร์ม SOAP แบบไหลลื่น** — ไม่ใช่ช่องตาราง แต่เป็นส่วน input ไหลต่อเนื่องพร้อมหัวข้อแบ่งส่วน

### ระบบ Layout Grid (อ้างอิงรูปที่ 1 — Smart Home App)

#### กริดหลัก
- **ประเภทกริด:** 12 คอลัมน์ responsive (iPad แนวนอน)
- **Gutter (ช่องว่างระหว่างคอลัมน์):** 16px
- **Margin (ขอบซ้าย-ขวา):** 24px
- **Content max-width:** 1140px (กึ่งกลางจอถ้าจอใหญ่กว่า)

#### Breakpoints (จุดเปลี่ยนเลย์เอาต์)
| อุปกรณ์ | ขนาด | กริด | หมายเหตุ |
|---------|------|------|---------|
| iPad แนวนอน | 1194×834 | 12 คอลัมน์ | เลย์เอาต์หลัก |
| iPad แนวตั้ง | 834×1194 | 8 คอลัมน์ | ซ้อนเลย์เอาต์ |
| มือถือ | <600px | 1 คอลัมน์ | ซ้อนเดียว (fallback) |

#### เลย์เอาต์ต่อหน้า
- **แดชบอร์ด:**
  - ซ้าย (4 คอลัมน์): การ์ดสถิติซ้อนแนวตั้ง + ปุ่มลัด
  - ขวา (8 คอลัมน์): รายการนัดหมายวันนี้ / เนื้อหาหลัก
- **โปรไฟล์ผู้ป่วย:**
  - Overlay เต็มจอ (เลื่อนเข้าจากขวา)
  - ส่วนหัว: ยึดด้านบน (รูป + ชื่อ + ปุ่มกด)
  - แท็บ: เลื่อนแนวนอนใต้ส่วนหัว
  - เนื้อหา: เลื่อนได้ padding ส่วน 20px
- **ปฏิทิน:**
  - แผงซ้าย (5 คอลัมน์): กริดปฏิทินรายเดือน
  - แผงขวา (7 คอลัมน์): รายละเอียดวัน / รายการนัดหมาย + ตารางเวร
- **ฟอร์มบันทึกการรักษา:**
  - ฟอร์มคอลัมน์เดียว (max-width 720px, กึ่งกลาง)
  - หัวข้อส่วนพร้อมเส้นแบ่ง
  - เลือกสินค้า: overlay bottom sheet (กริดสินค้าเต็มความกว้าง)
- **เปรียบเทียบรูป (แนวนอน):**
  - 4 คอลัมน์เท่ากัน แต่ละช่องมีรูป 1 รูป
  - สัดส่วนภาพ: 3:4 ต่อช่อง
  - แถบป้ายกำกับใต้แต่ละรูป (วันที่ + ประเภท)
- **ตั้งค่า:**
  - แถบด้านซ้าย (3 คอลัมน์): เมนูนำทาง
  - เนื้อหาขวา (9 คอลัมน์): ฟอร์มตั้งค่า
- **คอร์ส (ตารางภาพรวม):**
  - ตารางเต็มความกว้าง 12 คอลัมน์
  - แถวส่วนหัวยึดด้านบน (sticky header)
  - กรอง/ค้นหาด้านบนตาราง

#### ระยะห่างและขนาดมาตรฐาน
```
Section padding:        20px
Card padding:           16–20px
Card border-radius:     18–24px
Card gap (ระยะห่างการ์ด): 16px
Button height:          48–56px (iPad touch target)
Input height:           48px
Tab height:             44px
Bottom nav height:      72px
App bar height:         64px
FAB size:               56px
Icon size (nav):        24px
Icon size (action):     20px
Avatar size (list):     48px
Avatar size (profile):  80px
```

### คอมโพเนนต์ UI หลักที่ต้องสร้าง
- `airaMDCard` — การ์ดมุมโค้งพร้อมเงา
- `airaMDButton` — ปุ่มหลักไล่สี gradient
- `airaMDBadge` — แบดจ์สถานะ (ใหม่, ยืนยัน, ติดตามผล, VIP, ⭐⭐⭐)
- `airaMDTextField` — ช่องกรอกข้อมูลธีมอบอุ่น
- `airaMDBottomNav` — แถบนำทาง 4 แท็บ
- `airaMDProfileTabs` — แท็บเลื่อนแนวนอนในโปรไฟล์ผู้ป่วย
- `airaMDChip` — ชิปเลือกได้ (ช่วงเวลา, ผลข้างเคียง ฯลฯ)
- `airaMDProgressBar` — แถบความคืบหน้าคอร์สไล่สี gradient

---

## 3. โครงสร้างฐานข้อมูล (Supabase)

### กฎสำคัญ
> ทุกตาราง **ต้องมี** `clinic_id UUID` เพื่อรองรับระบบหลายคลินิก (Multi-tenant SaaS) ในอนาคต

### 3.1 ตาราง: `clinics` (คลินิก)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| name | TEXT NOT NULL | ชื่อคลินิก |
| logo_url | TEXT | โลโก้ |
| address | TEXT | ที่อยู่ |
| phone | TEXT | เบอร์โทร |
| line_oa_id | TEXT | LINE Official Account ID |
| settings | JSONB | ตั้งค่าทั่วไปของแอป |
| created_at | TIMESTAMPTZ | วันที่สร้าง |
| updated_at | TIMESTAMPTZ | วันที่แก้ไขล่าสุด |

### 3.2 ตาราง: `staff` (แพทย์และพนักงาน)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK → clinics | หลายคลินิก |
| user_id | UUID FK → auth.users | Supabase Auth |
| full_name | TEXT NOT NULL | ชื่อ-นามสกุล |
| nickname | TEXT | ชื่อเล่น |
| role | ENUM | `OWNER`, `DOCTOR`, `RECEPTIONIST` |
| base_salary | DECIMAL(12,2) | อนาคต: ระบบเงินเดือน |
| is_active | BOOLEAN DEFAULT true | สถานะทำงาน |
| pin_hash | TEXT | PIN ล็อก |
| avatar_url | TEXT | รูปโปรไฟล์ |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.3 ตาราง: `staff_schedules` (ตารางเวร)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| staff_id | UUID FK → staff | |
| date | DATE NOT NULL | วันที่ |
| status | ENUM | `ON_DUTY` (เข้าเวร), `LEAVE` (ลา), `HALF_DAY` (ครึ่งวัน) |
| start_time | TIME | เวลาเริ่ม |
| end_time | TIME | เวลาเลิก |
| note | TEXT | หมายเหตุ |
| created_at | TIMESTAMPTZ | |

### 3.4 ตาราง: `patients` (ผู้ป่วย)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | หลายคลินิก |
| hn | TEXT UNIQUE | เลข HN (สร้างอัตโนมัติ) |
| first_name | TEXT NOT NULL | ชื่อ |
| last_name | TEXT NOT NULL | นามสกุล |
| nickname | TEXT | ชื่อเล่น |
| date_of_birth | DATE | วันเกิด |
| gender | ENUM | `M` (ชาย), `F` (หญิง), `OTHER` (อื่นๆ) |
| national_id | TEXT | เลขบัตรประชาชน (เข้ารหัส) |
| passport_no | TEXT | หนังสือเดินทาง |
| phone | TEXT | เบอร์โทร |
| line_id | TEXT | LINE ID |
| whatsapp | TEXT | เบอร์ WhatsApp |
| email | TEXT | อีเมล |
| address | TEXT | ที่อยู่ |
| status | ENUM | `NORMAL`, `VIP`, `STAR` |
| drug_allergies | TEXT[] | รายชื่อยาที่แพ้ |
| allergy_symptoms | TEXT | อาการแพ้ |
| medical_conditions | TEXT[] | โรคประจำตัว |
| smoking | ENUM | `NONE` (ไม่สูบ), `OCCASIONAL` (นานๆ ครั้ง), `REGULAR` (ประจำ) |
| alcohol | ENUM | `NONE`, `OCCASIONAL`, `REGULAR` |
| is_using_retinoids | BOOLEAN | ใช้ Retinoids อยู่หรือไม่ |
| is_on_anticoagulant | BOOLEAN | ใช้ยาต้านการแข็งตัวของเลือดอยู่หรือไม่ |
| preferred_channel | ENUM | `LINE`, `WHATSAPP`, `BOTH`, `NONE` |
| profile_photo_url | TEXT | รูปโปรไฟล์ |
| notes | TEXT | หมายเหตุทั่วไป |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.5 ตาราง: `appointments` (นัดหมาย)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| doctor_id | UUID FK → staff | กำหนดอัตโนมัติจากตารางเวร |
| date | DATE NOT NULL | วันที่นัด |
| start_time | TIME NOT NULL | เวลาเริ่ม |
| end_time | TIME | เวลาสิ้นสุด |
| status | ENUM | `NEW` (ใหม่), `CONFIRMED` (ยืนยัน), `FOLLOW_UP` (ติดตามผล), `COMPLETED` (เสร็จ), `CANCELLED` (ยกเลิก), `NO_SHOW` (ไม่มา) |
| treatment_type | TEXT | ประเภทหัตถการ |
| notes | TEXT | หมายเหตุ |
| reminder_sent | BOOLEAN | ส่งแจ้งเตือนแล้วหรือยัง |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.6 ตาราง: `services` (บริการ/หัตถการ — ราคา)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| name | TEXT NOT NULL | ชื่อบริการ |
| category | ENUM | `HA`, `INJECTABLE`, `LASER`, `TREATMENT`, `OTHER` |
| default_price | DECIMAL(12,2) | ราคาเริ่มต้น |
| doctor_fee_type | ENUM | `FIXED_AMOUNT`, `PERCENTAGE`, `NONE` |
| doctor_fee_value | DECIMAL(12,2) | อนาคต: ค่าคอมมิชชัน |
| estimated_cost | DECIMAL(12,2) | อนาคต: คำนวณกำไรขั้นต้น (GP) |
| is_active | BOOLEAN | เปิดใช้งาน |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.7 ตาราง: `treatment_records` (บันทึกการรักษา)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| doctor_id | UUID FK → staff | อัตโนมัติจากตารางเวร |
| appointment_id | UUID FK → appointments | เชื่อมนัดหมาย (ไม่บังคับ) |
| date | TIMESTAMPTZ NOT NULL | วันที่รักษา |
| category | ENUM | `INJECTABLE`, `LASER`, `TREATMENT`, `OTHER` |
| treatment_name | TEXT NOT NULL | ชื่อหัตถการ |
| chief_complaint | TEXT | SOAP: อาการสำคัญ |
| objective | TEXT | SOAP: ตรวจร่างกาย |
| assessment | TEXT | SOAP: การวินิจฉัย |
| plan | TEXT | SOAP: แผนการรักษา |
| vitals | JSONB | `{temp, pulse, bp_sys, bp_dia, spo2, pain_score}` |
| device | TEXT | ชื่อเครื่องเลเซอร์/อุปกรณ์ |
| energy | TEXT | เช่น "0.8J" |
| pulse_spot | TEXT | เช่น "7mm spot" |
| total_shots | TEXT | เช่น "600 shots" |
| products_used | JSONB | `[{product_id, name, dose, unit}]` |
| actual_units_used | DECIMAL(10,4) | สำหรับหักสต็อก |
| response_to_previous | ENUM | `IMPROVED`, `STABLE`, `WORSE`, `N_A` |
| adverse_events | TEXT[] | เช่น `['ผิวแดง', 'บวม']` |
| instructions | TEXT[] | คำแนะนำหลังทำ |
| follow_up_date | DATE | วันนัดติดตามผล |
| follow_up_time | TIME | เวลานัดติดตามผล |
| diagram_url | TEXT | รูปไดอะแกรมใบหน้า |
| notes | TEXT | หมายเหตุอิสระ |
| commission_status | ENUM | `PENDING`, `PAID` — อนาคต |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.8 ตาราง: `patient_photos` (รูปผู้ป่วย)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | รองรับหลายคลินิก |
| patient_id | UUID FK → patients | |
| treatment_record_id | UUID FK | เชื่อมบันทึกการรักษา (ไม่บังคับ) |
| image_type | ENUM | `BEFORE` (ก่อน), `AFTER_1M` (หลัง 1 เดือน), `AFTER_3M`, `AFTER_6M`, `FOLLOW_UP`, `OTHER` |
| storage_path | TEXT NOT NULL | พาธไฟล์ใน Supabase Storage |
| thumbnail_path | TEXT | รูปย่อ (downsampled) |
| treatment_date | DATE | วันที่รักษา |
| description | TEXT | คำอธิบาย |
| sort_order | INT DEFAULT 0 | ลำดับการจัดเรียง |
| created_at | TIMESTAMPTZ | |

### 3.9 ตาราง: `face_diagrams` (ไดอะแกรมบนใบหน้า)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| treatment_record_id | UUID FK | เชื่อมบันทึกการรักษา (ไม่บังคับ) |
| image_url | TEXT NOT NULL | รูป canvas ที่บันทึกเป็น PNG |
| view_type | ENUM | `FRONT` (ด้านหน้า), `SIDE` (ด้านข้าง), `LIP_ZONE` (โซนปาก) |
| strokes_data | JSONB | ข้อมูลเส้นวาดดิบ (สำหรับแก้ไขซ้ำ) |
| markers_data | JSONB | ข้อมูลหมุด/ป้ายกำกับ (เช่น "20U", "1ml") |
| created_at | TIMESTAMPTZ | |

### 3.10 ตาราง: `consent_forms` (ใบยินยอมที่ลงนามแล้ว)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| treatment_record_id | UUID FK | |
| form_template_id | UUID FK | เชื่อมเทมเพลต |
| signature_url | TEXT NOT NULL | รูปลายเซ็นดิจิทัล |
| signed_at | TIMESTAMPTZ NOT NULL | วันเวลาที่ลงนาม |
| witness_name | TEXT | ชื่อพยาน |
| pdf_url | TEXT | ไฟล์ PDF ที่สร้างขึ้น |
| created_at | TIMESTAMPTZ | |

### 3.11 ตาราง: `consent_form_templates` (แม่แบบใบยินยอม)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| name | TEXT NOT NULL | เช่น "ใบยินยอม Filler" |
| category | TEXT | หมวดหัตถการ |
| content | TEXT NOT NULL | เนื้อหาแม่แบบ |
| is_active | BOOLEAN DEFAULT true | เปิดใช้งาน |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.12 ตาราง: `products` (สินค้า/คลังยา)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| name | TEXT NOT NULL | ชื่อสินค้า |
| brand | TEXT | ยี่ห้อ |
| category | ENUM | `BOTOX`, `FILLER`, `BIOSTIMULATOR`, `POLYNUCLEOTIDE`, `SKINBOOSTER`, `LASER`, `OTHER` |
| unit | TEXT NOT NULL | `U`, `cc`, `ml`, `syringe`, `vial`, `shots`, `ครั้ง`, `mg`, `g` |
| unit_cost | DECIMAL(12,2) | อนาคต: ต้นทุนต่อหน่วย |
| default_price | DECIMAL(12,2) | ราคาเริ่มต้น |
| stock_quantity | DECIMAL(12,4) | สต็อกทศนิยม (เช่น เหลือ 30 Units) |
| stock_per_container | DECIMAL(12,4) | เช่น 50 Units ต่อ vial |
| min_stock_alert | INT | เกณฑ์แจ้งเตือนสต็อกต่ำ |
| expiry_date | DATE | วันหมดอายุ |
| is_active | BOOLEAN DEFAULT true | เปิดใช้งาน |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.13 ตาราง: `inventory_transactions` (ธุรกรรมสต็อก)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| product_id | UUID FK → products | |
| treatment_record_id | UUID FK | ใช้ในการรักษาไหน |
| patient_id | UUID FK | ใช้กับผู้ป่วยคนไหน |
| transaction_type | ENUM | `STOCK_IN` (รับเข้า), `USED` (ใช้), `WASTAGE` (สูญเสีย), `ADJUSTMENT` (ปรับปรุง) |
| quantity | DECIMAL(12,4) | บวกสำหรับรับเข้า, ลบสำหรับใช้ |
| unit | TEXT | หน่วย |
| batch_no | TEXT | เลข batch |
| expiry_date | DATE | วันหมดอายุระดับ batch |
| notes | TEXT | หมายเหตุ |
| created_by | UUID FK → staff | ผู้บันทึก |
| created_at | TIMESTAMPTZ | |

### 3.14 ตาราง: `courses` (คอร์ส)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| name | TEXT NOT NULL | ชื่อคอร์ส |
| service_id | UUID FK → services | เชื่อมบริการ (ไม่บังคับ) |
| price | DECIMAL(12,2) | ราคาคอร์ส |
| sessions_bought | INT NOT NULL | จำนวนครั้งที่ซื้อ |
| sessions_bonus | INT DEFAULT 0 | จำนวนครั้งแถม (สีทอง) |
| sessions_total | INT GENERATED | ซื้อ + แถม |
| sessions_used | INT DEFAULT 0 | จำนวนครั้งที่ใช้แล้ว |
| status | ENUM | `ACTIVE` (ใช้งาน), `LOW` (เหลือน้อย), `COMPLETED` (ครบ), `EXPIRED` (หมดอายุ) |
| expiry_date | DATE | วันหมดอายุ |
| notes | TEXT | หมายเหตุ |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 3.15 ตาราง: `course_sessions` (ครั้งของคอร์ส)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| course_id | UUID FK → courses | |
| session_number | INT NOT NULL | ครั้งที่ |
| is_bonus | BOOLEAN DEFAULT false | เป็นครั้งแถม (สีทอง) |
| is_used | BOOLEAN DEFAULT false | ใช้แล้วหรือยัง |
| used_date | DATE | วันที่ใช้ |
| treatment_record_id | UUID FK | เชื่อมบันทึกการรักษา |
| created_at | TIMESTAMPTZ | |

### 3.16 ตาราง: `financial_records` (บันทึกการเงิน)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| treatment_record_id | UUID FK | เชื่อมบันทึกการรักษา (ไม่บังคับ) |
| course_id | UUID FK → courses | เชื่อมคอร์ส (ไม่บังคับ) |
| type | ENUM | `CHARGE` (เรียกเก็บ), `PAYMENT` (ชำระ), `REFUND` (คืนเงิน), `ADJUSTMENT` (ปรับปรุง) |
| amount | DECIMAL(12,2) NOT NULL | จำนวนเงิน |
| payment_method | ENUM | `CASH` (เงินสด), `TRANSFER` (โอน), `CREDIT_CARD`, `DEBIT`, `OTHER` |
| description | TEXT | รายละเอียด |
| is_outstanding | BOOLEAN DEFAULT false | ยังค้างชำระ |
| created_by | UUID FK → staff | ผู้บันทึก |
| created_at | TIMESTAMPTZ | |

### 3.17 ตาราง: `message_logs` (บันทึกข้อความ)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| channel | ENUM | `LINE`, `WHATSAPP` |
| template_type | ENUM | `APPOINTMENT` (นัดหมาย), `CONFIRMATION` (ยืนยัน), `AFTER_CARE` (ดูแลหลังทำ), `PROMOTION` (โปรโมชัน), `CUSTOM` (กำหนดเอง) |
| message_content | TEXT | เนื้อหาข้อความ |
| status | ENUM | `SENT` (ส่งแล้ว), `DELIVERED` (ส่งถึง), `FAILED` (ล้มเหลว), `PENDING` (รอส่ง) |
| sent_by | UUID FK → staff | ผู้ส่ง |
| sent_at | TIMESTAMPTZ | เวลาที่ส่ง |
| created_at | TIMESTAMPTZ | |

### 3.18 ตาราง: `audit_logs` (บันทึกตรวจสอบ)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| user_id | UUID FK → staff | ผู้ดำเนินการ |
| action | TEXT NOT NULL | เช่น 'DELETED_PATIENT_IMAGE', 'EDITED_FINANCIAL_RECORD' |
| entity_type | TEXT | 'patient', 'treatment_record' ฯลฯ |
| entity_id | UUID | |
| old_data | JSONB | ข้อมูลก่อนเปลี่ยน |
| new_data | JSONB | ข้อมูลหลังเปลี่ยน |
| ip_address | TEXT | |
| timestamp | TIMESTAMPTZ DEFAULT now() | |

### 3.19 ตาราง: `digital_notepads` (กระดาษโน้ตดิจิทัล)
| คอลัมน์ | ชนิดข้อมูล | หมายเหตุ |
|---------|-----------|---------|
| id | UUID PK | |
| clinic_id | UUID FK | |
| patient_id | UUID FK → patients | |
| title | TEXT | ชื่อโน้ต |
| canvas_data | JSONB | ข้อมูลวาดดิบ |
| image_url | TEXT | บันทึกเป็น PNG |
| created_by | UUID FK → staff | ผู้สร้าง |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

---

> **ต่อส่วนที่ 2:** เฟส 1–3, โครงสร้างโปรเจกต์, แพ็กเกจ, เช็คลิสต์ → ดูที่ [`IMPLEMENTATION_PLAN_TH_2.md`](IMPLEMENTATION_PLAN_TH_2.md)
