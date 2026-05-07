import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

class InventoryRepository extends BaseRepository {
  InventoryRepository(SupabaseClient client)
      : super(client, 'inventory_transactions');

  Future<List<InventoryTransaction>> list({
    required String clinicId,
    String orderBy = 'created_at',
    bool ascending = false,
    int? limit,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: orderBy,
      ascending: ascending,
      limit: limit,
    );
    return data.map(InventoryTransaction.fromJson).toList();
  }

  Future<InventoryTransaction> create(InventoryTransaction tx) async {
    final data = await insert(tx.toInsertJson());
    return InventoryTransaction.fromJson(data);
  }

  /// Get transactions for a specific product.
  Future<List<InventoryTransaction>> getByProduct({
    required String productId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(InventoryTransaction.fromJson).toList();
  }

  /// Record stock-in and update product stock.
  Future<InventoryTransaction> stockIn({
    required String clinicId,
    required String productId,
    required double quantity,
    String? batchNo,
    DateTime? expiryDate,
    String? createdBy,
    String? notes,
  }) async {
    final tx = InventoryTransaction(
      id: '',
      clinicId: clinicId,
      productId: productId,
      transactionType: InventoryTransactionType.stockIn,
      quantity: quantity,
      batchNo: batchNo,
      expiryDate: expiryDate,
      createdBy: createdBy,
      notes: notes,
    );
    return create(tx);
  }

  /// Atomic ledger + stock-quantity update backed by the
  /// `apply_inventory_adjustment` RPC (migration 014).
  ///
  /// Returns the resulting `stock_quantity` so callers can reconcile
  /// their local cache without a follow-up fetch.
  ///
  /// Throws:
  ///   * [InvalidQuantityException] — quantity is null/negative.
  ///   * [InsufficientStockException] — USED/WASTAGE would take stock < 0.
  ///   * [NotFoundException] — product id doesn't exist.
  ///   * [UnknownRepositoryException] — any other Postgres error.
  Future<double> applyAdjustment({
    required String productId,
    required InventoryTransactionType transactionType,
    required double quantity,
    String? unit,
    String? batchNo,
    DateTime? expiryDate,
    String? notes,
    String? createdBy,
  }) async {
    try {
      final result = await client.rpc(
        'apply_inventory_adjustment',
        params: {
          'p_product_id': productId,
          'p_transaction_type': transactionType.dbValue,
          'p_quantity': quantity,
          'p_unit': unit,
          'p_batch_no': batchNo,
          'p_expiry_date': expiryDate?.toIso8601String().split('T').first,
          'p_notes': notes,
          'p_created_by': createdBy,
        },
      );
      if (result == null) return 0;
      return (result as num).toDouble();
    } on PostgrestException catch (e) {
      // Map server-side SQLSTATEs to typed exceptions so the UI can
      // localise messages without parsing English prose.
      if (e.message.contains('insufficient_stock')) {
        throw const InsufficientStockException();
      }
      if (e.message.contains('quantity must be') ||
          e.message.contains('invalid transaction_type')) {
        throw const InvalidQuantityException();
      }
      if (e.code == 'P0002' || e.message.contains('not found')) {
        throw const NotFoundException('product');
      }
      throw UnknownRepositoryException(e.message, e);
    }
  }
}
