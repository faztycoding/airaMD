import 'enums.dart';

class TreatmentRecord {
  final String id;
  final String clinicId;
  final String patientId;
  final String? doctorId;
  final String? appointmentId;
  final DateTime date;
  final TreatmentCategory category;
  final String treatmentName;
  final String? chiefComplaint;
  final String? objective;
  final String? assessment;
  final String? plan;
  final Map<String, dynamic> vitals;
  final String? device;
  final String? energy;
  final String? pulseSpot;
  final String? totalShots;
  final List<dynamic> productsUsed;
  final double? actualUnitsUsed;
  final TreatmentResponse responseToPrevious;
  final List<String> adverseEvents;
  final List<String> instructions;
  final DateTime? followUpDate;
  final String? followUpTime;
  final String? diagramUrl;
  final String? notes;
  final CommissionStatus commissionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TreatmentRecord({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.doctorId,
    this.appointmentId,
    required this.date,
    this.category = TreatmentCategory.other,
    required this.treatmentName,
    this.chiefComplaint,
    this.objective,
    this.assessment,
    this.plan,
    this.vitals = const {},
    this.device,
    this.energy,
    this.pulseSpot,
    this.totalShots,
    this.productsUsed = const [],
    this.actualUnitsUsed,
    this.responseToPrevious = TreatmentResponse.notApplicable,
    this.adverseEvents = const [],
    this.instructions = const [],
    this.followUpDate,
    this.followUpTime,
    this.diagramUrl,
    this.notes,
    this.commissionStatus = CommissionStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory TreatmentRecord.fromJson(Map<String, dynamic> json) =>
      TreatmentRecord(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        doctorId: json['doctor_id'] as String?,
        appointmentId: json['appointment_id'] as String?,
        date: DateTime.parse(json['date'].toString()),
        category: TreatmentCategory.fromDb(json['category'] as String?),
        treatmentName: json['treatment_name'] as String,
        chiefComplaint: json['chief_complaint'] as String?,
        objective: json['objective'] as String?,
        assessment: json['assessment'] as String?,
        plan: json['plan'] as String?,
        vitals: (json['vitals'] as Map<String, dynamic>?) ?? {},
        device: json['device'] as String?,
        energy: json['energy'] as String?,
        pulseSpot: json['pulse_spot'] as String?,
        totalShots: json['total_shots'] as String?,
        productsUsed: (json['products_used'] as List<dynamic>?) ?? [],
        actualUnitsUsed: (json['actual_units_used'] as num?)?.toDouble(),
        responseToPrevious: TreatmentResponse.fromDb(
            json['response_to_previous'] as String?),
        adverseEvents: _parseStringList(json['adverse_events']),
        instructions: _parseStringList(json['instructions']),
        followUpDate: json['follow_up_date'] != null
            ? DateTime.tryParse(json['follow_up_date'].toString())
            : null,
        followUpTime: json['follow_up_time'] as String?,
        diagramUrl: json['diagram_url'] as String?,
        notes: json['notes'] as String?,
        commissionStatus:
            CommissionStatus.fromDb(json['commission_status'] as String?),
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
        if (doctorId != null) 'doctor_id': doctorId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        'date': date.toIso8601String(),
        'category': category.dbValue,
        'treatment_name': treatmentName,
        if (chiefComplaint != null) 'chief_complaint': chiefComplaint,
        if (objective != null) 'objective': objective,
        if (assessment != null) 'assessment': assessment,
        if (plan != null) 'plan': plan,
        'vitals': vitals,
        if (device != null) 'device': device,
        if (energy != null) 'energy': energy,
        if (pulseSpot != null) 'pulse_spot': pulseSpot,
        if (totalShots != null) 'total_shots': totalShots,
        'products_used': productsUsed,
        if (actualUnitsUsed != null) 'actual_units_used': actualUnitsUsed,
        'response_to_previous': responseToPrevious.dbValue,
        'adverse_events': adverseEvents,
        'instructions': instructions,
        if (followUpDate != null)
          'follow_up_date':
              followUpDate!.toIso8601String().split('T').first,
        if (followUpTime != null) 'follow_up_time': followUpTime,
        if (diagramUrl != null) 'diagram_url': diagramUrl,
        if (notes != null) 'notes': notes,
        'commission_status': commissionStatus.dbValue,
      };

  Map<String, dynamic> toUpdateJson() => {
        'doctor_id': doctorId,
        'category': category.dbValue,
        'treatment_name': treatmentName,
        'chief_complaint': chiefComplaint,
        'objective': objective,
        'assessment': assessment,
        'plan': plan,
        'vitals': vitals,
        'device': device,
        'energy': energy,
        'pulse_spot': pulseSpot,
        'total_shots': totalShots,
        'products_used': productsUsed,
        'actual_units_used': actualUnitsUsed,
        'response_to_previous': responseToPrevious.dbValue,
        'adverse_events': adverseEvents,
        'instructions': instructions,
        'follow_up_date': followUpDate?.toIso8601String().split('T').first,
        'follow_up_time': followUpTime,
        'diagram_url': diagramUrl,
        'notes': notes,
        'commission_status': commissionStatus.dbValue,
      };

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
