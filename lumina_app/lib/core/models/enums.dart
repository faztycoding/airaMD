// All database enums mapped to Dart enums with DB string conversion.
// Each enum value carries its exact PostgreSQL string via [dbValue].

// ─── Staff ───────────────────────────────────────────────────

enum StaffRole {
  owner('OWNER'),
  doctor('DOCTOR'),
  receptionist('RECEPTIONIST');

  final String dbValue;
  const StaffRole(this.dbValue);
  static StaffRole fromDb(String? v) => StaffRole.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => StaffRole.doctor,
      );
}

enum ScheduleStatus {
  onDuty('ON_DUTY'),
  leave('LEAVE'),
  halfDay('HALF_DAY');

  final String dbValue;
  const ScheduleStatus(this.dbValue);
  static ScheduleStatus fromDb(String? v) => ScheduleStatus.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => ScheduleStatus.onDuty,
      );
}

// ─── Patient ─────────────────────────────────────────────────

enum GenderType {
  male('M'),
  female('F'),
  other('OTHER');

  final String dbValue;
  const GenderType(this.dbValue);
  static GenderType fromDb(String? v) => GenderType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => GenderType.other,
      );

  String label({bool isThai = true}) => switch (this) {
    GenderType.male => isThai ? 'ผู้ชาย' : 'Male',
    GenderType.female => isThai ? 'ผู้หญิง' : 'Female',
    GenderType.other => isThai ? 'อื่นๆ' : 'Other',
  };
}

enum SmokingType {
  none('NONE'),
  occasional('OCCASIONAL'),
  regular('REGULAR');

  final String dbValue;
  const SmokingType(this.dbValue);
  static SmokingType fromDb(String? v) => SmokingType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => SmokingType.none,
      );

  String label({bool isThai = true}) => switch (this) {
    SmokingType.none => isThai ? 'ไม่สูบ' : 'None',
    SmokingType.occasional => isThai ? 'สูบบ้าง' : 'Occasional',
    SmokingType.regular => isThai ? 'สูบประจำ' : 'Regular',
  };
}

enum AlcoholType {
  none('NONE'),
  occasional('OCCASIONAL'),
  regular('REGULAR');

  final String dbValue;
  const AlcoholType(this.dbValue);
  static AlcoholType fromDb(String? v) => AlcoholType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => AlcoholType.none,
      );

  String label({bool isThai = true}) => switch (this) {
    AlcoholType.none => isThai ? 'ไม่ดื่ม' : 'None',
    AlcoholType.occasional => isThai ? 'ดื่มบ้าง' : 'Occasional',
    AlcoholType.regular => isThai ? 'ดื่มประจำ' : 'Regular',
  };
}

enum PatientStatus {
  normal('NORMAL'),
  vip('VIP'),
  star('STAR');

  final String dbValue;
  const PatientStatus(this.dbValue);
  static PatientStatus fromDb(String? v) => PatientStatus.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => PatientStatus.normal,
      );
}

enum PreferredChannel {
  line('LINE'),
  facebook('FACEBOOK'),
  instagram('INSTAGRAM'),
  phone('PHONE'),
  none('NONE');

  final String dbValue;
  const PreferredChannel(this.dbValue);

  String label() => switch (this) {
        PreferredChannel.line => 'LINE',
        PreferredChannel.facebook => 'Facebook',
        PreferredChannel.instagram => 'Instagram',
        PreferredChannel.phone => 'โทรศัพท์',
        PreferredChannel.none => 'ไม่ระบุ',
      };

  static PreferredChannel fromDb(String? v) =>
      PreferredChannel.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => PreferredChannel.none,
      );
}

// ─── Appointment ─────────────────────────────────────────────

enum AppointmentStatus {
  newAppt('NEW'),
  confirmed('CONFIRMED'),
  followUp('FOLLOW_UP'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  noShow('NO_SHOW');

  final String dbValue;
  const AppointmentStatus(this.dbValue);
  static AppointmentStatus fromDb(String? v) =>
      AppointmentStatus.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => AppointmentStatus.newAppt,
      );
}

// ─── Service ─────────────────────────────────────────────────

enum ServiceCategory {
  ha('HA'),
  injectable('INJECTABLE'),
  laser('LASER'),
  treatment('TREATMENT'),
  other('OTHER');

  final String dbValue;
  const ServiceCategory(this.dbValue);
  static ServiceCategory fromDb(String? v) =>
      ServiceCategory.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => ServiceCategory.other,
      );
}

enum DoctorFeeType {
  fixedAmount('FIXED_AMOUNT'),
  percentage('PERCENTAGE'),
  none('NONE');

  final String dbValue;
  const DoctorFeeType(this.dbValue);
  static DoctorFeeType fromDb(String? v) => DoctorFeeType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => DoctorFeeType.none,
      );
}

// ─── Treatment ───────────────────────────────────────────────

