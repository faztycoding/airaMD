import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/features/settings/inventory_validation.dart';

void main() {
  group('Inventory quantity validation', () {
    test('returns invalid quantity for null, zero, or negative values', () {
      expect(
        validateInventoryQuantity(
          quantity: null,
          type: InventoryTransactionType.stockIn,
          availableStock: 10,
        ),
        InventoryQuantityValidationIssue.invalidQuantity,
      );
      expect(
        validateInventoryQuantity(
          quantity: 0,
          type: InventoryTransactionType.stockIn,
          availableStock: 10,
        ),
        InventoryQuantityValidationIssue.invalidQuantity,
      );
      expect(
        validateInventoryQuantity(
          quantity: -1,
          type: InventoryTransactionType.stockIn,
          availableStock: 10,
        ),
        InventoryQuantityValidationIssue.invalidQuantity,
      );
    });

    test('blocks used quantity that exceeds stock', () {
      expect(
        validateInventoryQuantity(
          quantity: 12,
          type: InventoryTransactionType.used,
          availableStock: 10,
        ),
        InventoryQuantityValidationIssue.insufficientStock,
      );
    });

    test('blocks wastage quantity that exceeds stock', () {
      expect(
        validateInventoryQuantity(
          quantity: 11,
          type: InventoryTransactionType.wastage,
          availableStock: 10,
        ),
        InventoryQuantityValidationIssue.insufficientStock,
      );
    });

    test('allows used quantity within available stock', () {
      expect(
        validateInventoryQuantity(
          quantity: 10,
          type: InventoryTransactionType.used,
          availableStock: 10,
        ),
        isNull,
      );
    });

    test('allows stock-in regardless of current stock', () {
      expect(
        validateInventoryQuantity(
          quantity: 100,
          type: InventoryTransactionType.stockIn,
          availableStock: 10,
        ),
        isNull,
      );
    });

    test('allows adjustment regardless of current stock (sets absolute value)', () {
      expect(
        validateInventoryQuantity(
          quantity: 5,
          type: InventoryTransactionType.adjustment,
          availableStock: 10,
        ),
        isNull,
      );
      expect(
        validateInventoryQuantity(
          quantity: 500,
          type: InventoryTransactionType.adjustment,
          availableStock: 10,
        ),
        isNull,
      );
    });
  });
}
