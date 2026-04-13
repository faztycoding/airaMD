# ตารางสรุปฟีเจอร์

## ขอบเขตการส่งมอบปัจจุบัน

| หมวด | ความสามารถ | สถานะ | หมายเหตุ |
| --- | --- | --- | --- |
| การจัดการผู้รับบริการ | สร้าง / แก้ไขผู้รับบริการพร้อม validation ที่เข้มขึ้น | พร้อมใช้ | มีการตรวจสอบเบอร์โทรและเลขบัตร/Passport |
| โปรไฟล์ผู้รับบริการ | โปรไฟล์ผู้รับบริการแบบหลายแท็บ | พร้อมใช้ | ส่วน clinical และ financial แสดงตามสิทธิ์ |
| การจัดการนัดหมาย | สร้าง / แก้ไขนัดหมาย | พร้อมใช้ | รองรับการ assign แพทย์ |
| Appointment Ownership | แพทย์ผู้รับผิดชอบในนัดหมาย | พร้อมใช้ | มองเห็นได้บนปฏิทินและเชื่อมต่อไปยัง treatment |
| บันทึกการรักษา | ฟอร์มการรักษาแบบ SOAP | พร้อมใช้ | มีการเลือกแพทย์ safety check และแผน follow-up |
| Appointment-to-Treatment Link | เปิด treatment จาก appointment | พร้อมใช้ | ส่ง appointment ID เข้า route ของ treatment |
| Completion Loop | appointment เปลี่ยนเป็น completed หลังบันทึก treatment | พร้อมใช้ | มีการ invalidate provider เพื่อ refresh หน้าจอ |
| การส่งข้อความ | บันทึก log และเริ่มต้น LINE / WhatsApp / โทรออก | พร้อมใช้ | UI รู้บริบทตามช่องทางติดต่อและมี guard |
| การเงิน | บันทึกรับชำระและรายการค้างชำระ | พร้อมใช้ | จำกัดการเข้าถึงตามสิทธิ์ |
| Product Library | ตั้งค่าราคาและสต็อกของสินค้า/บริการ | พร้อมใช้ | รองรับการแก้ไขราคาเริ่มต้นและข้อมูลสต็อก |
| Inventory | รับเข้า / เบิกใช้ / สูญเสีย / ปรับยอด | พร้อมใช้ | ป้องกันสต็อกติดลบ มี batch chips และ expiry visibility |
| การใช้สต็อกแบบทศนิยม | รองรับจำนวนแบบ decimal | พร้อมใช้ | ใช้ได้ทั้งตอนตัดสต็อกจาก treatment และ inventory entry |
| Consent | การเก็บใบยินยอมแบบดิจิทัล | พร้อมใช้ | route ด้าน clinical ถูกป้องกันด้วยสิทธิ์ |
| Digital Notepad | กระดานบันทึก clinical note | พร้อมใช้ | route ด้าน clinical ถูกป้องกันด้วยสิทธิ์ |
| Settings Readiness | หน้า settings ที่ใช้ข้อมูลพนักงานจริงและคัดเมนูที่พร้อมใช้ | พร้อมใช้ | ลบ placeholder ของ cloud item แล้ว |
| Auditability | audit log ครอบคลุม flow หลัก | พร้อมใช้ | appointment, patient, treatment, inventory ดีขึ้นชัดเจน |

## ตารางสิทธิ์การมองเห็นตามบทบาท

| หมวด | Owner | Doctor | Reception / สิทธิ์จำกัด |
| --- | --- | --- | --- |
| รายชื่อผู้รับบริการ | เต็มรูปแบบ | ดูข้อมูล / ใช้งาน clinical ตาม policy | action ถูกจำกัด |
| สร้าง / แก้ไขผู้รับบริการ | ได้ | ได้ | ไม่ได้ |
| ลบผู้รับบริการ | ได้ | ไม่ได้ | ไม่ได้ |
| แท็บด้าน Clinical | ได้ | ได้ | ไม่ได้ |
| หน้าการเงิน | ได้ | ได้ | ไม่ได้ |
| Settings | ได้ | ได้ | ไม่ได้ |
| Route ของ Consent / Notepad / Diagram | ได้ | ได้ | ไม่ได้ |
| จุดเข้าใช้งาน Messaging | ตามบริบท | ตามบริบท | ตามบริบท แต่ยังถูกจำกัดตาม route ที่เข้าถึงได้ |

## สรุปความพร้อมเชิงปฏิบัติการ

### พร้อมใช้ตอนนี้
- workflow ผู้รับบริการ, นัดหมาย และการรักษาแบบ end-to-end
- doctor ownership ครอบคลุมทั้ง calendar และ treatment records
- inventory ใช้งานได้จริงพร้อม traceability และการป้องกันที่สำคัญ
- financial logging พร้อม visibility ตามสิทธิ์
- เครื่องมือเอกสารทาง clinical
- settings และ feedback states พร้อมสำหรับเดโม

### สิ่งที่ต่อยอดได้ในอนาคต
- การตัดสต็อกตาม lot จริงในระดับ batch
- workflow ด้าน supplier / PO / GRN
- workflow คืนของให้ supplier
- policy การจัดการนัดหมายของ receptionist ที่ละเอียดขึ้น
- analytics ด้าน inventory และรายงาน vendor ขั้นสูง
