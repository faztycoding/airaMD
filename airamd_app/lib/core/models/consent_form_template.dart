class ConsentFormTemplate {
  final String id;
  final String clinicId;
  final String name;
  final String? category;
  final String content;
  final bool isActive;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConsentFormTemplate({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category,
    required this.content,
    this.isActive = true,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory ConsentFormTemplate.fromJson(Map<String, dynamic> json) =>
      ConsentFormTemplate(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        // Normalize legacy data: some older rows stored the literal two-char
        // sequence "\n" instead of a real newline, which broke line-based
        // rendering (editor, consent form, PDF, parseRiskItems).
        content: (json['content'] as String).replaceAll(r'\n', '\n'),
        isActive: json['is_active'] as bool? ?? true,
        version: json['version'] as int? ?? 1,
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
        'version': version,
      };

  ConsentFormTemplate copyWith({
    String? name,
    String? category,
    String? content,
    bool? isActive,
    int? version,
  }) =>
      ConsentFormTemplate(
        id: id,
        clinicId: clinicId,
        name: name ?? this.name,
        category: category ?? this.category,
        content: content ?? this.content,
        isActive: isActive ?? this.isActive,
        version: version ?? this.version,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
