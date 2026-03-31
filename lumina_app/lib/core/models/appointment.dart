import 'enums.dart';

class Appointment {
  final String id;
  final String clinicId;
  final String patientId;
  final String? doctorId;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final AppointmentStatus status;
  final String? treatmentType;
  final String? notes;
  final bool reminderSent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.doctorId,
    required this.date,
    required this.startTime,
    this.endTime,
    this.status = AppointmentStatus.newAppt,
    this.treatmentType,
    this.notes,
    this.reminderSent = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        doctorId: json['doctor_id'] as String?,
        date: DateTime.parse(json['date'].toString()),
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String?,
        status: AppointmentStatus.fromDb(json['status'] as String?),
        treatmentType: json['treatment_type'] as String?,
        notes: json['notes'] as String?,
        reminderSent: json['reminder_sent'] as bool? ?? false,
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
        'date': date.toIso8601String().split('T').first,
        'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        'status': status.dbValue,
        if (treatmentType != null) 'treatment_type': treatmentType,
        if (notes != null) 'notes': notes,
        'reminder_sent': reminderSent,
      };

  Map<String, dynamic> toUpdateJson() => {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'date': date.toIso8601String().split('T').first,
        'start_time': startTime,
        'end_time': endTime,
        'status': status.dbValue,
        'treatment_type': treatmentType,
        'notes': notes,
        'reminder_sent': reminderSent,
      };

  Appointment copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? doctorId,
    DateTime? date,
    String? startTime,
    String? endTime,
    AppointmentStatus? status,
    String? treatmentType,
    String? notes,
    bool? reminderSent,
  }) =>
      Appointment(
        id: id ?? this.id,
        clinicId: clinicId ?? this.clinicId,
        patientId: patientId ?? this.patientId,
        doctorId: doctorId ?? this.doctorId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        treatmentType: treatmentType ?? this.treatmentType,
        notes: notes ?? this.notes,
        reminderSent: reminderSent ?? this.reminderSent,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
