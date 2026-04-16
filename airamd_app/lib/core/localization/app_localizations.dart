import 'package:flutter/material.dart';

/// Comprehensive app localization system with Thai (default) and English.
/// Access via `AppL10n.of(context)` or the `context.l10n` extension.
class AppL10n {
  final Locale locale;

  AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ?? AppL10n(const Locale('th'));
  }

  bool get isThai => locale.languageCode == 'th';

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  // ═══════════════════════════════════════════════════════════════
  // Authentication
  // ═══════════════════════════════════════════════════════════════
  String get loginTitle => isThai ? 'เข้าสู่ระบบ' : 'Sign In';
  String get loginDesc => isThai ? 'เข้าสู่ระบบเพื่อจัดการคลินิกของคุณ' : 'Sign in to manage your clinic';
  String get loginSubtitle => isThai ? 'ระบบจัดการคลินิกความงามอัจฉริยะ' : 'Intelligent Aesthetic Clinic Management';
  String get loginButton => isThai ? 'เข้าสู่ระบบ' : 'Sign In';
  String get signupTitle => isThai ? 'สร้างบัญชี' : 'Create Account';
  String get signupDesc => isThai ? 'ลงทะเบียนคลินิกใหม่เพื่อเริ่มต้นใช้งาน' : 'Register a new clinic to get started';
  String get signupButton => isThai ? 'ลงทะเบียน' : 'Sign Up';
  String get signupSuccess => isThai ? 'ลงทะเบียนสำเร็จ! กรุณาเข้าสู่ระบบ' : 'Registration successful! Please sign in.';
  String get signupSuccessTitle => isThai ? 'ลงทะเบียนสำเร็จ!' : 'Registration Successful!';
  String get signupSuccessBody => isThai ? 'กรุณาตรวจสอบอีเมลของคุณเพื่อยืนยันบัญชี\nจากนั้นกลับมาเข้าสู่ระบบได้ทันที' : 'Please check your email to confirm your account.\nThen come back and sign in.';
  String get understood => isThai ? 'เข้าใจแล้ว' : 'Got it';
  String get forgotPasswordTitle => isThai ? 'ลืมรหัสผ่าน' : 'Forgot Password';
  String get forgotPasswordDesc => isThai ? 'กรอกอีเมลเพื่อรับลิงก์รีเซ็ตรหัสผ่าน' : 'Enter your email to receive a reset link';
  String get sendResetLink => isThai ? 'ส่งลิงก์รีเซ็ต' : 'Send Reset Link';
  String get resetEmailSent => isThai ? 'ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลแล้ว' : 'Password reset link sent to your email';
  String get enterEmailFirst => isThai ? 'กรุณากรอกอีเมลก่อน' : 'Please enter your email first';
  String get email => isThai ? 'อีเมล' : 'Email';
  String get password => isThai ? 'รหัสผ่าน' : 'Password';
  String get confirmPassword => isThai ? 'ยืนยันรหัสผ่าน' : 'Confirm Password';
  String get fullName => isThai ? 'ชื่อ-นามสกุล' : 'Full Name';
  String get clinicName => isThai ? 'ชื่อคลินิก' : 'Clinic Name';
  String get clinicNameHint => isThai ? '(ไม่บังคับ)' : '(Optional)';
  String get forgotPassword => isThai ? 'ลืมรหัสผ่าน?' : 'Forgot password?';
  String get noAccount => isThai ? 'ยังไม่มีบัญชี?' : "Don't have an account?";
  String get haveAccount => isThai ? 'มีบัญชีอยู่แล้ว?' : 'Already have an account?';
  String get rememberedPassword => isThai ? 'จำรหัสผ่านได้แล้ว?' : 'Remembered your password?';
  String get invalidCredentials => isThai ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' : 'Invalid email or password';
  String get emailNotConfirmed => isThai ? 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ' : 'Please confirm your email before signing in';
  String get emailAlreadyUsed => isThai ? 'อีเมลนี้ถูกใช้งานแล้ว' : 'This email is already registered';
  String get weakPassword => isThai ? 'รหัสผ่านไม่แข็งแรงพอ' : 'Password is too weak';
  String get tooManyAttempts => isThai ? 'ลองมากเกินไป กรุณารอสักครู่' : 'Too many attempts. Please wait a moment.';
  String get passwordMismatch => isThai ? 'รหัสผ่านไม่ตรงกัน' : 'Passwords do not match';
  String get passwordTooShort => isThai ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' : 'Password must be at least 8 characters';
  String get invalidEmail => isThai ? 'รูปแบบอีเมลไม่ถูกต้อง' : 'Invalid email format';
  String get fieldRequired => isThai ? 'กรุณากรอกข้อมูล' : 'This field is required';
  String get verifyOtp => isThai ? 'ยืนยัน OTP' : 'Verify OTP';
  String get otpDesc => isThai ? 'กรอกรหัส OTP ที่ส่งไปยังอีเมลของคุณ' : 'Enter the OTP sent to your email';
  String get verifyButton => isThai ? 'ยืนยัน' : 'Verify';
  String get resendOtp => isThai ? 'ส่ง OTP ใหม่' : 'Resend OTP';
  String get poweredBy => isThai ? 'ขับเคลื่อนโดย' : 'Powered by';
  String get logoutConfirm => isThai ? 'ต้องการออกจากระบบหรือไม่?' : 'Are you sure you want to sign out?';
  String get logoutButton => isThai ? 'ออกจากระบบ' : 'Sign Out';

  // ═══════════════════════════════════════════════════════════════
  // Navigation
  // ═══════════════════════════════════════════════════════════════
  String get dashboard => isThai ? 'แดชบอร์ด' : 'Dashboard';
  String get patients => isThai ? 'ผู้ป่วย' : 'Patients';
  String get calendar => isThai ? 'ปฏิทิน' : 'Calendar';
  String get settings => isThai ? 'ตั้งค่า' : 'Settings';

  // ═══════════════════════════════════════════════════════════════
  // Dashboard
  // ═══════════════════════════════════════════════════════════════
  String get todayAppointments => isThai ? 'นัดหมายวันนี้' : "Today's Appointments";
  String get totalPatients => isThai ? 'ผู้ป่วยทั้งหมด' : 'Total Patients';
  String get followUp => isThai ? 'ติดตามผล' : 'Follow Up';
  String get newPatient => isThai ? 'เพิ่มผู้ป่วย' : 'New Patient';
  String get newAppointment => isThai ? 'นัดหมายใหม่' : 'New Appointment';
  String get uploadPhoto => isThai ? 'อัปโหลดรูป' : 'Upload Photo';
  String get drawDiagram => isThai ? 'วาดไดอะแกรม' : 'Draw Diagram';
  String get search => isThai ? 'ค้นหา' : 'Search';
  String get today => isThai ? 'วันนี้' : 'Today';
  String get tomorrow => isThai ? 'พรุ่งนี้' : 'Tomorrow';
  String nAppts(int n) => isThai ? '$n นัด' : '$n Appts';
  String nPatients(int n) => isThai ? '$n คน' : '$n patients';
  String inDays(int d) => isThai ? 'อีก $d วัน' : 'In $d days';
  String overdueDays(int d) => isThai ? 'เลยกำหนด $d วัน' : '$d days overdue';
  String get tapNewAppointment => isThai ? 'แตะ "นัดหมายใหม่" เพื่อเพิ่ม' : 'Tap "New Appointment" to add';
  String get lowStockAlert => isThai ? 'แจ้งเตือนสต็อกต่ำ' : 'Low Stock Alert';
  String get expiringProducts => isThai ? 'สินค้าใกล้หมดอายุ' : 'Expiring Products';

  // ═══════════════════════════════════════════════════════════════
  // Patient Profile / Tabs
  // ═══════════════════════════════════════════════════════════════
  String get patientInfo => isThai ? 'ข้อมูล' : 'Info';
  String get personalInfo => isThai ? 'ข้อมูลส่วนตัว' : 'Personal Info';
  String get personalInformation => isThai ? 'ข้อมูลส่วนตัว' : 'Personal Information';
  String get healthAssessment => isThai ? 'HA (ประเมิน)' : 'HA';
  String get healthHistory => isThai ? 'ประวัติสุขภาพ (HA)' : 'Health History (HA)';
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
  String get spending => 'Spending';
  String get patientStatus => isThai ? 'สถานะคนไข้' : 'Patient Status';
  String get messages => isThai ? 'ข้อความ' : 'Messages';
  String get editPatient => isThai ? 'แก้ไข' : 'Edit';
  String get editPatientInfo => isThai ? 'แก้ไขข้อมูลผู้รับบริการ' : 'Edit Patient';
  String get age => isThai ? 'อายุ' : 'Age';
  String get years => isThai ? 'ปี' : 'yrs';

  // ─── Patient List ───
  String get addPatient => isThai ? 'เพิ่มผู้รับบริการ' : 'Add Patient';
  String get patientList => isThai ? 'ผู้รับบริการ' : 'Patients';
  String get noPatientData => isThai ? 'ยังไม่มีข้อมูลผู้รับบริการ' : 'No patient data yet';
  String get tapAddToStart => isThai ? 'กดปุ่ม "เพิ่มผู้รับบริการ" เพื่อเริ่มต้น' : 'Tap "Add Patient" to start';
  String get searchNameNicknameHn => isThai ? 'ชื่อ / ชื่อเล่น' : 'Name / Nickname';
  String get patientNotFound => isThai ? 'ไม่พบข้อมูลผู้รับบริการ' : 'Patient not found';
  String get nameNickname => isThai ? 'ชื่อ / ชื่อเล่น' : 'Name / Nickname';
  String get passport => isThai ? 'พาสปอร์ต' : 'Passport';
  String get noDocuments => isThai ? 'ยังไม่มีข้อมูลเอกสาร' : 'No documents on file';
  String get symptoms => isThai ? 'อาการ' : 'Symptoms';
  String get smokingAlcoholMeds => isThai ? 'บุหรี่ / แอลกอฮอล์ / ยา' : 'Smoking / Alcohol / Medication';
  String get newDiagram => isThai ? 'สร้าง Diagram ใหม่' : 'New Diagram';
  String get noDiagramsYet => isThai ? 'ยังไม่มี Diagram' : 'No diagrams yet';
  String get diagramSession => isThai ? 'บันทึก Diagram' : 'Diagram Session';
  String get locked => isThai ? 'ล็อก' : 'Locked';
  String nViews(int n) => isThai ? '$n มุมมอง' : '$n views';
  String get nameComparisonHint => isThai ? 'ตั้งชื่อชุดเปรียบเทียบ เช่น "Botox หน้าผาก" หรือ "Filler ปาก"' : 'Name this set, e.g. "Botox Forehead"';
  String get create => isThai ? 'สร้าง' : 'Create';
  String get createBucketHint => isThai ? 'กรุณาสร้าง Storage Bucket "patient-photos" ใน Supabase Dashboard' : 'Create "patient-photos" bucket in Supabase';
  String get noComparisonPhotos => isThai ? 'ยังไม่มีรูปเปรียบเทียบ' : 'No comparison photos yet';
  String get notepadForSession => isThai ? 'โน้ตเพิ่มเติมสำหรับ session นี้' : 'Additional notes for this session';
  String get blankPagesDesc => isThai ? 'หน้าเปล่าสำหรับเขียนบันทึกอิสระ' : 'Blank pages for free-form notes';
  String get deleteThisNote => isThai ? 'ลบโน้ตนี้?' : 'Delete this note?';
  String get noNotesYet => isThai ? 'ยังไม่มีบันทึก' : 'No notes yet';
  String get templateAppointment => isThai ? 'แจ้งนัดหมาย' : 'Appointment';
  String get templateConfirmation => isThai ? 'ยืนยันนัด' : 'Confirmation';
  String get templateAfterCare => isThai ? 'คำแนะนำหลังทำ' : 'After Care';
  String get templatePromotion => isThai ? 'โปรโมชั่น' : 'Promotion';
  String get templateCustom => isThai ? 'ข้อความทั่วไป' : 'Custom';
  String get tapNewNoteHint => isThai ? 'แตะ "เขียนใหม่" เพื่อเริ่มจดบันทึกอิสระ\nวาดรูป เขียนข้อความ หรือร่างอะไรก็ได้' : 'Tap "New Note" to start writing freely\nDraw, write, or sketch anything you need';
  String get treatmentRecordLaser => isThai ? 'บันทึกการรักษา / Laser Parameters' : 'Treatment Record / Laser Parameters';
  String get nextAppointment => isThai ? 'นัดหมายครั้งถัดไป' : 'Next Appointment';
  String get avoidSun => isThai ? 'หลีกเลี่ยงแสงแดด (Avoid sun exposure)' : 'Avoid sun exposure';
  String get applySunscreen => isThai ? 'ทาครีมกันแดด SPF 30+ (Apply sunscreen SPF 30+)' : 'Apply sunscreen SPF 30+';
  String get applyMedication => isThai ? 'ทายาตามแพทย์สั่ง / มอยส์เจอไรเซอร์' : 'Apply prescribed medication / moisturizer';
  String get patientStatusInternal => isThai ? 'สถานะคนไข้ (ภายในเท่านั้น)' : 'Patient Status (Internal Only)';
  // ─── Access & Scaffold ───
  String get restricted => isThai ? 'จำกัด' : 'Restricted';
  String get noAccessSettings => isThai ? 'ไม่มีสิทธิ์เข้าถึงการตั้งค่า' : 'No access to settings';
  String get noAccessFinancial => isThai ? 'ไม่มีสิทธิ์เข้าถึงข้อมูลการเงิน' : 'No access to financial data';
  String get noAccessClinical => isThai ? 'ไม่มีสิทธิ์เข้าถึงข้อมูลการรักษา' : 'No access to clinical data';
  String get sortByRecent => isThai ? 'เรียงตาม: ล่าสุด' : 'Sort: Recent';
  String get searchHintFull => isThai ? 'ค้นหาชื่อ, ชื่อเล่น, HN, เบอร์โทร, บัตร ปชช...' : 'Search name, nickname, HN, phone, ID...';
  String get todayAppt => isThai ? 'นัดวันนี้' : 'Today';

  // ─── Patient Form ───
  String get patientInformation => isThai ? 'ข้อมูลผู้รับบริการ' : 'Patient Information';
  String get patientNameDesc => isThai ? 'กรอกชื่อ-นามสกุลของผู้รับบริการ' : 'Patient name and basic details';
  String get contactInformation => isThai ? 'ข้อมูลติดต่อ' : 'Contact Information';
  String get contactDesc => isThai ? 'เบอร์โทร, LINE, Facebook, IG, Email' : 'Phone, LINE, Facebook, IG, email';
  String get identificationDocs => isThai ? 'เอกสารยืนยันตัวตน' : 'Identification Documents';
  String get idDoc => isThai ? 'เอกสาร' : 'ID';
  String get medicalInfo => isThai ? 'การแพทย์' : 'Medical';
  String get medicalDesc => isThai ? 'แพ้ยา, โรคประจำตัว, พฤติกรรม' : 'Allergies, conditions, habits';
  String get firstName => isThai ? 'ชื่อ' : 'First Name';
  String get lastName => isThai ? 'นามสกุล' : 'Last Name';
  String get nickname => isThai ? 'ชื่อเล่น' : 'Nickname';
  String get dateOfBirth => isThai ? 'วันเกิด' : 'Date of Birth';
  String get gender => isThai ? 'เพศ' : 'Gender';
  String get phone => isThai ? 'เบอร์โทร' : 'Phone';
  String get patientEmail => isThai ? 'อีเมล' : 'Email';
  String get address => isThai ? 'ที่อยู่' : 'Address';
  String get nationalId => isThai ? 'เลขบัตรประชาชน' : 'National ID';
  String get passportNo => isThai ? 'เลข Passport' : 'Passport No.';
  String get drugAllergies => isThai ? 'แพ้ยา' : 'Drug Allergies';
  String get allergySymptoms => isThai ? 'อาการ' : 'Symptoms';
  String get medicalConditions => isThai ? 'โรคประจำตัว' : 'Medical Conditions';
  String get smoking => isThai ? 'สูบบุหรี่' : 'Smoking';
  String get alcohol => isThai ? 'แอลกอฮอล์' : 'Alcohol';
  String get usingRetinoids => isThai ? 'ใช้เรตินอยด์' : 'Using Retinoids';
  String get onAnticoagulant => isThai ? 'ยาต้านการแข็งตัวของเลือด' : 'On Anticoagulant';
  String get preferredChannel => isThai ? 'ช่องทางติดต่อ' : 'Preferred Channel';
  String get additionalNotes => isThai ? 'หมายเหตุเพิ่มเติม' : 'Additional Notes';
  String get noDrugAllergies => isThai ? 'ไม่มีประวัติแพ้ยา' : 'No drug allergies';
  String get noMedicalConditions => isThai ? 'ไม่มีโรคประจำตัว' : 'No medical conditions';
  String get none => isThai ? 'ไม่มี (None)' : 'None';
  String get occasional => isThai ? 'นานๆ ครั้ง' : 'Occasional';
  String get regular => isThai ? 'ประจำ' : 'Regular';
  String get male => isThai ? 'ชาย' : 'Male';
  String get female => isThai ? 'หญิง' : 'Female';
  String get other => isThai ? 'อื่นๆ' : 'Other';
  String get otherSpecify => isThai ? 'อื่นๆ (ระบุ)...' : 'Other (Specify)...';
  String get newPatientRegistration => isThai ? 'ลงทะเบียนผู้รับบริการใหม่' : 'New Patient Registration';
  String get contact => isThai ? 'ติดต่อ' : 'Contact';
  String get statusAndId => isThai ? 'สถานะ & เอกสาร' : 'Status & Identification';
  String get statusAndIdDesc => isThai ? 'สถานะผู้รับบริการ, เลขบัตร' : 'Patient status and ID documents';
  String get medicalHistory => isThai ? 'ประวัติทางการแพทย์' : 'Medical History';
  String get specialNotes => isThai ? 'บันทึกสิ่งที่ต้องระวังเป็นพิเศษ' : 'Any special instructions or notes';
  String get saveChanges => isThai ? 'บันทึกการแก้ไข' : 'Save Changes';
  String get registerPatient => isThai ? 'ลงทะเบียนผู้รับบริการ' : 'Register Patient';
  String get requireIdOrPassport => isThai
      ? 'กรุณากรอกเลขบัตรประชาชน หรือ หมายเลข Passport อย่างน้อย 1 อย่าง'
      : 'Please enter at least a National ID or Passport number';
  String get saveSuccess => isThai ? 'บันทึกสำเร็จ' : 'Saved successfully';
  String get editSuccess => isThai ? 'แก้ไขข้อมูลสำเร็จ' : 'Updated successfully';
  String get addPatientSuccess => isThai ? 'เพิ่มผู้รับบริการสำเร็จ' : 'Patient added successfully';
  String saveFailed(String e) => isThai ? 'บันทึกไม่สำเร็จ: $e' : 'Save failed: $e';
  String get pleaseFillRequired => isThai ? 'กรุณากรอกข้อมูลให้ครบ' : 'Please fill in all required fields';

  // ─── Delete Patient ───
  String get deletePatient => isThai ? 'ลบผู้รับบริการ?' : 'Delete patient?';
  String get confirmDelete => isThai ? 'ยืนยันลบ' : 'Confirm Delete';
  String deletePatientConfirm(String name, String? hn) =>
      isThai ? 'ต้องการลบ "$name" (${hn ?? "-"})?' : 'Delete "$name" (${hn ?? "-"})?';
  String get actionReversible => isThai ? 'การกระทำนี้สามารถกู้คืนได้ภายหลัง' : 'This action can be reversed later.';
  String deletedPatient(String name) => isThai ? 'ลบ $name แล้ว' : 'Deleted $name';
  String deleteFailed(String e) => isThai ? 'ลบไม่สำเร็จ: $e' : 'Delete failed: $e';
  String get deleteAll => isThai ? 'ลบทั้งหมด?' : 'Delete all?';

  // ═══════════════════════════════════════════════════════════════
  // Treatment Form (SOAP)
  // ═══════════════════════════════════════════════════════════════
  String get newTreatmentRecord => isThai ? 'บันทึกการรักษาใหม่' : 'New Treatment Record';
  String get editTreatmentRecord => isThai ? 'แก้ไขบันทึกการรักษา' : 'Edit Treatment';
  String editRecord(String label) => isThai ? 'แก้ไขบันทึก $label' : 'Edit $label';
  String get treatmentInfo => isThai ? 'ข้อมูลการรักษา' : 'Treatment Info';
  String get treatmentName => isThai ? 'ชื่อหัตถการ' : 'Treatment Name';
  String get category => isThai ? 'หมวดหมู่' : 'Category';
  String get soapNotes => 'SOAP Notes';
  String get productsUsed => isThai ? 'ผลิตภัณฑ์ที่ใช้' : 'Products Used';
  String get results => isThai ? 'ผลการรักษา' : 'Results';
  String get followUpSchedule => isThai ? 'นัดติดตามผล' : 'Follow-up Schedule';
  String get instructions => isThai ? 'คำแนะนำหลังทำหัตถการ' : 'Post-treatment Instructions';
  String get instructionsFollowUp => isThai ? 'คำแนะนำ & นัดติดตามผล' : 'Instructions & Follow-up';
  String get notes => isThai ? 'หมายเหตุ' : 'Notes';
  String get save => isThai ? 'บันทึก' : 'Save';
  String get saving => isThai ? 'กำลังบันทึก...' : 'Saving...';
  String get cancel => isThai ? 'ยกเลิก' : 'Cancel';
  String get confirm => isThai ? 'ยืนยัน' : 'Confirm';
  String get delete => isThai ? 'ลบ' : 'Delete';
  String newRecord(String label) => isThai ? '+ บันทึก $label ใหม่' : '+ New $label';
  String noRecords(String label) => isThai ? 'ยังไม่มีบันทึก $label' : 'No $label records yet';
  String get addNewRecord => isThai ? '+ บันทึก' : '+ Record';
  String get addSupplement => isThai ? '+ เพิ่มอาหารเสริม' : '+ Add Supplement';
  String get noSupplementData => isThai ? 'ยังไม่มีข้อมูลอาหารเสริม' : 'No supplement data yet';

  // ─── SOAP Sections ───
  String get subjectiveSymptoms => isThai ? 'Subjective Symptoms (อาการ/ปัญหาหลัก)' : 'Subjective (Chief Complaint)';
  String get objectiveExam => isThai ? 'Objective (ตรวจร่างกาย)' : 'Objective (Physical Exam)';
  String get assessmentDiagnosis => isThai ? 'Assessment (วินิจฉัย)' : 'Assessment (Diagnosis)';
  String get planOfTreatment => isThai ? 'Plan of Treatment (แผนการรักษา)' : 'Plan of Treatment';
  String get assessmentFull => isThai ? 'การวินิจฉัย (Assessment / Diagnosis)' : 'Assessment (Diagnosis / Problem List)';
  String get diagnosisHint => isThai ? 'การวินิจฉัย / Problem List' : 'Diagnosis / problem list...';
  String get treatmentPlanHint => isThai ? 'แผนการรักษา / สิ่งที่จะทำ' : 'Treatment plan...';

  // ─── Laser Parameters ───
  String get laserParameters => isThai ? 'Treatment Record / Laser Parameters' : 'Laser Parameters';
  String get deviceLaserType => isThai ? 'Device / Laser Type' : 'Device / Laser Type';
  String get energyFluence => isThai ? 'Energy / Fluence' : 'Energy / Fluence';
  String get pulseDurationSpotSize => isThai ? 'Pulse Duration / Spot Size' : 'Pulse Duration / Spot Size';
  String get totalShotsPasses => isThai ? 'Total Shots / Passes' : 'Total Shots / Passes';
  String get deviceLaserSubtitle => isThai ? 'อุปกรณ์ / เลเซอร์' : 'Device / Laser';

  // ─── Progress Notes ───
  String get responseToPrevious => isThai ? 'Response to Previous Treatment' : 'Response to Previous';
  String get improved => isThai ? 'ดีขึ้น' : 'Improved';
  String get stable => isThai ? 'คงที่' : 'Stable';
  String get worsened => isThai ? 'แย่ลง' : 'Worsened';
  String get notApplicable => isThai ? 'ไม่ระบุ' : 'N/A';
  String get adverseEvents => isThai ? 'อาการข้างเคียง (Adverse Events)' : 'Adverse Events';
  String get specifyTreatmentFirst => isThai ? 'กรุณาระบุชื่อหัตถการก่อน' : 'Please specify treatment name first';
  String get soapSubtitle => isThai ? 'บันทึก SOAP Notes + ผลิตภัณฑ์' : 'SOAP Notes + Products Used';
  String get info => isThai ? 'ข้อมูล' : 'Info';
  String get products => isThai ? 'ผลิตภัณฑ์' : 'Products';
  String get saveTreatment => isThai ? 'บันทึกการรักษา' : 'Save Treatment';
  String get selectFromLibrary => isThai ? 'เลือกจากคลัง:' : 'Select from library:';
  String get orTypeManually => isThai ? 'หรือพิมพ์ชื่อเอง →' : 'or type manually →';
  String get selectProduct => isThai ? '← เลือกจากคลัง' : '← Select from library';
  String get selectProductLeft => isThai ? 'เลือกผลิตภัณฑ์ด้านซ้าย' : 'Select product on the left';
  String get noProductsInLibrary => isThai ? 'ไม่มีผลิตภัณฑ์' : 'No products available';
  String get noProductsYet => isThai ? 'ยังไม่มีผลิตภัณฑ์ในคลัง' : 'No products in library yet';

  // ═══════════════════════════════════════════════════════════════
  // Calendar / Appointments
  // ═══════════════════════════════════════════════════════════════
  String get appointmentList => isThai ? 'รายการนัดหมาย' : 'Appointments';
  String get noAppointments => isThai ? 'ไม่มีนัดหมาย' : 'No appointments';
  String get manageSchedule => isThai ? 'จัดการตารางนัดหมาย' : 'Manage appointment schedule';
  String get calendarTitle => isThai ? 'ปฏิทินนัดหมาย' : 'Appointments';
  String get addAppointment => isThai ? 'เพิ่มนัดหมาย' : 'Add Appointment';
  String get noAppointmentsToday => isThai ? 'ไม่มีนัดหมายในวันนี้' : 'No appointments';
  String get tapNewAppt => isThai ? 'แตะ "นัดหมายใหม่" เพื่อเพิ่ม' : 'Tap "New Appointment" to add';
  String apptCount(int n) => isThai ? '$n นัด' : '$n Appts';
  String get failedLoadRoster => isThai ? 'โหลดตารางพนักงานไม่สำเร็จ' : 'Failed to load staff roster';
  String get staffRoster => isThai ? 'ตารางเวรทีมงาน' : 'Staff Roster';
  String staffStatusForDate(String date) => isThai ? 'สถานะพนักงานประจำวันที่ $date' : 'Team status for $date';
  String onDutyCount(int n) => isThai ? 'เข้าเวร $n' : 'On duty $n';
  String leaveCount(int n) => isThai ? 'ลา $n' : 'Leave $n';
  String halfDayCount(int n) => isThai ? 'ครึ่งวัน $n' : 'Half day $n';
  String get noStaffFound => isThai ? 'ยังไม่มีข้อมูลพนักงานในคลินิก' : 'No active staff found for this clinic.';
  String get onDuty => isThai ? 'เข้าเวร' : 'On duty';
  String get leave => isThai ? 'ลา' : 'Leave';
  String get halfDay => isThai ? 'ครึ่งวัน' : 'Half day';
  String get noSchedule => isThai ? 'ยังไม่ลงตาราง' : 'No schedule';
  String get ownerRole => isThai ? 'เจ้าของระบบ' : 'Owner';
  String get doctorRole => isThai ? 'แพทย์' : 'Doctor';
  String get staffRole => isThai ? 'พนักงาน' : 'Staff';
  String get noShiftTime => isThai ? 'ไม่มีเวลาเข้าเวร' : 'No shift time';
  String get manageShift => isThai ? 'จัดการเวร' : 'Manage Shift';
  String manageShiftFor(String name) => isThai ? 'จัดเวร $name' : 'Manage shift for $name';
  String get shiftStatus => isThai ? 'สถานะ' : 'Status';
  String get startTime => isThai ? 'เวลาเริ่ม' : 'Start Time';
  String get endTime => isThai ? 'เวลาสิ้นสุด' : 'End Time';
  String get shiftNote => isThai ? 'หมายเหตุ' : 'Note';
  String get saveShift => isThai ? 'บันทึกเวร' : 'Save Shift';
  String get shiftSaved => isThai ? 'บันทึกเวรสำเร็จ' : 'Shift saved';
  String get deleteShift => isThai ? 'ลบเวร' : 'Delete Shift';
  String get shiftDeleted => isThai ? 'ลบเวรสำเร็จ' : 'Shift deleted';
  String get notFoundShort => isThai ? 'ไม่พบข้อมูล' : 'Not found';
  String get noTreatmentSpecified => isThai ? 'ไม่ระบุหัตถการ' : 'No treatment specified';
  String get editAppointment => isThai ? 'แก้ไขนัดหมาย' : 'Edit Appointment';
  String get setDateTime => isThai ? 'กำหนดวัน-เวลา' : 'Set Date & Time';
  String get selectDate => isThai ? 'เลือกวันที่' : 'Select date';
  String get selectTime => isThai ? 'เลือกเวลา' : 'Select time';
  String get selectPatient => isThai ? 'กรุณาเลือกผู้รับบริการ' : 'Please select a patient';
  String get procedure => isThai ? 'หัตถการ' : 'Procedure';
  String get procedureToPerform => isThai ? 'หัตถการที่จะทำ' : 'Procedure';
  String get appointmentSaveSuccess => isThai ? 'สร้างนัดหมายสำเร็จ' : 'Appointment created';
  String get appointmentEditSuccess => isThai ? 'แก้ไขนัดหมายสำเร็จ' : 'Appointment updated';
  String get dateTime => isThai ? 'วัน-เวลา' : 'DateTime';
  String get status => isThai ? 'สถานะ' : 'Status';
  String get patient => isThai ? 'ผู้รับบริการ' : 'Patient';
  String get saveAppointment => isThai ? 'บันทึกนัดหมาย' : 'Save Appointment';
  String get selectPatientForAppt => isThai ? 'เลือกผู้รับบริการสำหรับนัดหมาย' : 'Select patient for appointment';
  String get dateTimeSubtitle => isThai ? 'วันที่, เวลาเริ่ม, เวลาสิ้นสุด' : 'Date, start time, end time';
  String get appointmentInfo => isThai ? 'ข้อมูลนัดหมาย' : 'Appointment Info';
  String get appointmentInfoSubtitle => isThai ? 'ประเภทหัตถการ, หมายเหตุ' : 'Procedure type, notes';
  String get selectApptStatus => isThai ? 'เลือกสถานะนัดหมาย' : 'Select appointment status';

  // ═══════════════════════════════════════════════════════════════
  // Courses
  // ═══════════════════════════════════════════════════════════════
  String get courses => isThai ? 'คอร์ส' : 'Courses';
  String get newCourse => isThai ? 'สร้างคอร์สใหม่' : 'New Course';
  String get editCourse => isThai ? 'แก้ไขคอร์ส' : 'Edit Course';
  String get sessionsUsed => isThai ? 'ครั้งที่ใช้' : 'Sessions Used';
  String get sessions => isThai ? 'เซสชั่น' : 'Sessions';
  String get remaining => isThai ? 'คงเหลือ' : 'Remaining';
  String get expired => isThai ? 'หมดอายุ' : 'Expired';
  String get course => isThai ? 'คอร์ส' : 'Course';
  String get patientCourses => isThai ? 'คอร์สของคนไข้' : "Patient's Courses";
  String get courseTreatment => isThai ? 'คอร์สทรีทเมนต์' : 'Course Treatments';
  String get noCoursesYet => isThai ? 'ยังไม่มีคอร์สที่ผูกกับคนไข้รายนี้' : 'No courses linked to this patient yet';
  String get noCoursesTreatment => isThai ? 'ยังไม่มีคอร์สทรีทเมนต์' : 'No treatment courses yet';
  String get courseEmptyDesc => isThai
      ? 'เริ่มสร้างคอร์สเพื่อจัดการแพ็กเกจรักษา\nติดตามจำนวนครั้ง และวันหมดอายุ'
      : 'Create courses to manage treatment packages\ntrack sessions and expiry dates';
  String sessionCount(int used, int total) => isThai ? 'ใช้แล้ว $used/$total ครั้ง' : 'Used $used/$total sessions';
  String remainingSessions(int n) => isThai ? 'เหลือ $n ครั้ง' : '$n remaining';
  String totalSessions(int bought, int bonus) => isThai ? 'รวมทั้งหมด: ${bought + bonus} ครั้ง' : 'Total: ${bought + bonus} sessions';
  String sessionNotes(String s) => isThai ? 'โน้ตเพิ่มเติมสำหรับ session นี้' : 'Additional notes for this session';
  String get asNeeded => isThai ? 'ตามความจำเป็น (As needed)' : 'As needed';
  String get courseManagementSubtitle => isThai ? 'ระบบจัดการคอร์สรักษา' : 'Treatment course management';
  String get saveCourse => isThai ? 'บันทึกคอร์ส' : 'Save Course';
  String get courseEditSuccess => isThai ? 'แก้ไขคอร์สสำเร็จ' : 'Course updated';
  String get courseSaveSuccess => isThai ? 'สร้างคอร์สสำเร็จ' : 'Course created';
  String get treatmentDetails => isThai ? 'รายละเอียดการรักษา' : 'Treatment Details';
  String get treatmentDetailsSubtitle => isThai ? 'ประเภท, แพทย์ผู้รับผิดชอบ' : 'Category, doctor';
  String get treatmentCategory => isThai ? 'ประเภทการรักษา' : 'Treatment Category';
  String get responsibleDoctor => isThai ? 'แพทย์ผู้รับผิดชอบ' : 'Responsible Doctor';
  String get treatmentArea => isThai ? 'บริเวณที่รักษา' : 'Treatment Area';
  String get low => isThai ? 'ต่ำ' : 'Low';

  // ═══════════════════════════════════════════════════════════════
  // Financial
  // ═══════════════════════════════════════════════════════════════
  String get financial => isThai ? 'การเงิน' : 'Financial';
  String get totalSpent => isThai ? 'ยอดใช้จ่ายสะสม' : 'Total Spent';
  String get outstanding => isThai ? 'ค้างชำระ' : 'Outstanding';
  String get paymentHistory => isThai ? 'ประวัติการชำระ' : 'Payment History';
  String get noOutstanding => isThai ? 'ไม่มียอดค้างชำระ' : 'No outstanding balance';
  String get noTransactions => isThai ? 'ไม่มีรายการ' : 'No transactions';
  String get paymentWillShowHere => isThai
      ? 'เมื่อมีการบันทึกรับชำระหรือค่าใช้จ่าย ข้อมูลจะแสดงในส่วนนี้'
      : 'Payment and charge records will appear here';

  // ═══════════════════════════════════════════════════════════════
  // Settings
  // ═══════════════════════════════════════════════════════════════
  String get clinicInfo => isThai ? 'ข้อมูลคลินิก' : 'Clinic Info';
  String get productLibrary => isThai ? 'คลังผลิตภัณฑ์' : 'Product Library';
  String get serviceList => isThai ? 'รายการบริการ' : 'Services';
  String get serviceManagement => isThai ? 'บริการ / หัตถการ' : 'Services / Procedures';
  String get language => isThai ? 'ภาษา' : 'Language';
  String get security => isThai ? 'ความปลอดภัย' : 'Security';
  String get privacyPolicy => isThai ? 'นโยบายความเป็นส่วนตัว' : 'Privacy Policy';
  String get auditLogs => isThai ? 'ประวัติการใช้งานระบบ' : 'Audit Logs';
  String get inventory => isThai ? 'คลังสินค้า' : 'Inventory';
  String get system => isThai ? 'ระบบ' : 'System';
  String get addProduct => isThai ? 'เพิ่มผลิตภัณฑ์' : 'Add Product';
  String get addService => isThai ? 'เพิ่มบริการใหม่' : 'Add Service';
  String deleteProduct(String name) => isThai ? 'ต้องการลบ "$name" ?' : 'Delete "$name"?';
  String deleteService(String name) => isThai ? 'ต้องการลบบริการ "$name" ?' : 'Delete service "$name"?';
  String get transactionHistory => isThai ? 'ประวัติธุรกรรม' : 'Transaction History';
  String get noTransactionsYet => isThai ? 'ยังไม่มีธุรกรรม' : 'No transactions yet';
  String get transactionSaveSuccess => isThai ? 'บันทึกธุรกรรมสำเร็จ' : 'Transaction saved';
  String get owner => isThai ? 'เจ้าของระบบ' : 'Owner';
  String get doctor => isThai ? 'แพทย์' : 'Doctor';
  String get receptionist => isThai ? 'พนักงานต้อนรับ' : 'Receptionist';

  // ═══════════════════════════════════════════════════════════════
  // Auth / PIN Lock
  // ═══════════════════════════════════════════════════════════════
  String get enterPinToUnlock => isThai ? 'ใส่รหัส PIN เพื่อเข้าใช้งาน' : 'Enter PIN to unlock';
  String get useBiometrics => isThai ? 'ใช้ลายนิ้วมือ / Face ID' : 'Use Biometrics';
  String get wrongPin => isThai ? 'รหัส PIN ไม่ถูกต้อง' : 'Incorrect PIN';
  String get pinUnlocked => isThai ? 'ปลดล็อกสำเร็จ' : 'Unlocked';

  // ═══════════════════════════════════════════════════════════════
  // Common / Shared
  // ═══════════════════════════════════════════════════════════════
  String get loading => isThai ? 'กำลังโหลด...' : 'Loading...';
  String get error => isThai ? 'เกิดข้อผิดพลาด' : 'Error';
  String errorMsg(String e) => isThai ? 'เกิดข้อผิดพลาด: $e' : 'Error: $e';
  String get retry => isThai ? 'ลองใหม่' : 'Retry';
  String get noData => isThai ? 'ไม่มีข้อมูล' : 'No data';
  String get notFound => isThai ? 'ไม่พบข้อมูล' : 'Not found';
  String get all => isThai ? 'ทั้งหมด' : 'All';
  String get add => isThai ? 'เพิ่ม' : 'Add';
  String get edit => isThai ? 'แก้ไข' : 'Edit';
  String get immutable => isThai ? 'แก้ไขไม่ได้' : 'Immutable';
  String get close => isThai ? 'ปิด' : 'Close';
  String get back => isThai ? 'กลับ' : 'Back';
  String get next => isThai ? 'ถัดไป' : 'Next';
  String get done => isThai ? 'เสร็จ' : 'Done';
  String get yes => isThai ? 'ใช่' : 'Yes';
  String get no => isThai ? 'ไม่' : 'No';
  String get readOnly => isThai ? 'อ่านอย่างเดียว' : 'Read Only';
  String get failedToLoad => isThai ? 'โหลดข้อมูลไม่สำเร็จ' : 'Failed to load data';
  String get failedToLoadPatient => isThai ? 'โหลดข้อมูลไม่สำเร็จ' : 'Failed to load patient data';
  String get photoUploaded => isThai ? 'อัพโหลดรูปสำเร็จ' : 'Photo uploaded';
  String exportFailed(String e) => isThai ? 'ส่งออกไม่สำเร็จ: $e' : 'Export failed: $e';
  String get createStorageBucket => isThai
      ? 'กรุณาสร้าง Storage Bucket "patient-photos" ใน Supabase Dashboard'
      : 'Create "patient-photos" bucket in Supabase';

  // ═══════════════════════════════════════════════════════════════
  // Before/After
  // ═══════════════════════════════════════════════════════════════
  String get compare => isThai ? 'เปรียบเทียบ' : 'Compare';
  String get export_ => isThai ? 'ส่งออก' : 'Export';
  String get newComparisonSet => isThai ? 'สร้างชุดเปรียบเทียบใหม่' : 'New Comparison Set';
  String get noPhotosToCompare => isThai ? 'ยังไม่มีรูปให้เปรียบเทียบ' : 'No photos to compare';
  String get comparisonSetName => isThai ? 'ชื่อชุดเปรียบเทียบ' : 'Set name';
  String get comparisonSetNameHint => isThai
      ? 'ตั้งชื่อชุดเปรียบเทียบ เช่น "Botox หน้าผาก" หรือ "Filler ปาก"'
      : 'Name this set, e.g. "Botox Forehead"';
  String get areaHint => isThai ? 'เช่น หน้าผาก, คาง, แก้ม' : 'e.g. Forehead, Chin';

  // ═══════════════════════════════════════════════════════════════
  // Safety Check
  // ═══════════════════════════════════════════════════════════════
  String get safetyWarning => isThai ? 'คำเตือนความปลอดภัย' : 'Safety Warning';
  String get proceedAnyway => isThai ? 'รับทราบและดำเนินการต่อ' : 'Proceed Anyway';
  String get safetyCheck => isThai ? 'ตรวจสอบความปลอดภัย' : 'Safety Check';
  String get allergiesWarning => isThai ? '⚠️ แพ้ยา' : '⚠️ Allergies';

  // ═══════════════════════════════════════════════════════════════
  // Consent Form
  // ═══════════════════════════════════════════════════════════════
  String get signConsent => isThai ? 'ลงนามใบยินยอม' : 'Sign Consent';
  String get signature => isThai ? 'ลายเซ็น' : 'Signature';
  String get witness => isThai ? 'พยาน' : 'Witness';
  String get witnessName => isThai ? 'ชื่อพยาน' : 'Witness Name';
  String get witnessNameOptional => isThai ? 'ชื่อพยาน (ถ้ามี)' : 'Witness name (optional)';
  String get consentAgreement => isThai ? 'ข้อตกลงยินยอม' : 'Consent Agreement';
  String get signBelowInstruction => isThai ? 'ใช้นิ้วหรือปากกาเซ็นด้านล่าง' : 'Sign below with finger or stylus';
  String get savedConsentForms => isThai ? 'Consent Form ที่บันทึกแล้ว' : 'Saved Consent Forms';
  String get noConsentFormsHint => isThai ? 'กดปุ่มด้านบนเพื่อสร้าง Consent Form ใหม่' : 'Tap button above to create new consent form';
  String get consentFormTitle => isThai ? 'ใบยินยอมรับการรักษา' : 'Consent Form';
  String get consentSaved => isThai ? 'บันทึกใบยินยอมเรียบร้อย' : 'Consent form saved';
  String get newConsentForm => isThai ? 'สร้างใบยินยอมใหม่' : 'New Consent Form';
  String consentSubtitle(String date) => 'Informed Consent • $date';
  String get consent => isThai ? 'ยินยอม' : 'Consent';
  String get patientSignature => isThai ? 'ลายเซ็นผู้รับบริการ' : 'Patient Signature';
  String get procedureToPerformSection => isThai ? 'หัตถการที่จะทำ' : 'Procedure';
  String get notesHint => isThai ? 'บันทึกเพิ่มเติม (ถ้ามี)' : 'Additional notes (optional)';
  String get consentGeneral => isThai
      ? 'ข้าพเจ้ายินยอมรับการรักษาตามหัตถการที่ระบุข้างต้น โดยได้รับคำอธิบายเกี่ยวกับขั้นตอน ความเสี่ยง ผลข้างเคียงที่อาจเกิดขึ้น และทางเลือกอื่นๆ เป็นที่เข้าใจดีแล้ว'
      : 'I consent to the procedure described above. Risks, benefits, and alternatives have been explained to me.';
  String get consentPhoto => isThai
      ? 'ข้าพเจ้ายินยอมให้ถ่ายภาพก่อน-หลังการรักษา เพื่อใช้ในการติดตามผลการรักษา'
      : 'I consent to before/after photography for treatment documentation.';
  String get consentAnesthesia => isThai
      ? 'ข้าพเจ้ายินยอมรับยาชาเฉพาะที่ (ถ้าจำเป็น)'
      : 'I consent to local anesthesia if required.';
  String get consentFullName => isThai ? 'ชื่อ-สกุล' : 'Name';
  String get signedDate => isThai ? 'วันที่ลงนาม' : 'Signed';

  // ═══════════════════════════════════════════════════════════════
  // Face Diagram
  // ═══════════════════════════════════════════════════════════════
  String get faceDiagram => isThai ? 'วาดไดอะแกรมใบหน้า' : 'Face Diagram';
  String get faceDiagramTitle => isThai ? 'Clinical Illustration / Skin Mapping' : 'Face Diagram';
  String get draw => isThai ? 'วาด' : 'Draw';
  String get pin => isThai ? 'หมุด' : 'Pin';
  String get undo => isThai ? 'ย้อนกลับ' : 'Undo';
  String get clear => isThai ? 'ล้าง' : 'Clear';
  String get front => isThai ? 'ด้านหน้า' : 'Front';
  String get left => isThai ? 'ด้านซ้าย' : 'Left';
  String get right => isThai ? 'ด้านขวา' : 'Right';
  String get side => isThai ? 'ด้านข้าง' : 'Side';
  String get lipZone => isThai ? 'ปาก/ริมฝีปาก' : 'Lip Zone';
  String get savedDiagrams => isThai ? 'Diagram ที่บันทึกแล้ว' : 'Saved Diagrams';
  String get clearAllStrokes => isThai ? 'ลบเส้นทั้งหมดในมุมมองนี้' : 'Clear all strokes in this view';
  String get viewDiagram => isThai ? 'ดู Diagram' : 'View Diagram';
  String get subjectiveTitle => isThai ? 'Subjective Symptoms (อาการ/ปัญหาหลัก)' : 'Subjective (Chief Complaint)';
  String get subjectiveHint => isThai ? 'ระบุอาการ / ปัญหาที่มา' : 'Chief complaint...';
  String get objectiveTitle => isThai ? 'Objective (ตรวจร่างกาย)' : 'Objective (Physical Exam)';
  String get objectiveHint => isThai ? 'ผลการตรวจ / สิ่งที่พบ' : 'Findings...';
  String get assessmentTitle => isThai ? 'Assessment (วินิจฉัย)' : 'Assessment (Diagnosis)';
  String get assessmentHint => isThai ? 'การวินิจฉัย / Problem List' : 'Diagnosis / problem list...';
  String get planTitle => isThai ? 'Plan of Treatment (แผนการรักษา)' : 'Plan of Treatment';
  String get planHint => isThai ? 'แผนการรักษา / สิ่งที่จะทำ' : 'Treatment plan...';
  String get laserParams => isThai ? 'Treatment Record / Laser Parameters' : 'Laser Parameters';
  String get doctorHint => isThai ? 'เช่น พญ.เตย' : 'e.g. Dr. Toey';

  // ═══════════════════════════════════════════════════════════════
  // Digital Notepad
  // ═══════════════════════════════════════════════════════════════
  String get digitalNotepad => isThai ? 'กระดาษโน้ตดิจิทัล' : 'Digital Notepad';
  String get newNote => isThai ? 'เขียนใหม่' : 'New Note';
  String get startWriting => isThai ? 'เริ่มเขียน' : 'Start Writing';
  String get blankPageDesc => isThai ? 'หน้าเปล่าสำหรับเขียนบันทึกอิสระ' : 'Blank pages for free-form notes';
  String get viewNotepad => isThai ? 'ดู Notepad' : 'View Notepad';
  String get noteTitleHint => isThai ? 'ชื่อโน้ต (ไม่บังคับ)...' : 'Note title (optional)...';
  String get notepadSaved => isThai ? 'บันทึก Notepad เรียบร้อย ✓' : 'Notepad saved ✓';
  String get nothingToSave => isThai ? 'ยังไม่ได้เขียนอะไรเลย — กรุณาเขียนก่อนบันทึก' : 'Nothing to save — please write something first';

  // ═══════════════════════════════════════════════════════════════
  // Messaging / LINE / WhatsApp
  // ═══════════════════════════════════════════════════════════════
  String get message => isThai ? 'ข้อความ' : 'Message';
  String get sendMessage => isThai ? 'ส่งข้อความ' : 'Send Message';
  String get sendAndLog => isThai ? 'ส่ง + บันทึก' : 'Send & Log';
  String get sendMessageAndLog => isThai ? 'ส่งข้อความ + บันทึก' : 'Send Message + Log';
  String get messageSaved => isThai ? 'บันทึกข้อความสำเร็จ' : 'Message logged';
  String get channel => isThai ? 'ช่องทาง:' : 'Channel:';
  String get openLine => isThai ? 'เปิด LINE' : 'Open LINE';
  String get call => isThai ? 'โทร' : 'Call';
  String get appointmentTemplate => isThai ? 'แจ้งนัดหมาย' : 'Appointment';
  String get confirmationTemplate => isThai ? 'ยืนยัน' : 'Confirmation';
  String get afterCareTemplate => isThai ? 'คำแนะนำหลังทำ' : 'After Care';
  String get promotionTemplate => isThai ? 'โปรโมชั่น' : 'Promotion';
  String get promoShort => isThai ? 'โปรฯ' : 'Promo';
  String get customTemplate => isThai ? 'ข้อความทั่วไป' : 'Custom';
  String get messageHistory => isThai ? 'ประวัติข้อความ' : 'Message History';
  String get noMessagesYet => isThai ? 'ยังไม่มีข้อความที่บันทึก' : 'No messages logged yet';
  String get typeLabel => isThai ? 'ประเภท:' : 'Type:';
  String get apptShort => isThai ? 'นัดหมาย' : 'Appointment';
  String get confirmShort => isThai ? 'ยืนยัน' : 'Confirmation';
  String get afterCareShort => isThai ? 'หลังทำ' : 'After Care';
  String get customShort => isThai ? 'ทั่วไป' : 'Custom';

  // ═══════════════════════════════════════════════════════════════
  // Offline / Sync
  // ═══════════════════════════════════════════════════════════════
  String get offline => isThai ? 'ออฟไลน์' : 'Offline';
  String get online => isThai ? 'ออนไลน์' : 'Online';
  String pendingSync(int n) => isThai ? '$n รายการรอซิงค์' : '$n pending sync';
  String get synced => isThai ? 'ซิงค์แล้ว' : 'Synced';
  String get lastSynced => isThai ? 'ซิงค์ล่าสุด' : 'Last synced';

  // ═══════════════════════════════════════════════════════════════
  // Audit Logs
  // ═══════════════════════════════════════════════════════════════
  String get auditLogTitle => isThai ? 'ประวัติการใช้งานระบบ' : 'Audit Logs';
  String get filterByAction => isThai ? 'กรองตามการกระทำ' : 'Filter by action';
  String get filterByEntity => isThai ? 'กรองตามประเภท' : 'Filter by entity';
  String get searchAuditLogs => isThai ? 'ค้นหา...' : 'Search...';

  // ═══════════════════════════════════════════════════════════════
  // Push Notifications
  // ═══════════════════════════════════════════════════════════════
  String get notificationSettings => isThai ? 'การแจ้งเตือน' : 'Notifications';
  String get notificationSettingsSubtitle => isThai ? 'แจ้งเตือนนัดหมาย, ติดตามผล' : 'Appointments, follow-up reminders';
  String get enableNotifications => isThai ? 'เปิดการแจ้งเตือน' : 'Enable Notifications';
  String get enableNotificationsDesc => isThai ? 'เปิด/ปิด การแจ้งเตือนทั้งหมด' : 'Turn all notifications on/off';
  String get appointmentReminder => isThai ? 'แจ้งเตือนนัดหมาย' : 'Appointment Reminders';
  String get appointmentReminderDesc => isThai ? 'แจ้งเตือนก่อนนัดหมาย 1 ชม.' : 'Notify 1 hour before appointment';
  String get followUpReminder => isThai ? 'แจ้งเตือนติดตามผล' : 'Follow-up Reminders';
  String get followUpReminderDesc => isThai ? 'แจ้งเตือนวัน Follow-up' : 'Notify on follow-up day';
  String get testNotification => isThai ? 'ทดสอบการแจ้งเตือน' : 'Test Notification';
  String get testNotificationBody => isThai ? 'นี่คือการแจ้งเตือนทดสอบจาก airaMD' : 'This is a test notification from airaMD';
  String get testNotificationSent => isThai ? 'ส่งการแจ้งเตือนทดสอบแล้ว' : 'Test notification sent';
  String get notificationInfoNote => isThai
      ? 'การแจ้งเตือนต้องใช้ Firebase Cloud Messaging (FCM)\nหากยังไม่ได้ตั้งค่า Firebase ให้ทำตามคู่มือในหน้าตั้งค่า'
      : 'Notifications require Firebase Cloud Messaging (FCM).\nIf not yet configured, follow the setup guide in Settings.';

  // ═══════════════════════════════════════════════════════════════
  // Messaging Config
  // ═══════════════════════════════════════════════════════════════
  String get messagingConfig => isThai ? 'ตั้งค่าข้อความ' : 'Messaging Config';
  String get messagingConfigSubtitle => isThai ? 'LINE OA, WhatsApp, SMS' : 'LINE OA, WhatsApp, SMS';
  String get lineApiConnected => isThai ? 'LINE OA เชื่อมต่อแล้ว' : 'LINE OA Connected';
  String get lineApiNotConfigured => isThai ? 'ยังไม่ได้ตั้งค่า LINE OA' : 'LINE OA Not Configured';
  String get lineConfigDesc => isThai
      ? 'กรอก Channel Access Token และ Channel Secret จาก LINE Developers Console เพื่อส่งข้อความอัตโนมัติผ่าน LINE OA'
      : 'Enter Channel Access Token and Secret from LINE Developers Console to enable automatic LINE messaging';
  String get smsDesc => isThai ? 'เปิดใช้งาน SMS เพื่อส่งข้อความผ่านเบอร์โทร' : 'Enable SMS for phone-based messaging';
  String get howItWorks => isThai ? 'วิธีตั้งค่า' : 'How It Works';
  String get lineStep1 => isThai ? 'เข้า LINE Developers Console (developers.line.biz)' : 'Go to LINE Developers Console (developers.line.biz)';
  String get lineStep2 => isThai ? 'สร้าง Provider + Messaging API Channel' : 'Create Provider + Messaging API Channel';
  String get lineStep3 => isThai ? 'คัดลอก Channel Access Token (Long-lived) และ Channel Secret' : 'Copy Channel Access Token (Long-lived) and Channel Secret';
  String get lineStep4 => isThai ? 'วาง Token และ Secret ในช่องด้านบน แล้วกดบันทึก' : 'Paste Token and Secret above, then save';

  // ═══════════════════════════════════════════════════════════════
  // Settings Screen Items
  // ═══════════════════════════════════════════════════════════════
  String get settingsClinic => isThai ? 'คลินิก' : 'Clinic';
  String get clinicInfoSubtitle => isThai ? 'ชื่อ ที่อยู่ เวลาเปิด' : 'Name, address, hours';
  String get manageStaff => isThai ? 'จัดการพนักงาน' : 'Manage Staff';
  String get manageStaffSubtitle => isThai ? 'เพิ่ม/แก้ไข บทบาท' : 'Add/edit roles';
  String get productLibrarySubtitle => isThai ? 'Botox, Filler, สต๊อก' : 'Botox, Filler, Stock';
  String get stockTransactions => isThai ? 'ธุรกรรมสต็อก' : 'Stock Transactions';
  String get stockTransactionsSubtitle => isThai ? 'รับเข้า เบิกออก ปรับยอด' : 'In, out, adjustment';
  String get financialSubtitle => isThai ? 'รายรับ ค้างชำระ ปิดยอด' : 'Revenue, outstanding, close';
  String get settingsProcedures => isThai ? 'หัตถการ' : 'Procedures';
  String get serviceListSubtitle => isThai ? 'ราคาหัตถการทั้งหมด' : 'All procedure pricing';
  String get manageCourses => isThai ? 'จัดการคอร์สทรีทเมนต์' : 'Manage treatment courses';
  String get consentTemplates => isThai ? 'ใบยินยอม' : 'Consent Forms';
  String get consentTemplateSubtitle => isThai ? 'เทมเพลต Consent Form' : 'Consent form templates';
  String get treatmentRules => isThai ? 'กฎระยะห่าง' : 'Interval Rules';
  String get treatmentRulesSubtitle => isThai ? 'Botox, Filler, HIFU...' : 'Botox, Filler, HIFU...';
  String get languageSubtitle => isThai ? 'ไทย / English' : 'Thai / English';
  String get securitySubtitle => isThai ? 'PIN, Auto-lock' : 'PIN, Auto-lock';
  String get cloudData => isThai ? 'ข้อมูลคลาวด์' : 'Cloud Data';
  String get cloudDataSubtitle => isThai ? 'Backup, Sync' : 'Backup, Sync';
  String get selectMenuToSettings => isThai ? 'เลือกเมนูด้านซ้ายเพื่อตั้งค่า' : 'Select a menu item to configure';
  String get settingsWillShowHere => isThai ? 'การตั้งค่าจะแสดงในพื้นที่นี้' : 'Settings will appear in this area';

  // ─── PIN Management ───
  String get setupPin => isThai ? 'ตั้งรหัส PIN 6 หลัก' : 'Set a 6-digit PIN';
  String get confirmPinAgain => isThai ? 'ยืนยันรหัส PIN อีกครั้ง' : 'Confirm PIN again';
  String get pinMismatch => isThai ? 'รหัสไม่ตรงกัน ลองใหม่' : 'PINs do not match. Try again';
  String get pinIncorrect => isThai ? 'รหัสไม่ถูกต้อง' : 'Incorrect PIN';
  String get biometricReason => isThai ? 'ยืนยันตัวตนเพื่อเข้าใช้ airaMD' : 'Authenticate to access airaMD';
  String get changePin => isThai ? 'เปลี่ยนรหัส PIN' : 'Change PIN';
  String get changePinSubtitle => isThai ? 'ตั้งรหัส PIN ใหม่' : 'Set a new PIN code';
  String get enterCurrentPin => isThai ? 'กรอกรหัส PIN ปัจจุบัน' : 'Enter current PIN';
  String get enterNewPin => isThai ? 'กรอกรหัส PIN ใหม่' : 'Enter new PIN';
  String get confirmNewPin => isThai ? 'ยืนยันรหัส PIN ใหม่' : 'Confirm new PIN';
  String get pinChanged => isThai ? 'เปลี่ยนรหัส PIN สำเร็จ' : 'PIN changed successfully';
  String get autoLock => isThai ? 'ล็อกอัตโนมัติ' : 'Auto-lock';
  String get autoLockSubtitle => isThai ? 'ล็อกเมื่อปิดแอป' : 'Lock when app is backgrounded';

  // ═══════════════════════════════════════════════════════════════
  // Privacy Policy (PDPA)
  // ═══════════════════════════════════════════════════════════════
  String get privacyPolicyTitle => isThai ? 'นโยบายความเป็นส่วนตัว' : 'Privacy Policy';
  String get privacyPolicySubtitle => 'Privacy Policy — PDPA Compliance';
  String get effectiveDate => isThai ? 'มีผลบังคับใช้: 1 เมษายน 2569' : 'Effective: April 1, 2026';
  String get pdpaSec1Title => isThai ? '1. บทนำ' : '1. Introduction';
  String get pdpaSec1Content => isThai
      ? 'คลินิกของเรา ("คลินิก") ให้ความสำคัญกับการคุ้มครองข้อมูลส่วนบุคคลของท่าน '
        'ตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA) '
        'นโยบายฉบับนี้อธิบายวิธีที่เราเก็บรวบรวม ใช้ เปิดเผย และคุ้มครองข้อมูลส่วนบุคคลของท่าน '
        'เมื่อท่านใช้บริการของคลินิกผ่านแอปพลิเคชัน airaMD'
      : 'Our clinic values the protection of your personal data '
        'in accordance with the Personal Data Protection Act B.E. 2562 (PDPA). '
        'This policy explains how we collect, use, disclose, and protect your personal data '
        'when you use our clinic services through the airaMD application.';
  String get pdpaSec2Title => isThai ? '2. ข้อมูลที่เราเก็บรวบรวม' : '2. Data We Collect';
  List<String> get pdpaSec2Bullets => isThai
      ? [
          'ข้อมูลส่วนตัว: ชื่อ-นามสกุล, วันเกิด, เพศ, เลขบัตรประชาชน, หมายเลขหนังสือเดินทาง',
          'ข้อมูลติดต่อ: เบอร์โทรศัพท์, LINE ID, WhatsApp, อีเมล, ที่อยู่',
          'ข้อมูลสุขภาพ: ประวัติการแพ้ยา, โรคประจำตัว, การใช้ยา, ประวัติการรักษา (SOAP Notes)',
          'ข้อมูลชีวมิติ: ลายเซ็นดิจิทัล, รูปใบหน้า (Before/After), ไดอะแกรมการรักษา',
          'ข้อมูลการเงิน: ประวัติการชำระเงิน, คอร์สที่ซื้อ, ยอดค้างชำระ',
          'ข้อมูลการใช้แอป: บันทึกการเข้าสู่ระบบ, กิจกรรมในแอป (Audit Logs)',
        ]
      : [
          'Personal data: Name, date of birth, gender, national ID, passport number',
          'Contact data: Phone, LINE ID, WhatsApp, email, address',
          'Health data: Drug allergies, medical conditions, medications, treatment records (SOAP Notes)',
          'Biometric data: Digital signatures, facial photos (Before/After), treatment diagrams',
          'Financial data: Payment history, purchased courses, outstanding balance',
          'Usage data: Login records, in-app activity (Audit Logs)',
        ];
  String get pdpaSec3Title => isThai ? '3. วัตถุประสงค์ในการใช้ข้อมูล' : '3. Purpose of Data Use';
  List<String> get pdpaSec3Bullets => isThai
      ? [
          'ให้บริการทางการแพทย์และเสริมความงาม',
          'จัดทำเวชระเบียนและบันทึกการรักษา',
          'นัดหมายและแจ้งเตือนผ่าน LINE / WhatsApp',
          'ติดตามผลการรักษาด้วยรูป Before/After',
          'จัดการคอร์สการรักษาและการเงิน',
          'ปฏิบัติตามกฎหมายที่เกี่ยวข้อง',
          'ปรับปรุงคุณภาพการบริการ',
        ]
      : [
          'Provide medical and aesthetic services',
          'Maintain medical records and treatment history',
          'Appointment reminders via LINE / WhatsApp',
          'Track treatment results with Before/After photos',
          'Manage treatment courses and finances',
          'Comply with applicable laws',
          'Improve service quality',
        ];
  String get pdpaSec4Title => isThai ? '4. การเปิดเผยข้อมูล' : '4. Data Disclosure';
  String get pdpaSec4Content => isThai
      ? 'เราจะไม่เปิดเผยข้อมูลส่วนบุคคลของท่านแก่บุคคลภายนอก ยกเว้นกรณีดังนี้:'
      : 'We will not disclose your personal data to third parties except in the following cases:';
  List<String> get pdpaSec4Bullets => isThai
      ? [
          'ได้รับความยินยอมจากท่าน',
          'ตามคำสั่งศาลหรือหน่วยงานราชการที่มีอำนาจ',
          'เพื่อปกป้องชีวิต สุขภาพ หรือผลประโยชน์ที่สำคัญ',
          'ผู้ให้บริการเทคโนโลยี (Supabase) ที่ปฏิบัติตามมาตรฐานความปลอดภัยสากล',
        ]
      : [
          'With your consent',
          'By court order or authorized government agencies',
          'To protect life, health, or critical interests',
          'Technology providers (Supabase) complying with international security standards',
        ];
  String get pdpaSec5Title => isThai ? '5. มาตรการรักษาความปลอดภัย' : '5. Security Measures';
  List<String> get pdpaSec5Bullets => isThai
      ? [
          'การเข้ารหัสข้อมูลระหว่างส่งและจัดเก็บ (HTTPS/TLS + Encryption at rest)',
          'ระบบยืนยันตัวตน: PIN Lock + สแกนลายนิ้วมือ/Face ID',
          'การควบคุมสิทธิ์การเข้าถึงตามบทบาท (RBAC)',
          'Row-Level Security (RLS) ในระดับฐานข้อมูล',
          'บันทึกตรวจสอบ (Audit Logs) สำหรับการเปลี่ยนแปลงข้อมูลสำคัญ',
          'การสำรองข้อมูลอัตโนมัติผ่าน Supabase',
        ]
      : [
          'Data encryption in transit and at rest (HTTPS/TLS + Encryption at rest)',
          'Authentication: PIN Lock + Fingerprint/Face ID',
          'Role-Based Access Control (RBAC)',
          'Row-Level Security (RLS) at the database level',
          'Audit Logs for critical data changes',
          'Automatic backups via Supabase',
        ];
  String get pdpaSec6Title => isThai ? '6. ระยะเวลาการเก็บรักษาข้อมูล' : '6. Data Retention Period';
  String get pdpaSec6Content => isThai
      ? 'เราเก็บรักษาข้อมูลส่วนบุคคลตลอดระยะเวลาที่ท่านเป็นผู้รับบริการของคลินิก '
        'และเก็บต่อไปอีกไม่น้อยกว่า 10 ปี ตามกฎหมายว่าด้วยเวชระเบียน '
        'หลังพ้นกำหนด ข้อมูลจะถูกลบหรือทำให้ไม่สามารถระบุตัวตนได้'
      : 'We retain your personal data for the duration of your service at our clinic '
        'and for at least 10 years thereafter as required by medical records law. '
        'After the retention period, data will be deleted or anonymized.';
  String get pdpaSec7Title => isThai ? '7. สิทธิของเจ้าของข้อมูล' : '7. Data Subject Rights';
  String get pdpaSec7Content => isThai ? 'ท่านมีสิทธิตาม PDPA ดังนี้:' : 'You have the following rights under PDPA:';
  List<String> get pdpaSec7Bullets => isThai
      ? [
          'สิทธิในการเข้าถึง: ขอดูข้อมูลส่วนบุคคลของท่าน',
          'สิทธิในการแก้ไข: ขอแก้ไขข้อมูลให้ถูกต้องและเป็นปัจจุบัน',
          'สิทธิในการลบ: ขอลบข้อมูล (ภายใต้ข้อจำกัดทางกฎหมาย)',
          'สิทธิในการระงับ: ขอระงับการใช้ข้อมูลชั่วคราว',
          'สิทธิในการคัดค้าน: คัดค้านการใช้ข้อมูลในบางกรณี',
          'สิทธิในการโอนย้าย: ขอรับข้อมูลในรูปแบบที่อ่านได้ด้วยเครื่อง',
          'สิทธิในการถอนความยินยอม: ถอนความยินยอมได้ทุกเมื่อ',
        ]
      : [
          'Right of access: Request to view your personal data',
          'Right of rectification: Request corrections to your data',
          'Right of erasure: Request deletion (subject to legal limitations)',
          'Right of restriction: Request temporary suspension of data use',
          'Right to object: Object to data use in certain cases',
          'Right of portability: Receive data in a machine-readable format',
          'Right to withdraw consent: Withdraw consent at any time',
        ];
  String get pdpaSec8Title => isThai ? '8. ข้อมูลผู้เยาว์' : '8. Minors';
  String get pdpaSec8Content => isThai
      ? 'หากท่านมีอายุต่ำกว่า 20 ปี การเก็บรวบรวมข้อมูลของท่านจะต้องได้รับความยินยอม '
        'จากผู้ปกครองหรือผู้แทนโดยชอบธรรมก่อน'
      : 'If you are under 20 years of age, data collection requires consent '
        'from your parent or legal guardian.';
  String get pdpaSec9Title => isThai ? '9. การเปลี่ยนแปลงนโยบาย' : '9. Policy Changes';
  String get pdpaSec9Content => isThai
      ? 'คลินิกอาจปรับปรุงนโยบายฉบับนี้เป็นครั้งคราว โดยจะแจ้งให้ท่านทราบผ่านแอปพลิเคชัน '
        'หรือช่องทางการติดต่อของท่าน การใช้บริการต่อหลังการเปลี่ยนแปลง '
        'ถือว่าท่านยอมรับนโยบายที่ปรับปรุงแล้ว'
      : 'The clinic may update this policy from time to time. We will notify you via the application '
        'or your contact channels. Continued use after changes constitutes acceptance of the updated policy.';
  String get pdpaSec10Title => isThai ? '10. ช่องทางการติดต่อ' : '10. Contact';
  String get pdpaSec10Content => isThai
      ? 'หากท่านมีคำถามเกี่ยวกับนโยบายฉบับนี้ หรือต้องการใช้สิทธิตาม PDPA '
        'กรุณาติดต่อเจ้าหน้าที่คุ้มครองข้อมูลส่วนบุคคล (DPO) ของคลินิก '
        'ผ่านช่องทางที่ระบุในหน้าตั้งค่าของแอปพลิเคชัน'
      : 'If you have questions about this policy or wish to exercise your PDPA rights, '
        'please contact the clinic\'s Data Protection Officer (DPO) '
        'through the channels listed in the app settings.';
  String get pdpaFooter => isThai
      ? 'airaMD ปฏิบัติตาม พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA)\nข้อมูลของท่านได้รับการเข้ารหัสและจัดเก็บอย่างปลอดภัย'
      : 'airaMD complies with the Personal Data Protection Act B.E. 2562 (PDPA)\nYour data is encrypted and stored securely.';
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