enum TreatmentCategory {
  injectable('INJECTABLE'),
  laser('LASER'),
  treatment('TREATMENT'),
  other('OTHER');

  final String dbValue;
  const TreatmentCategory(this.dbValue);
  static TreatmentCategory fromDb(String? v) =>
      TreatmentCategory.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => TreatmentCategory.other,
      );
}

enum TreatmentResponse {
  improved('IMPROVED'),
  stable('STABLE'),
  worse('WORSE'),
  notApplicable('N_A');

  final String dbValue;
  const TreatmentResponse(this.dbValue);
  static TreatmentResponse fromDb(String? v) =>
      TreatmentResponse.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => TreatmentResponse.notApplicable,
      );
}

enum CommissionStatus {
  pending('PENDING'),
  paid('PAID');

  final String dbValue;
  const CommissionStatus(this.dbValue);
  static CommissionStatus fromDb(String? v) =>
      CommissionStatus.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => CommissionStatus.pending,
      );
}

// ─── Photo / Diagram ─────────────────────────────────────────

enum PhotoType {
  before('BEFORE'),
  after1m('AFTER_1M'),
  after3m('AFTER_3M'),
  after6m('AFTER_6M'),
  followUp('FOLLOW_UP'),
  other('OTHER');

  final String dbValue;
  const PhotoType(this.dbValue);
  static PhotoType fromDb(String? v) => PhotoType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => PhotoType.other,
      );
}

enum DiagramView {
  front('FRONT'),
  side('SIDE'),
  leftSide('LEFT_SIDE'),
  rightSide('RIGHT_SIDE'),
  lipZone('LIP_ZONE');

  final String dbValue;
  const DiagramView(this.dbValue);
  static DiagramView fromDb(String? v) => DiagramView.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => DiagramView.front,
      );
}

// ─── Product / Inventory ─────────────────────────────────────

enum ProductCategory {
  botox('BOTOX'),
  filler('FILLER'),
  biostimulator('BIOSTIMULATOR'),
  polynucleotide('POLYNUCLEOTIDE'),
  skinbooster('SKINBOOSTER'),
  laser('LASER'),
  other('OTHER');

  final String dbValue;
  const ProductCategory(this.dbValue);
  static ProductCategory fromDb(String? v) =>
      ProductCategory.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => ProductCategory.other,
      );
}

enum InventoryTransactionType {
  stockIn('STOCK_IN'),
  used('USED'),
  wastage('WASTAGE'),
  adjustment('ADJUSTMENT');

  final String dbValue;
  const InventoryTransactionType(this.dbValue);
  static InventoryTransactionType fromDb(String? v) =>
      InventoryTransactionType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => InventoryTransactionType.adjustment,
      );
}

// ─── Course ──────────────────────────────────────────────────

enum CourseStatus {
  active('ACTIVE'),
  low('LOW'),
  completed('COMPLETED'),
  expired('EXPIRED');

  final String dbValue;
  const CourseStatus(this.dbValue);
  static CourseStatus fromDb(String? v) => CourseStatus.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => CourseStatus.active,
      );
}

// ─── Financial ───────────────────────────────────────────────

enum FinancialType {
  charge('CHARGE'),
  payment('PAYMENT'),
  refund('REFUND'),
  adjustment('ADJUSTMENT');

  final String dbValue;
  const FinancialType(this.dbValue);
  static FinancialType fromDb(String? v) => FinancialType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => FinancialType.charge,
      );
}

enum PaymentMethod {
  cash('CASH'),
  transfer('TRANSFER'),
  creditCard('CREDIT_CARD'),
  debit('DEBIT'),
  other('OTHER');

  final String dbValue;
  const PaymentMethod(this.dbValue);
  static PaymentMethod fromDb(String? v) => PaymentMethod.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => PaymentMethod.cash,
      );
}

// ─── Messaging ───────────────────────────────────────────────

enum MessageChannel {
  line('LINE'),
  whatsapp('WHATSAPP');

  final String dbValue;
  const MessageChannel(this.dbValue);
  static MessageChannel fromDb(String? v) => MessageChannel.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => MessageChannel.line,
      );
}

enum MessageTemplateType {
  appointment('APPOINTMENT'),
  confirmation('CONFIRMATION'),
  afterCare('AFTER_CARE'),
  promotion('PROMOTION'),
  custom('CUSTOM');

  final String dbValue;
  const MessageTemplateType(this.dbValue);
  static MessageTemplateType fromDb(String? v) =>
      MessageTemplateType.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => MessageTemplateType.custom,
      );
}

enum MessageStatus {
  sent('SENT'),
  delivered('DELIVERED'),
  failed('FAILED'),
  pending('PENDING');

  final String dbValue;
  const MessageStatus(this.dbValue);
  static MessageStatus fromDb(String? v) => MessageStatus.values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => MessageStatus.pending,
      );
}
