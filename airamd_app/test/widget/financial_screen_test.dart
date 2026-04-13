import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/providers/providers.dart';
import 'package:airamd/features/financial/financial_screen.dart';
import '../helpers/test_app.dart';
import '../helpers/test_fixtures.dart';

class _MockPatientListNotifier extends AsyncNotifier<List<Patient>>
    implements PatientListNotifier {
  @override
  Future<List<Patient>> build() async => [TestFixtures.healthyPatient()];

  @override
  Future<void> refresh() async {}

  @override
  Future<Patient> addPatient(Patient patient) async => patient;

  @override
  Future<Patient> updatePatient(Patient patient) async => patient;

  @override
  Future<void> deletePatient(String id) async {}
}

void main() {
  testWidgets('FinancialScreen rejects invalid amount before create action', (
    tester,
  ) async {
    final createdRecords = <FinancialRecord>[];

    await tester.pumpWidget(
      testApp(
        const FinancialScreen(),
        overrides: [
          canAccessFinancialDataProvider.overrideWithValue(true),
          currentClinicIdProvider.overrideWithValue(TestFixtures.clinicId),
          todayRevenueAmountProvider.overrideWith((ref) => Future.value(0)),
          outstandingRecordsProvider.overrideWith((ref) => Future.value(<FinancialRecord>[])),
          financialListProvider.overrideWith((ref) => Future.value(<FinancialRecord>[])),
          patientListProvider.overrideWith(() => _MockPatientListNotifier()),
          createFinancialRecordActionProvider.overrideWithValue((record) async {
            createdRecords.add(record);
            return record;
          }),
        ],
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('สมหญิง ใจดี').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    expect(createdRecords, isEmpty);
    expect(find.text('จำนวนเงินต้องเป็นตัวเลขที่ถูกต้อง'), findsOneWidget);
  });
}
