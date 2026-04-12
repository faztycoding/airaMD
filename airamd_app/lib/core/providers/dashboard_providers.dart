import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// Dashboard stats — aggregated data for the main dashboard.
class DashboardStats {
  final int todayAppointments;
  final int totalPatients;
  final int pendingFollowUps;
  final double monthRevenue;

  const DashboardStats({
    this.todayAppointments = 0,
    this.totalPatients = 0,
    this.pendingFollowUps = 0,
    this.monthRevenue = 0,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const DashboardStats();

  final apptRepo = ref.watch(appointmentRepoProvider);
  final patientRepo = ref.watch(patientRepoProvider);
  final treatmentRepo = ref.watch(treatmentRepoProvider);
  final financialRepo = ref.watch(financialRepoProvider);

  final results = await Future.wait([
    apptRepo.countToday(clinicId),
    patientRepo.countPatients(clinicId),
    treatmentRepo.getPendingFollowUps(clinicId: clinicId),
    financialRepo.todayRevenue(clinicId),
  ]);

  return DashboardStats(
    todayAppointments: results[0] as int,
    totalPatients: results[1] as int,
    pendingFollowUps: (results[2] as List<TreatmentRecord>).length,
    monthRevenue: results[3] as double,
  );
});

/// Upcoming follow-ups for dashboard card.
final upcomingFollowUpsProvider =
    FutureProvider<List<TreatmentRecord>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(treatmentRepoProvider);
  return repo.getPendingFollowUps(clinicId: clinicId, limit: 5);
});

/// Today's revenue.
final todayRevenueProvider = FutureProvider<double>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return 0;
  final repo = ref.watch(financialRepoProvider);
  return repo.todayRevenue(clinicId);
});

/// Low stock alerts for dashboard.
final lowStockAlertsProvider = FutureProvider<List<Product>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(productRepoProvider);
  return repo.getLowStock(clinicId);
});

/// Products expiring within 30 days or already expired.
final expiringProductsProvider = FutureProvider<List<Product>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(productRepoProvider);
  final all = await repo.list(clinicId: clinicId);
  final cutoff = DateTime.now().add(const Duration(days: 30));
  return all
      .where((p) => p.expiryDate != null && p.expiryDate!.isBefore(cutoff))
      .toList()
    ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
});
