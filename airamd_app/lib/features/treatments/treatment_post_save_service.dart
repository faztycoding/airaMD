import 'package:uuid/uuid.dart';
import '../../core/models/models.dart';

class TreatmentPostSaveService {
  const TreatmentPostSaveService();

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
