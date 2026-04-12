import 'enums.dart';

class Service {
  final String id;
  final String clinicId;
  final String name;
  final ServiceCategory category;
  final double? defaultPrice;
  final DoctorFeeType doctorFeeType;
  final double? doctorFeeValue;
  final double? estimatedCost;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Service({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category = ServiceCategory.other,
    this.defaultPrice,
    this.doctorFeeType = DoctorFeeType.none,
    this.doctorFeeValue,
    this.estimatedCost,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        name: json['name'] as String,
        category: ServiceCategory.fromDb(json['category'] as String?),
        defaultPrice: (json['default_price'] as num?)?.toDouble(),
        doctorFeeType: DoctorFeeType.fromDb(json['doctor_fee_type'] as String?),
        doctorFeeValue: (json['doctor_fee_value'] as num?)?.toDouble(),
        estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'name': name,
        'category': category.dbValue,
        if (defaultPrice != null) 'default_price': defaultPrice,
        'doctor_fee_type': doctorFeeType.dbValue,
        if (doctorFeeValue != null) 'doctor_fee_value': doctorFeeValue,
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category.dbValue,
        'default_price': defaultPrice,
        'doctor_fee_type': doctorFeeType.dbValue,
        'doctor_fee_value': doctorFeeValue,
        'estimated_cost': estimatedCost,
        'is_active': isActive,
      };

  Service copyWith({
    String? id,
    String? clinicId,
    String? name,
    ServiceCategory? category,
    double? defaultPrice,
    DoctorFeeType? doctorFeeType,
    double? doctorFeeValue,
    double? estimatedCost,
    bool? isActive,
  }) =>
      Service(
        id: id ?? this.id,
        clinicId: clinicId ?? this.clinicId,
        name: name ?? this.name,
        category: category ?? this.category,
        defaultPrice: defaultPrice ?? this.defaultPrice,
        doctorFeeType: doctorFeeType ?? this.doctorFeeType,
        doctorFeeValue: doctorFeeValue ?? this.doctorFeeValue,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
