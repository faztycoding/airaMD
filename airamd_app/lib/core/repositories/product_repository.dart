import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '_helpers.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

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
  ///
  /// User input is sanitised through `escape_like` to neutralise `%` `_` `\`
  /// wildcard injection that would otherwise let an attacker exfiltrate a
  /// whole clinic's product list with a single character.
  Future<List<Product>> searchProducts({
    required String clinicId,
    required String query,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return list(clinicId: clinicId);

    final escaped = escapeLike(trimmed);
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .or('name.ilike.%$escaped%,brand.ilike.%$escaped%')
        .eq('is_active', true)
        .order('name', ascending: true)
        .limit(limit);

    return data.map(Product.fromJson).toList();
  }

  // ───────────────────────────────────────────────────────────────
  // Stock mutation
  // ───────────────────────────────────────────────────────────────

  /// Deduct stock after treatment usage.
  ///
  /// Uses the `deduct_stock_atomic` Postgres RPC introduced in migration 009
  /// so two concurrent treatments using the same product can never produce
  /// negative stock. Throws [InvalidQuantityException] /
  /// [InsufficientStockException] / [NotFoundException] instead of bare
  /// `Exception` so callers can switch on the failure mode.
  Future<Product> deductStock(String productId, double quantity) async {
    if (quantity <= 0) {
      throw const InvalidQuantityException();
    }

    try {
      // The RPC performs the read-modify-write inside one statement using
      // `UPDATE ... WHERE stock_quantity >= $qty` so it is race-free even
      // under concurrent calls.
      await client.rpc(
        'deduct_stock_atomic',
        params: {
          'p_product_id': productId,
          'p_quantity': quantity,
        },
      );
    } on PostgrestException catch (e) {
      // Postgres SQLSTATE / message dispatch — see migration 009.
      if (e.message.contains('insufficient_stock')) {
        // Look up the product name once for a friendlier UI message.
        final fallback = await get(productId);
        throw InsufficientStockException(
          productName: fallback?.name,
          cause: e,
        );
      }
      if (e.message.contains('quantity_must_be_positive')) {
        throw InvalidQuantityException(e);
      }
      rethrow;
    }

    // Refetch so callers receive the canonical post-update Product row.
    final updated = await get(productId);
    if (updated == null) {
      throw const NotFoundException('product');
    }
    return updated;
  }
}
