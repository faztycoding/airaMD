class CourseSession {
  final String id;
  final String clinicId;
  final String courseId;
  final int sessionNumber;
  final bool isBonus;
  final bool isUsed;
  final DateTime? usedDate;
  final String? treatmentRecordId;
  final DateTime? createdAt;

  const CourseSession({
    required this.id,
    required this.clinicId,
    required this.courseId,
    required this.sessionNumber,
    this.isBonus = false,
    this.isUsed = false,
    this.usedDate,
    this.treatmentRecordId,
    this.createdAt,
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) => CourseSession(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        courseId: json['course_id'] as String,
        sessionNumber: json['session_number'] as int,
        isBonus: json['is_bonus'] as bool? ?? false,
        isUsed: json['is_used'] as bool? ?? false,
        usedDate: json['used_date'] != null
            ? DateTime.tryParse(json['used_date'].toString())
            : null,
        treatmentRecordId: json['treatment_record_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'course_id': courseId,
        'session_number': sessionNumber,
        'is_bonus': isBonus,
        'is_used': isUsed,
        if (usedDate != null)
          'used_date': usedDate!.toIso8601String().split('T').first,
        if (treatmentRecordId != null) 'treatment_record_id': treatmentRecordId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'is_used': isUsed,
        'used_date': usedDate?.toIso8601String().split('T').first,
        'treatment_record_id': treatmentRecordId,
      };
}
