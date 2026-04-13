import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/features/treatments/treatment_post_save_service.dart';

void main() {
  group('TreatmentPostSaveService', () {
    const service = TreatmentPostSaveService();

    final record = TreatmentRecord(
      id: 'tr-001',
      clinicId: 'clinic-001',
      patientId: 'patient-001',
      appointmentId: 'appt-001',
      treatmentName: 'Botox',
      category: TreatmentCategory.injectable,
      date: DateTime(2026, 4, 13),
    );

    test('marks linked appointment completed and syncs stock transactions', () async {
      final updatedAppointments = <Map<String, dynamic>>[];
      final deductedProducts = <Map<String, dynamic>>[];
      final createdTransactions = <InventoryTransaction>[];

      final failures = await service.handleNewTreatmentSave(
        clinicId: 'clinic-001',
        patientId: 'patient-001',
        record: record,
        productsUsed: const [
          {
            'product_id': 'prod-001',
            'quantity': 2.0,
            'unit': 'U',
            'name': 'Botox 50U',
          },
        ],
        updateAppointmentStatus: (appointmentId, status) async {
          updatedAppointments.add({'id': appointmentId, 'status': status});
        },
        deductStock: (productId, quantity) async {
          deductedProducts.add({'id': productId, 'quantity': quantity});
        },
        createInventoryTransaction: (tx) async {
          createdTransactions.add(tx);
        },
      );

      expect(failures, isEmpty);
      expect(updatedAppointments, [
        {'id': 'appt-001', 'status': AppointmentStatus.completed}
      ]);
      expect(deductedProducts, [
        {'id': 'prod-001', 'quantity': 2.0}
      ]);
      expect(createdTransactions, hasLength(1));
      expect(createdTransactions.single.productId, 'prod-001');
      expect(createdTransactions.single.transactionType, InventoryTransactionType.used);
      expect(createdTransactions.single.quantity, 2.0);
    });

    test('collects stock sync failures without stopping save flow', () async {
      final failures = await service.handleNewTreatmentSave(
        clinicId: 'clinic-001',
        patientId: 'patient-001',
        record: record,
        productsUsed: const [
          {
            'product_id': 'prod-001',
            'quantity': 1.0,
            'unit': 'U',
            'name': 'Botox 50U',
          },
          {
            'product_id': 'prod-002',
            'quantity': 0.5,
            'unit': 'U',
            'name': 'Filler',
          },
        ],
        updateAppointmentStatus: (_, __) async {},
        deductStock: (productId, quantity) async {
          if (productId == 'prod-002') {
            throw Exception('insufficient stock');
          }
        },
        createInventoryTransaction: (_) async {},
      );

      expect(failures, ['Filler']);
    });
  });
}
