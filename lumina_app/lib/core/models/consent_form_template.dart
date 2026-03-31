class ConsentFormTemplate {
  final String id;
  final String clinicId;
  final String name;
  final String? category;
  final String content;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConsentFormTemplate({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category,
    required this.content,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ConsentFormTemplate.fromJson(Map<String, dynamic> json) =>
      ConsentFormTemplate(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        content: json['content'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'name': name,
        if (category != null) 'category': category,
        'content': content,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category,
        'content': content,
        'is_active': isActive,
      };
}
