import 'enums.dart';

class Product {
  final String id;
  final String clinicId;
  final String name;
  final String? brand;
  final ProductCategory category;
  final String unit;
  final double? unitCost;
  final double? defaultPrice;
  final double stockQuantity;
  final double? stockPerContainer;
  final int? minStockAlert;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.clinicId,
    required this.name,
    this.brand,
    this.category = ProductCategory.other,
    this.unit = 'U',
    this.unitCost,
    this.defaultPrice,
    this.stockQuantity = 0,
    this.stockPerContainer,
    this.minStockAlert,
    this.expiryDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock =>
      minStockAlert != null && stockQuantity <= minStockAlert!;

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        category: ProductCategory.fromDb(json['category'] as String?),
        unit: json['unit'] as String? ?? 'U',
        unitCost: (json['unit_cost'] as num?)?.toDouble(),
        defaultPrice: (json['default_price'] as num?)?.toDouble(),
        stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0,
        stockPerContainer:
            (json['stock_per_container'] as num?)?.toDouble(),
        minStockAlert: json['min_stock_alert'] as int?,
        expiryDate: json['expiry_date'] != null
            ? DateTime.tryParse(json['expiry_date'].toString())
            : null,
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
        if (brand != null) 'brand': brand,
        'category': category.dbValue,
        'unit': unit,
        if (unitCost != null) 'unit_cost': unitCost,
        if (defaultPrice != null) 'default_price': defaultPrice,
        'stock_quantity': stockQuantity,
        if (stockPerContainer != null) 'stock_per_container': stockPerContainer,
        if (minStockAlert != null) 'min_stock_alert': minStockAlert,
        if (expiryDate != null)
          'expiry_date': expiryDate!.toIso8601String().split('T').first,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'brand': brand,
        'category': category.dbValue,
        'unit': unit,
        'unit_cost': unitCost,
        'default_price': defaultPrice,
        'stock_quantity': stockQuantity,
        'stock_per_container': stockPerContainer,
        'min_stock_alert': minStockAlert,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'is_active': isActive,
      };

  Product copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? brand,
    ProductCategory? category,
    String? unit,
    double? unitCost,
    double? defaultPrice,
    double? stockQuantity,
    double? stockPerContainer,
    int? minStockAlert,
    DateTime? expiryDate,
    bool? isActive,
  }) =>
      Product(
        id: id ?? this.id,
        clinicId: clinicId ?? this.clinicId,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        unitCost: unitCost ?? this.unitCost,
        defaultPrice: defaultPrice ?? this.defaultPrice,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        stockPerContainer: stockPerContainer ?? this.stockPerContainer,
        minStockAlert: minStockAlert ?? this.minStockAlert,
        expiryDate: expiryDate ?? this.expiryDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
