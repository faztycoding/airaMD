import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// All financial records for current clinic.
final financialListProvider = FutureProvider<List<FinancialRecord>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(financialRepoProvider);
  return repo.list(clinicId: clinicId, limit: 100);
});

/// Financial records for a patient.
final financialsByPatientProvider =
    FutureProvider.family<List<FinancialRecord>, String>((ref, patientId) async {
  final repo = ref.watch(financialRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

/// Outstanding (unpaid) records.
final outstandingRecordsProvider =
    FutureProvider<List<FinancialRecord>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(financialRepoProvider);
  return repo.getOutstanding(clinicId);
});

/// Today's revenue.
final todayRevenueAmountProvider = FutureProvider<double>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return 0;
  final repo = ref.watch(financialRepoProvider);
  return repo.todayRevenue(clinicId);
});

/// Patient balance summary — total charges vs payments.
final patientBalanceProvider =
    FutureProvider.family<double, String>((ref, patientId) async {
  final repo = ref.watch(financialRepoProvider);
  final records = await repo.getByPatient(patientId: patientId);
  double balance = 0;
  for (final r in records) {
    if (r.type == FinancialType.charge) {
      balance += r.amount;
    } else if (r.type == FinancialType.payment) {
      balance -= r.amount;
    } else if (r.type == FinancialType.refund) {
      balance += r.amount;
    } else if (r.type == FinancialType.adjustment) {
      balance += r.amount;
    }
  }
  return balance; // positive = owes money
});
