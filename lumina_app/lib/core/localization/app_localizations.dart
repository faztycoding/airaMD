import 'package:flutter/material.dart';

/// Simple app localization system with Thai (default) and English.
/// Access via `AppL10n.of(context)` or the `context.l10n` extension.
class AppL10n {
  final Locale locale;

  AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ?? AppL10n(const Locale('th'));
  }

  bool get isThai => locale.languageCode == 'th';

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  // ─── Navigation ───
  String get dashboard => isThai ? 'แดชบอร์ด' : 'Dashboard';
  String get patients => isThai ? 'ผู้ป่วย' : 'Patients';
  String get calendar => isThai ? 'ปฏิทิน' : 'Calendar';
  String get settings => isThai ? 'ตั้งค่า' : 'Settings';

  // ─── Dashboard ───
  String get todayAppointments => isThai ? 'นัดหมายวันนี้' : "Today's Appointments";
  String get totalPatients => isThai ? 'ผู้ป่วยทั้งหมด' : 'Total Patients';
  String get followUp => isThai ? 'ติดตามผล' : 'Follow Up';
  String get newPatient => isThai ? 'เพิ่มผู้ป่วย' : 'New Patient';
  String get newAppointment => isThai ? 'นัดหมายใหม่' : 'New Appointment';
  String get uploadPhoto => isThai ? 'อัปโหลดรูป' : 'Upload Photo';
  String get drawDiagram => isThai ? 'วาดไดอะแกรม' : 'Draw Diagram';
  String get search => isThai ? 'ค้นหา' : 'Search';
  String get noAppointmentsToday => isThai ? 'ไม่มีนัดหมายวันนี้' : 'No appointments today';

  // ─── Patient ───
  String get patientInfo => isThai ? 'ข้อมูล' : 'Info';
  String get healthAssessment => isThai ? 'HA (ประเมิน)' : 'HA';
  String get injectable => isThai ? 'ฉีด' : 'Injectable';
  String get laser => isThai ? 'เลเซอร์' : 'Laser';
  String get treatment => isThai ? 'ทรีทเมนต์' : 'Treatment';
  String get antiAging => 'Anti-aging';
  String get courseTable => isThai ? 'ตารางคอร์ส' : 'Course Table';
  String get beforeAfter => 'Before & After';
  String get consentForm => 'Consent Form';
  String get supplements => isThai ? 'อาหารเสริม' : 'Supplements';
  String get surgery => isThai ? 'ศัลยกรรม' : 'Surgery';
  String get expenses => isThai ? 'ค่าใช้จ่าย' : 'Expenses';
  String get editPatient => isThai ? 'แก้ไข' : 'Edit';
  String get age => isThai ? 'อายุ' : 'Age';
  String get years => isThai ? 'ปี' : 'yrs';

  // ─── Treatment Form ───
  String get newTreatmentRecord => isThai ? 'บันทึกการรักษาใหม่' : 'New Treatment Record';
  String get editTreatmentRecord => isThai ? 'แก้ไขบันทึกการรักษา' : 'Edit Treatment';
  String get treatmentInfo => isThai ? 'ข้อมูลการรักษา' : 'Treatment Info';
  String get treatmentName => isThai ? 'ชื่อหัตถการ' : 'Treatment Name';
  String get category => isThai ? 'หมวดหมู่' : 'Category';
  String get soapNotes => 'SOAP Notes';
  String get productsUsed => isThai ? 'ผลิตภัณฑ์ที่ใช้' : 'Products Used';
  String get results => isThai ? 'ผลการรักษา' : 'Results';
  String get followUpSchedule => isThai ? 'นัดติดตามผล' : 'Follow-up Schedule';
  String get instructions => isThai ? 'คำแนะนำหลังทำหัตถการ' : 'Post-treatment Instructions';
  String get notes => isThai ? 'หมายเหตุ' : 'Notes';
  String get save => isThai ? 'บันทึก' : 'Save';
  String get saving => isThai ? 'กำลังบันทึก...' : 'Saving...';
  String get cancel => isThai ? 'ยกเลิก' : 'Cancel';
  String get confirm => isThai ? 'ยืนยัน' : 'Confirm';
  String get delete => isThai ? 'ลบ' : 'Delete';

  // ─── Calendar ───
  String get appointmentList => isThai ? 'รายการนัดหมาย' : 'Appointments';
  String get staffRoster => isThai ? 'ตารางเวรทีมงาน' : 'Staff Roster';
  String get noAppointments => isThai ? 'ไม่มีนัดหมาย' : 'No appointments';

  // ─── Courses ───
  String get courses => isThai ? 'คอร์ส' : 'Courses';
  String get newCourse => isThai ? 'สร้างคอร์สใหม่' : 'New Course';
  String get sessionsUsed => isThai ? 'ครั้งที่ใช้' : 'Sessions Used';
  String get remaining => isThai ? 'คงเหลือ' : 'Remaining';
  String get expired => isThai ? 'หมดอายุ' : 'Expired';

  // ─── Financial ───
  String get financial => isThai ? 'การเงิน' : 'Financial';
  String get totalSpent => isThai ? 'ยอดใช้จ่ายสะสม' : 'Total Spent';
  String get outstanding => isThai ? 'ค้างชำระ' : 'Outstanding';
  String get paymentHistory => isThai ? 'ประวัติการชำระ' : 'Payment History';

  // ─── Settings ───
  String get clinicInfo => isThai ? 'ข้อมูลคลินิก' : 'Clinic Info';
  String get productLibrary => isThai ? 'คลังผลิตภัณฑ์' : 'Product Library';
  String get serviceList => isThai ? 'รายการบริการ' : 'Services';
  String get language => isThai ? 'ภาษา' : 'Language';
  String get security => isThai ? 'ความปลอดภัย' : 'Security';
  String get privacyPolicy => isThai ? 'นโยบายความเป็นส่วนตัว' : 'Privacy Policy';

  // ─── Common ───
  String get loading => isThai ? 'กำลังโหลด...' : 'Loading...';
  String get error => isThai ? 'เกิดข้อผิดพลาด' : 'Error';
  String get retry => isThai ? 'ลองใหม่' : 'Retry';
  String get noData => isThai ? 'ไม่มีข้อมูล' : 'No data';
  String get today => isThai ? 'วันนี้' : 'Today';
  String get all => isThai ? 'ทั้งหมด' : 'All';
  String get add => isThai ? 'เพิ่ม' : 'Add';
  String get edit => isThai ? 'แก้ไข' : 'Edit';
  String get close => isThai ? 'ปิด' : 'Close';
  String get back => isThai ? 'กลับ' : 'Back';
  String get next => isThai ? 'ถัดไป' : 'Next';
  String get done => isThai ? 'เสร็จ' : 'Done';
  String get yes => isThai ? 'ใช่' : 'Yes';
  String get no => isThai ? 'ไม่' : 'No';

  // ─── Before/After ───
  String get compare => isThai ? 'เปรียบเทียบ' : 'Compare';
  String get export_ => isThai ? 'ส่งออก' : 'Export';
  String get newComparisonSet => isThai ? 'สร้างชุดเปรียบเทียบใหม่' : 'New Comparison Set';
  String get noPhotosToCompare => isThai ? 'ยังไม่มีรูปให้เปรียบเทียบ' : 'No photos to compare';

  // ─── Safety ───
  String get safetyWarning => isThai ? 'คำเตือนความปลอดภัย' : 'Safety Warning';
  String get proceedAnyway => isThai ? 'รับทราบและดำเนินการต่อ' : 'Proceed Anyway';
  String get safetyCheck => isThai ? 'ตรวจสอบความปลอดภัย' : 'Safety Check';

  // ─── Consent ───
  String get signConsent => isThai ? 'ลงนามใบยินยอม' : 'Sign Consent';
  String get signature => isThai ? 'ลายเซ็น' : 'Signature';
  String get witness => isThai ? 'พยาน' : 'Witness';

  // ─── Diagram ───
  String get faceDiagram => isThai ? 'วาดไดอะแกรมใบหน้า' : 'Face Diagram';
  String get draw => isThai ? 'วาด' : 'Draw';
  String get pin => isThai ? 'หมุด' : 'Pin';
  String get undo => isThai ? 'ย้อนกลับ' : 'Undo';
  String get clear => isThai ? 'ล้าง' : 'Clear';

  // ─── Digital Notepad ───
  String get digitalNotepad => isThai ? 'กระดาษโน้ตดิจิทัล' : 'Digital Notepad';
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) => ['th', 'en'].contains(locale.languageCode);

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

/// Extension for easy access: `context.l10n`
extension AppL10nExtension on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
