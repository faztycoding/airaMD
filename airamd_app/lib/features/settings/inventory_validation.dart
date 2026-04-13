import '../../core/models/models.dart';

enum InventoryQuantityValidationIssue {
  invalidQuantity,
  insufficientStock,
}

InventoryQuantityValidationIssue? validateInventoryQuantity({
  required double? quantity,
  required InventoryTransactionType type,
  required double availableStock,
}) {
  if (quantity == null || quantity <= 0) {
    return InventoryQuantityValidationIssue.invalidQuantity;
  }

  final deductsStock =
      type == InventoryTransactionType.used ||
      type == InventoryTransactionType.wastage;
  if (deductsStock && quantity > availableStock) {
    return InventoryQuantityValidationIssue.insufficientStock;
  }

  return null;
}
