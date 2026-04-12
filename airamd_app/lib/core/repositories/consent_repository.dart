import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class ConsentTemplateRepository extends BaseRepository {
  ConsentTemplateRepository(SupabaseClient client)
      : super(client, 'consent_form_templates');

  Future<List<ConsentFormTemplate>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);

    if (activeOnly) query = query.eq('is_active', true);

    final data = await query.order('name', ascending: true);
    return data.map(ConsentFormTemplate.fromJson).toList();
  }

  Future<ConsentFormTemplate?> get(String id) async {
    final data = await getById(id);
    return data != null ? ConsentFormTemplate.fromJson(data) : null;
  }

  Future<ConsentFormTemplate> create(ConsentFormTemplate template) async {
    final data = await insert(template.toInsertJson());
    return ConsentFormTemplate.fromJson(data);
  }

  Future<ConsentFormTemplate> updateTemplate(
      ConsentFormTemplate template) async {
    final data = await update(template.id, template.toUpdateJson());
    return ConsentFormTemplate.fromJson(data);
  }
}

class ConsentFormRepository extends BaseRepository {
  ConsentFormRepository(SupabaseClient client)
      : super(client, 'consent_forms');

  Future<List<ConsentForm>> getByPatient({
    required String patientId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('signed_at', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(ConsentForm.fromJson).toList();
  }

  Future<ConsentForm> create(ConsentForm form) async {
    final data = await insert(form.toInsertJson());
    return ConsentForm.fromJson(data);
  }
}
