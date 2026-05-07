import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/repositories/inventory_op.dart';

void main() {
  group('InventoryOp.toJson', () {
    test('serialises only the keys the RPC understands, with snake_case', () {
      const op = InventoryOp(
        productId: 'prod-001',
        quantity: 1.5,
        unit: 'ml',
        notes: 'Auto-deduct: Filler',
        batchNo: 'B-2026-04',
        createdBy: 'user-uuid',
      );

      expect(op.toJson(), {
        'product_id': 'prod-001',
        'quantity': 1.5,
        'transaction_type': 'USED', // default
        'unit': 'ml',
        'batch_no': 'B-2026-04',
        'notes': 'Auto-deduct: Filler',
        'created_by': 'user-uuid',
      });
    });

    test('omits null optional fields so the RPC sees absent keys, not nulls',
        () {
      const op = InventoryOp(productId: 'p-1', quantity: 0.25);
      expect(op.toJson(), {
        'product_id': 'p-1',
        'quantity': 0.25,
        'transaction_type': 'USED',
      });
    });

    test('honours non-default transaction types (e.g. WASTAGE / STOCK_IN)', () {
      const wastage = InventoryOp(
        productId: 'p-1',
        quantity: 1.0,
        transactionType: InventoryTransactionType.wastage,
      );
      const stockIn = InventoryOp(
        productId: 'p-1',
        quantity: 5.0,
        transactionType: InventoryTransactionType.stockIn,
      );
      expect(wastage.toJson()['transaction_type'], 'WASTAGE');
      expect(stockIn.toJson()['transaction_type'], 'STOCK_IN');
    });
  });
}
