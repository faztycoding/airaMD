import 'enums.dart';

class StaffSchedule {
  final String id;
  final String clinicId;
  final String staffId;
  final DateTime date;
  final ScheduleStatus status;
  final String? startTime;
  final String? endTime;
  final String? note;
  final DateTime? createdAt;

  const StaffSchedule({
    required this.id,
    required this.clinicId,
    required this.staffId,
    required this.date,
    this.status = ScheduleStatus.onDuty,
    this.startTime,
    this.endTime,
    this.note,
    this.createdAt,
  });

  factory StaffSchedule.fromJson(Map<String, dynamic> json) => StaffSchedule(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        staffId: json['staff_id'] as String,
        date: DateTime.parse(json['date'].toString()),
        status: ScheduleStatus.fromDb(json['status'] as String?),
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        note: json['note'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'staff_id': staffId,
        'date': date.toIso8601String().split('T').first,
        'status': status.dbValue,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (note != null) 'note': note,
      };

  Map<String, dynamic> toUpdateJson() => {
        'status': status.dbValue,
        'start_time': startTime,
        'end_time': endTime,
        'note': note,
      };
}
