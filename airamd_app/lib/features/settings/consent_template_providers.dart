import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/repository_providers.dart';
import 'consent_default_templates.dart';

/// DB-backed consent templates for the current clinic.
///
/// Replaces the previous in-memory list — templates now persist to Supabase
/// (`consent_form_templates`) so add / edit / delete survive app restarts.
/// Writes are OWNER-only at the RLS layer.
final consentTemplatesProvider = AsyncNotifierProvider<ConsentTemplatesNotifier,
    List<ConsentFormTemplate>>(ConsentTemplatesNotifier.new);

class ConsentTemplatesNotifier
    extends AsyncNotifier<List<ConsentFormTemplate>> {
  @override
  Future<List<ConsentFormTemplate>> build() async {
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return const [];
    // activeOnly: false so OWNER can see (and re-activate) archived templates.
    return ref
        .read(consentTemplateRepoProvider)
        .list(clinicId: clinicId, activeOnly: false);
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> add({
    required String name,
    String? category,
    required String content,
  }) async {
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) return;
    await ref.read(consentTemplateRepoProvider).create(
          ConsentFormTemplate(
            id: '',
            clinicId: clinicId,
            name: name,
            category: category,
            content: content,
          ),
        );
    await _reload();
  }

  Future<void> edit(ConsentFormTemplate template) async {
    await ref.read(consentTemplateRepoProvider).updateTemplate(template);
    await _reload();
  }

  Future<void> remove(String id) async {
    await ref.read(consentTemplateRepoProvider).deleteTemplate(id);
    await _reload();
  }

  /// Seed the clinic's default Laser + Treatment templates. Used from the
  /// empty-state button so a new clinic starts with its real legal documents.
  Future<void> seedDefaults() async {
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) return;
    final repo = ref.read(consentTemplateRepoProvider);
    for (final d in kDefaultConsentTemplates) {
      await repo.create(
        ConsentFormTemplate(
          id: '',
          clinicId: clinicId,
          name: d.name,
          category: d.category,
          content: d.content,
        ),
      );
    }
    await _reload();
  }
}
