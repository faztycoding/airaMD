class TreatmentRule {
  final String id;
  final String clinicId;
  final String treatmentType;
  final int repeatMinDays;
  final int repeatIdealDays;
  final List<String> contraindications;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TreatmentRule({
    required this.id,
    required this.clinicId,
    required this.treatmentType,
    this.repeatMinDays = 30,
    this.repeatIdealDays = 60,
    this.contraindications = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory TreatmentRule.fromJson(Map<String, dynamic> json) => TreatmentRule(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        treatmentType: json['treatment_type'] as String,
        repeatMinDays: json['repeat_min_days'] as int? ?? 30,
        repeatIdealDays: json['repeat_ideal_days'] as int? ?? 60,
        contraindications: _parseStringList(json['contraindications']),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'treatment_type': treatmentType,
        'repeat_min_days': repeatMinDays,
        'repeat_ideal_days': repeatIdealDays,
        'contraindications': contraindications,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'treatment_type': treatmentType,
        'repeat_min_days': repeatMinDays,
        'repeat_ideal_days': repeatIdealDays,
        'contraindications': contraindications,
        'notes': notes,
      };

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
