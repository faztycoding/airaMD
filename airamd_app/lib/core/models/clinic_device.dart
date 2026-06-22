/// A clinic-managed device / machine (e.g. Ulthera Prime, Ultraformer III,
/// Oligio) used as a quick-pick preset in the treatment form.
class ClinicDevice {
  final String id;
  final String clinicId;
  final String name;
  final String category; // mirrors TreatmentCategory.dbValue, default LASER
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClinicDevice({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category = 'LASER',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ClinicDevice.fromJson(Map<String, dynamic> json) => ClinicDevice(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'LASER',
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'name': name,
        'category': category,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category,
        'is_active': isActive,
      };

  ClinicDevice copyWith({
    String? name,
    String? category,
    bool? isActive,
  }) =>
      ClinicDevice(
        id: id,
        clinicId: clinicId,
        name: name ?? this.name,
        category: category ?? this.category,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
