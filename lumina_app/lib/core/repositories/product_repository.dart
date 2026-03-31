import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository {
  ProductRepository(SupabaseClient client) : super(client, 'products');

  Future<List<Product>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);

    if (activeOnly) query = query.eq('is_active', true);

    final data = await query.order('name', ascending: true);
    return data.map(Product.fromJson).toList();
  }

  Future<Product?> get(String id) async {
    final data = await getById(id);
    return data != null ? Product.fromJson(data) : null;
  }

  Future<Product> create(Product product) async {
    final data = await insert(product.toInsertJson());
    return Product.fromJson(data);
  }

  Future<Product> updateProduct(Product product) async {
    final data = await update(product.id, product.toUpdateJson());
    return Product.fromJson(data);
  }

  Future<void> deleteProduct(String id) => delete(id);

  /// Get products by category.
  Future<List<Product>> getByCategory({
    required String clinicId,
    required ProductCategory category,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('category', category.dbValue)
        .eq('is_active', true)
        .order('name', ascending: true);
    return data.map(Product.fromJson).toList();
  }

  /// Get products with low stock alerts.
  Future<List<Product>> getLowStock(String clinicId) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('is_active', true)
        .not('min_stock_alert', 'is', null)
        .order('stock_quantity', ascending: true);

    return data
        .map(Product.fromJson)
        .where((p) => p.isLowStock)
        .toList();
  }

  /// Search products by name or brand.
  Future<List<Product>> searchProducts({
    required String clinicId,
    required String query,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return list(clinicId: clinicId);

    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .or('name.ilike.%$trimmed%,brand.ilike.%$trimmed%')
        .eq('is_active', true)
        .order('name', ascending: true)
        .limit(limit);

    return data.map(Product.fromJson).toList();
  }

  /// Deduct stock after treatment usage.
  Future<Product> deductStock(String productId, double quantity) async {
    final product = await get(productId);
    if (product == null) throw Exception('Product not found');

    final newQty = product.stockQuantity - quantity;
    final data = await update(productId, {'stock_quantity': newQty});
    return Product.fromJson(data);
  }
}
