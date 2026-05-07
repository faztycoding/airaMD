import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/repositories/repository_exceptions.dart';
import 'package:airamd/features/treatments/treatment_post_save_service.dart';

void main() {
  group('TreatmentPostSaveService.buildInventoryOps', () {
    test('drops rows with missing product_id or non-positive quantity', () {
      final ops = TreatmentPostSaveService.buildInventoryOps(
        productsUsed: const [
          {'product_id': 'p-1', 'quantity': 1.5, 'unit': 'ml'},
          {'product_id': null, 'quantity': 1.0}, // missing id
          {'product_id': 'p-2', 'quantity': 0}, // zero qty
          {'product_id': 'p-3', 'quantity': -1}, // negative
          {'product_id': 'p-4', 'quantity': 2.0}, // valid
        ],
        treatmentName: 'Botox',
      );

      expect(ops.map((o) => o.productId).toList(), ['p-1', 'p-4']);
      expect(ops.first.quantity, 1.5);
      expect(ops.first.unit, 'ml');
      expect(ops.first.notes, 'Auto-deduct: Botox');
    });

    test('falls back to "U" unit when missing', () {
      final ops = TreatmentPostSaveService.buildInventoryOps(
        productsUsed: const [
          {'product_id': 'p-1', 'quantity': 1.0},
        ],
        treatmentName: 'Filler',
      );
      expect(ops.single.unit, 'U');
    });
  });

  group('TreatmentPostSaveService.markLinkedAppointmentCompleted', () {
    const service = TreatmentPostSaveService();

    final baseRecord = TreatmentRecord(
      id: 'tr-001',
      clinicId: 'clinic-001',
      patientId: 'patient-001',
      appointmentId: 'appt-001',
      treatmentName: 'Botox',
      category: TreatmentCategory.injectable,
      date: DateTime(2026, 4, 13),
    );

    test('marks linked appointment completed', () async {
      final calls = <Map<String, dynamic>>[];
      await service.markLinkedAppointmentCompleted(
        record: baseRecord,
        updateAppointmentStatus: (id, status) async {
          calls.add({'id': id, 'status': status});
        },
      );
      expect(calls, [
        {'id': 'appt-001', 'status': AppointmentStatus.completed}
      ]);
    });

    test('skips when no appointment is linked', () async {
      final calls = <Map<String, dynamic>>[];
      final unlinked = TreatmentRecord(
        id: 'tr-002',
        clinicId: 'clinic-001',
        patientId: 'patient-001',
        appointmentId: null,
        treatmentName: 'Botox',
        category: TreatmentCategory.injectable,
        date: DateTime(2026, 4, 13),
      );
      await service.markLinkedAppointmentCompleted(
        record: unlinked,
        updateAppointmentStatus: (id, status) async {
          calls.add({'id': id, 'status': status});
        },
      );
      expect(calls, isEmpty);
    });

    test('skips when appointmentId is empty string', () async {
      final calls = <Map<String, dynamic>>[];
      final emptyAppt = TreatmentRecord(
        id: 'tr-003',
        clinicId: 'clinic-001',
        patientId: 'patient-001',
        appointmentId: '',
        treatmentName: 'Botox',
        category: TreatmentCategory.injectable,
        date: DateTime(2026, 4, 13),
      );
      await service.markLinkedAppointmentCompleted(
        record: emptyAppt,
        updateAppointmentStatus: (id, status) async {
          calls.add({'id': id, 'status': status});
        },
      );
      expect(calls, isEmpty);
    });
  });

  group('TreatmentPostSaveService (legacy non-atomic flow)', () {
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
            // The repository now raises a typed exception rather than a bare
            // `Exception('insufficient stock')`. The post-save service must
            // still treat it as a non-fatal stock-sync failure.
            throw const InsufficientStockException(productName: 'Filler');
          }
        },
        createInventoryTransaction: (_) async {},
      );

      expect(failures, ['Filler']);
    });
  });
}
