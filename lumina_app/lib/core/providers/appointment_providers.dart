import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// Today's appointments for current clinic.
final todayAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(appointmentRepoProvider);
  return repo.getByDate(clinicId: clinicId, date: DateTime.now());
});

/// Appointments for a specific date.
final appointmentsByDateProvider =
    FutureProvider.family<List<Appointment>, DateTime>((ref, date) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(appointmentRepoProvider);
  return repo.getByDate(clinicId: clinicId, date: date);
});

/// Appointments for a patient.
final appointmentsByPatientProvider =
    FutureProvider.family<List<Appointment>, String>((ref, patientId) async {
  final repo = ref.watch(appointmentRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

/// Today's appointment count.
final todayAppointmentCountProvider = FutureProvider<int>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return 0;
  final repo = ref.watch(appointmentRepoProvider);
  return repo.countToday(clinicId);
});

/// Appointments for a date range (calendar view).
final appointmentsByRangeProvider = FutureProvider.family<List<Appointment>,
    ({DateTime from, DateTime to})>((ref, range) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(appointmentRepoProvider);
  return repo.getByDateRange(
    clinicId: clinicId,
    from: range.from,
    to: range.to,
  );
});
