import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// All active treatment combo templates for the current clinic.
///
/// Seeded with 5 starter combos in migration 023 (Phase 5E).
final treatmentTemplateListProvider =
    FutureProvider<List<TreatmentTemplate>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const [];
  final repo = ref.watch(treatmentTemplateRepoProvider);
  return repo.list(clinicId: clinicId);
});

/// Templates filtered by treatment category — useful for the picker
/// which only shows combos matching the currently-selected category.
final treatmentTemplatesByCategoryProvider = FutureProvider.family<
    List<TreatmentTemplate>, TreatmentCategory>((ref, cat) async {
  final all = await ref.watch(treatmentTemplateListProvider.future);
  return all.where((t) => t.category == cat).toList();
});
