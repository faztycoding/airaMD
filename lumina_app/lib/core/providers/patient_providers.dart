import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// All patients for current clinic.
final patientListProvider =
    AsyncNotifierProvider<PatientListNotifier, List<Patient>>(
  PatientListNotifier.new,
);

class PatientListNotifier extends AsyncNotifier<List<Patient>> {
  @override
  Future<List<Patient>> build() async {
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return [];
    final repo = ref.watch(patientRepoProvider);
    return repo.list(clinicId: clinicId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<Patient> addPatient(Patient patient) async {
    final repo = ref.read(patientRepoProvider);
    final created = await repo.create(patient);
    await refresh();
    return created;
  }

  Future<Patient> updatePatient(Patient patient) async {
    final repo = ref.read(patientRepoProvider);
    final updated = await repo.updatePatient(patient);
    await refresh();
    return updated;
  }

  Future<void> deletePatient(String id) async {
    final repo = ref.read(patientRepoProvider);
    await repo.deletePatient(id);
    await refresh();
  }
}

/// Search patients.
final patientSearchProvider =
    FutureProvider.family<List<Patient>, String>((ref, query) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(patientRepoProvider);
  return repo.searchPatients(clinicId: clinicId, query: query);
});

/// Single patient by ID.
final patientByIdProvider =
    FutureProvider.family<Patient?, String>((ref, id) async {
  final repo = ref.watch(patientRepoProvider);
  return repo.get(id);
});

/// Patient count for current clinic.
final patientCountProvider = FutureProvider<int>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return 0;
  final repo = ref.watch(patientRepoProvider);
  return repo.countPatients(clinicId);
});
