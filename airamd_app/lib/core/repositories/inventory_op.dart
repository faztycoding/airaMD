import '../models/enums.dart';

/// Single inventory operation passed to [TreatmentRepository.createWithInventory]
/// and serialised into the `record_treatment_atomic` Postgres RPC payload.
///
/// Kept as a small, immutable value object instead of reusing
/// [InventoryTransaction] because it only carries the inputs that the RPC
/// needs — the resulting persisted row is built server-side, with `id`,
/// `clinic_id`, `treatment_record_id`, `patient_id`, and timestamps filled in
/// from the surrounding treatment.
class InventoryOp {
  final String productId;
  final double quantity;
  final InventoryTransactionType transactionType;
  final String? unit;
  final String? batchNo;
  final String? notes;
  final String? createdBy;

  const InventoryOp({
    required this.productId,
    required this.quantity,
    this.transactionType = InventoryTransactionType.used,
    this.unit,
    this.batchNo,
    this.notes,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'transaction_type': transactionType.dbValue,
        if (unit != null) 'unit': unit,
        if (batchNo != null) 'batch_no': batchNo,
        if (notes != null) 'notes': notes,
        if (createdBy != null) 'created_by': createdBy,
      };
}
