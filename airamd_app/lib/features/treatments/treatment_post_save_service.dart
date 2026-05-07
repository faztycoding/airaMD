import 'package:uuid/uuid.dart';
import '../../core/models/models.dart';
import '../../core/repositories/inventory_op.dart';

class TreatmentPostSaveService {
  const TreatmentPostSaveService();

  // ───────────────────────────────────────────────────────────────
  // Atomic flow (preferred — uses record_treatment_atomic RPC)
  // ───────────────────────────────────────────────────────────────

  /// Build the [InventoryOp] list from the raw `productsUsed` rows the form
  /// captures, dropping any that are missing required fields.
  ///
  /// Exposed as a pure static helper so the form (and tests) can reuse the
  /// same mapping without going through the service instance.
  static List<InventoryOp> buildInventoryOps({
    required List<Map<String, dynamic>> productsUsed,
    required String treatmentName,
  }) {
    final ops = <InventoryOp>[];
    for (final product in productsUsed) {
      final productId = product['product_id'] as String?;
      final quantity = (product['quantity'] as num?)?.toDouble() ?? 0;
      if (productId == null || quantity <= 0) continue;
      ops.add(InventoryOp(
        productId: productId,
        quantity: quantity,
        transactionType: InventoryTransactionType.used,
        unit: product['unit'] as String? ?? 'U',
        notes: 'Auto-deduct: $treatmentName',
      ));
    }
    return ops;
  }

  /// Run the appointment-status side effect for an atomic save.
  ///
  /// The treatment row + inventory transactions are now written by the
  /// `record_treatment_atomic` RPC inside one Postgres transaction, so the
  /// only thing left to coordinate from Dart is marking the linked
  /// appointment as `COMPLETED` (which intentionally lives outside the atomic
  /// block — a missed status update is recoverable and shouldn't roll back
  /// the patient's clinical record).
  Future<void> markLinkedAppointmentCompleted({
    required TreatmentRecord record,
    required Future<void> Function(String appointmentId, AppointmentStatus status)
        updateAppointmentStatus,
  }) async {
    if (record.appointmentId != null && record.appointmentId!.isNotEmpty) {
      await updateAppointmentStatus(
        record.appointmentId!,
        AppointmentStatus.completed,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Legacy non-atomic flow (kept for the offline queue replay path)
  // ───────────────────────────────────────────────────────────────

  /// Original sequential save flow.
  ///
  /// Retained because the offline-aware sync queue replays operations
  /// individually and cannot yet drive the atomic RPC. Once the queue is
  /// migrated to use `record_treatment_atomic` directly this can be removed.
  Future<List<String>> handleNewTreatmentSave({
    required String clinicId,
    required String patientId,
    required TreatmentRecord record,
    required List<Map<String, dynamic>> productsUsed,
    required Future<void> Function(String appointmentId, AppointmentStatus status)
        updateAppointmentStatus,
    required Future<void> Function(String productId, double quantity) deductStock,
    required Future<void> Function(InventoryTransaction transaction)
        createInventoryTransaction,
  }) async {
    if (record.appointmentId != null && record.appointmentId!.isNotEmpty) {
      await updateAppointmentStatus(
        record.appointmentId!,
        AppointmentStatus.completed,
      );
    }

    final stockSyncFailures = <String>[];
    for (final product in productsUsed) {
      final productId = product['product_id'] as String?;
      final quantity = (product['quantity'] as num?)?.toDouble() ?? 0;
      if (productId == null || quantity <= 0) continue;

      try {
        await deductStock(productId, quantity);
        await createInventoryTransaction(
          InventoryTransaction(
            id: const Uuid().v4(),
            clinicId: clinicId,
            productId: productId,
            treatmentRecordId: record.id,
            patientId: patientId,
            transactionType: InventoryTransactionType.used,
            quantity: quantity,
            unit: product['unit'] as String? ?? 'U',
            notes: 'Auto-deduct: ${record.treatmentName}',
          ),
        );
      } catch (_) {
        stockSyncFailures.add(product['name']?.toString() ?? productId);
      }
    }

    return stockSyncFailures;
  }
}
