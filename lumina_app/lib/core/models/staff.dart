import 'enums.dart';

class Staff {
  final String id;
  final String clinicId;
  final String? userId;
  final String fullName;
  final String? nickname;
  final StaffRole role;
  final double? baseSalary;
  final bool isActive;
  final String? pinHash;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Staff({
    required this.id,
    required this.clinicId,
    this.userId,
    required this.fullName,
    this.nickname,
    this.role = StaffRole.doctor,
    this.baseSalary,
    this.isActive = true,
    this.pinHash,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        userId: json['user_id'] as String?,
        fullName: json['full_name'] as String,
        nickname: json['nickname'] as String?,
        role: StaffRole.fromDb(json['role'] as String?),
        baseSalary: (json['base_salary'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? true,
        pinHash: json['pin_hash'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        if (userId != null) 'user_id': userId,
        'full_name': fullName,
        if (nickname != null) 'nickname': nickname,
        'role': role.dbValue,
        if (baseSalary != null) 'base_salary': baseSalary,
        'is_active': isActive,
        if (pinHash != null) 'pin_hash': pinHash,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'nickname': nickname,
        'role': role.dbValue,
        'base_salary': baseSalary,
        'is_active': isActive,
        'pin_hash': pinHash,
        'avatar_url': avatarUrl,
      };

  Staff copyWith({
    String? id,
    String? clinicId,
    String? userId,
    String? fullName,
    String? nickname,
    StaffRole? role,
    double? baseSalary,
    bool? isActive,
    String? pinHash,
    String? avatarUrl,
  }) =>
      Staff(
        id: id ?? this.id,
        clinicId: clinicId ?? this.clinicId,
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        nickname: nickname ?? this.nickname,
        role: role ?? this.role,
        baseSalary: baseSalary ?? this.baseSalary,
        isActive: isActive ?? this.isActive,
        pinHash: pinHash ?? this.pinHash,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
