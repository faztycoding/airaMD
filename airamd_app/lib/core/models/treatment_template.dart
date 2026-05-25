import '../repositories/_helpers.dart';
import 'enums.dart';

/// Reusable preset that pre-fills the treatment form for common
/// combo procedures (e.g. "Acne Scar Combo", "Midface Filler").
///
/// Backed by the `treatment_templates` table introduced in
/// migration 023 (Phase 5E, May 25 2026).
class TreatmentTemplate {
  final String id;
  final String clinicId;
  final String name;
  final TreatmentCategory category;
  final String? description;

  /// Suggested products, each entry shaped like
  /// `{name, brand?, quantity, unit}`.
  final List<dynamic> suggestedProducts;

  /// Names of services that this combo typically includes — matched
  /// against the `services.name` column when the template is applied.
  final List<String> suggestedServices;

  /// Pre-filled patient instructions (one per element).
  final List<String> defaultInstructions;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TreatmentTemplate({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category = TreatmentCategory.treatment,
    this.description,
    this.suggestedProducts = const [],
    this.suggestedServices = const [],
    this.defaultInstructions = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TreatmentTemplate.fromJson(Map<String, dynamic> json) {
    final svc = json['suggested_services'];
    return TreatmentTemplate(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      name: json['name'] as String,
      category: TreatmentCategory.fromDb(json['category'] as String?),
      description: json['description'] as String?,
      suggestedProducts:
          (json['suggested_products'] as List<dynamic>?) ?? const [],
      suggestedServices: svc is List
          ? svc.map((e) => e.toString()).toList()
          : parseStringList(svc),
      defaultInstructions: parseStringList(json['default_instructions']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'name': name,
        'category': category.dbValue,
        if (description != null) 'description': description,
        'suggested_products': suggestedProducts,
        'suggested_services': suggestedServices,
        'default_instructions': defaultInstructions,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category.dbValue,
        'description': description,
        'suggested_products': suggestedProducts,
        'suggested_services': suggestedServices,
        'default_instructions': defaultInstructions,
        'is_active': isActive,
      };

  TreatmentTemplate copyWith({
    String? name,
    TreatmentCategory? category,
    String? description,
    List<dynamic>? suggestedProducts,
    List<String>? suggestedServices,
    List<String>? defaultInstructions,
    bool? isActive,
  }) =>
      TreatmentTemplate(
        id: id,
        clinicId: clinicId,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        suggestedProducts: suggestedProducts ?? this.suggestedProducts,
        suggestedServices: suggestedServices ?? this.suggestedServices,
        defaultInstructions: defaultInstructions ?? this.defaultInstructions,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
