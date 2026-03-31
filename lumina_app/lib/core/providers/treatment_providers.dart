import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// Treatment records for a patient.
final treatmentsByPatientProvider =
    FutureProvider.family<List<TreatmentRecord>, String>((ref, patientId) async {
  final repo = ref.watch(treatmentRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

/// Single treatment record by ID.
final treatmentByIdProvider =
    FutureProvider.family<TreatmentRecord?, String>((ref, id) async {
  final repo = ref.watch(treatmentRepoProvider);
  return repo.get(id);
});

/// Today's treatments for clinic.
final todayTreatmentsProvider =
    FutureProvider<List<TreatmentRecord>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(treatmentRepoProvider);
  return repo.getByDate(clinicId: clinicId, date: DateTime.now());
});

/// Treatment rules for current clinic.
final treatmentRulesProvider =
    FutureProvider<List<TreatmentRule>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(treatmentRuleRepoProvider);
  return repo.list(clinicId: clinicId);
});

/// Face diagrams for a patient.
final diagramsByPatientProvider =
    FutureProvider.family<List<FaceDiagram>, String>((ref, patientId) async {
  final repo = ref.watch(diagramRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

/// Get last treatment of a specific type for a patient.
final lastTreatmentOfTypeProvider = FutureProvider.family<TreatmentRecord?,
    ({String patientId, String treatmentName})>((ref, params) async {
  final repo = ref.watch(treatmentRepoProvider);
  final records = await repo.getByPatient(patientId: params.patientId, limit: 100);
  try {
    return records.firstWhere(
      (r) => r.treatmentName.toLowerCase() == params.treatmentName.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
});
