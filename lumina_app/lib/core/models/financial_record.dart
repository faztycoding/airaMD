import 'enums.dart';

class FinancialRecord {
  final String id;
  final String clinicId;
  final String patientId;
  final String? treatmentRecordId;
  final String? courseId;
  final FinancialType type;
  final double amount;
  final PaymentMethod? paymentMethod;
  final String? description;
  final bool isOutstanding;
  final String? createdBy;
  final DateTime? createdAt;

  const FinancialRecord({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.treatmentRecordId,
    this.courseId,
    required this.type,
    required this.amount,
    this.paymentMethod,
    this.description,
    this.isOutstanding = false,
    this.createdBy,
    this.createdAt,
  });

  factory FinancialRecord.fromJson(Map<String, dynamic> json) =>
      FinancialRecord(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        treatmentRecordId: json['treatment_record_id'] as String?,
        courseId: json['course_id'] as String?,
        type: FinancialType.fromDb(json['type'] as String?),
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['payment_method'] != null
            ? PaymentMethod.fromDb(json['payment_method'] as String?)
            : null,
        description: json['description'] as String?,
        isOutstanding: json['is_outstanding'] as bool? ?? false,
        createdBy: json['created_by'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        if (treatmentRecordId != null) 'treatment_record_id': treatmentRecordId,
        if (courseId != null) 'course_id': courseId,
        'type': type.dbValue,
        'amount': amount,
        if (paymentMethod != null) 'payment_method': paymentMethod!.dbValue,
        if (description != null) 'description': description,
        'is_outstanding': isOutstanding,
        if (createdBy != null) 'created_by': createdBy,
      };
}
