class Clinic {
  final String id;
  final String name;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? lineOaId;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Clinic({
    required this.id,
    required this.name,
    this.logoUrl,
    this.address,
    this.phone,
    this.lineOaId,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) => Clinic(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        lineOaId: json['line_oa_id'] as String?,
        settings: (json['settings'] as Map<String, dynamic>?) ?? {},
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (lineOaId != null) 'line_oa_id': lineOaId,
        'settings': settings,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'logo_url': logoUrl,
        'address': address,
        'phone': phone,
        'line_oa_id': lineOaId,
        'settings': settings,
      };

  Clinic copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? address,
    String? phone,
    String? lineOaId,
    Map<String, dynamic>? settings,
  }) =>
      Clinic(
        id: id ?? this.id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        lineOaId: lineOaId ?? this.lineOaId,
        settings: settings ?? this.settings,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
