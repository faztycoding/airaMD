import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// All courses for current clinic.
final courseListProvider = FutureProvider<List<Course>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(courseRepoProvider);
  return repo.list(clinicId: clinicId);
});

/// Courses for a specific patient.
final coursesByPatientProvider =
    FutureProvider.family<List<Course>, String>((ref, patientId) async {
  final repo = ref.watch(courseRepoProvider);
  return repo.getByPatient(patientId: patientId, activeOnly: false);
});

/// Active courses for a specific patient.
final activeCoursesProvider =
    FutureProvider.family<List<Course>, String>((ref, patientId) async {
  final repo = ref.watch(courseRepoProvider);
  return repo.getByPatient(patientId: patientId, activeOnly: true);
});

/// Single course by ID.
final courseByIdProvider =
    FutureProvider.family<Course?, String>((ref, id) async {
  final repo = ref.watch(courseRepoProvider);
  return repo.get(id);
});
