import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

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
}
