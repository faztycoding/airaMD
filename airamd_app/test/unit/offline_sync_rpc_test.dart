import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/services/offline_sync_service.dart';

void main() {
  group('PendingOperation — RPC action round-trip', () {
    test('serialises an RPC op and deserialises with the same payload', () {
      final op = PendingOperation(
        id: '1730000000',
        table: 'record_treatment_atomic',
        action: 'RPC',
        payload: {
          'p_treatment': {
            'clinic_id': 'c-1',
            'patient_id': 'p-1',
            'treatment_name': 'Botox',
          },
          'p_inventory': [
            {'product_id': 'prod-1', 'quantity': 2.0},
          ],
        },
        createdAt: DateTime.utc(2026, 5, 6, 22, 0),
      );

      final json = op.toJson();
      expect(json['action'], 'RPC');
      expect(json['table'], 'record_treatment_atomic');
      expect(json['payload']['p_treatment']['treatment_name'], 'Botox');

      final round = PendingOperation.fromJson(json);
      expect(round.id, op.id);
      expect(round.action, 'RPC');
      expect(round.table, 'record_treatment_atomic');
      expect(round.payload['p_inventory'], isA<List>());
      expect(
        (round.payload['p_inventory'] as List).first['product_id'],
        'prod-1',
      );
      expect(round.createdAt.toUtc(), DateTime.utc(2026, 5, 6, 22, 0));
    });

    test('keeps INSERT/UPDATE/DELETE actions unchanged for back-compat', () {
      for (final action in ['INSERT', 'UPDATE', 'DELETE', 'UPSERT']) {
        final op = PendingOperation(
          id: '1',
          table: 'patients',
          action: action,
          payload: const {'id': 'p-1', 'first_name': 'Test'},
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final round = PendingOperation.fromJson(op.toJson());
        expect(round.action, action);
        expect(round.table, 'patients');
        expect(round.payload['first_name'], 'Test');
      }
    });
  });
}
