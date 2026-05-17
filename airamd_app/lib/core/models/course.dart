import 'enums.dart';

class Course {
  final String id;
  final String clinicId;
  final String patientId;
  final String name;
  final String? serviceId;
  final double? price;
  final int sessionsBought;
  final int sessionsBonus;
  final int sessionsUsed;
  final int? sessionsTotal; // generated column — read-only
  final CourseStatus status;
  final DateTime? expiryDate;
  final String? notes;
  /// Treatment category — drives which products / devices are pickable.
  /// Mirrors TreatmentCategory.dbValue: 'injectable' | 'laser' | 'treatment'
  /// | 'anti_aging' | 'skincare' | 'other'.
  final String? treatmentCategory;
  /// Doctor responsible for course delivery. Optional.
  final String? responsibleDoctorId;
  /// JSON array of products consumed per session of this course.
  /// Format: [{ 'product_id': uuid, 'name': str, 'quantity': num }].
  final List<dynamic> productsUsed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Course({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.name,
    this.serviceId,
    this.price,
    this.sessionsBought = 1,
    this.sessionsBonus = 0,
    this.sessionsUsed = 0,
    this.sessionsTotal,
    this.status = CourseStatus.active,
    this.expiryDate,
    this.notes,
    this.treatmentCategory,
    this.responsibleDoctorId,
    this.productsUsed = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get sessionsRemaining =>
      (sessionsTotal ?? (sessionsBought + sessionsBonus)) - sessionsUsed;

  double get usagePercent {
    final total = sessionsTotal ?? (sessionsBought + sessionsBonus);
    if (total == 0) return 0;
    return sessionsUsed / total;
  }

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        name: json['name'] as String,
        serviceId: json['service_id'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        sessionsBought: json['sessions_bought'] as int? ?? 1,
        sessionsBonus: json['sessions_bonus'] as int? ?? 0,
        sessionsUsed: json['sessions_used'] as int? ?? 0,
        sessionsTotal: json['sessions_total'] as int?,
        status: CourseStatus.fromDb(json['status'] as String?),
        expiryDate: json['expiry_date'] != null
            ? DateTime.tryParse(json['expiry_date'].toString())
            : null,
        notes: json['notes'] as String?,
        treatmentCategory: json['treatment_category'] as String?,
        responsibleDoctorId: json['responsible_doctor_id'] as String?,
        productsUsed:
            (json['products_used'] as List<dynamic>?) ?? const [],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        'name': name,
        if (serviceId != null) 'service_id': serviceId,
        if (price != null) 'price': price,
        'sessions_bought': sessionsBought,
        'sessions_bonus': sessionsBonus,
        'sessions_used': sessionsUsed,
        // sessions_total is GENERATED — never insert
        'status': status.dbValue,
        if (expiryDate != null)
          'expiry_date': expiryDate!.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
        if (treatmentCategory != null) 'treatment_category': treatmentCategory,
        if (responsibleDoctorId != null)
          'responsible_doctor_id': responsibleDoctorId,
        'products_used': productsUsed,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'service_id': serviceId,
        'price': price,
        'sessions_bought': sessionsBought,
        'sessions_bonus': sessionsBonus,
        'sessions_used': sessionsUsed,
        'status': status.dbValue,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'notes': notes,
        'treatment_category': treatmentCategory,
        'responsible_doctor_id': responsibleDoctorId,
        'products_used': productsUsed,
      };
}
