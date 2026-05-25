import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class TreatmentTemplateRepository extends BaseRepository {
  TreatmentTemplateRepository(SupabaseClient client)
      : super(client, 'treatment_templates');

  Future<List<TreatmentTemplate>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client.from(tableName).select().eq('clinic_id', clinicId);
    if (activeOnly) query = query.eq('is_active', true);
    final data = await query.order('name', ascending: true);
    return data.map(TreatmentTemplate.fromJson).toList();
  }

  Future<TreatmentTemplate?> get(String id) async {
    final data = await getById(id);
    return data != null ? TreatmentTemplate.fromJson(data) : null;
  }

  Future<TreatmentTemplate> create(TreatmentTemplate template) async {
    final data = await insert(template.toInsertJson());
    return TreatmentTemplate.fromJson(data);
  }

  Future<TreatmentTemplate> updateTemplate(TreatmentTemplate template) async {
    final data = await update(template.id, template.toUpdateJson());
    return TreatmentTemplate.fromJson(data);
  }

  Future<void> deleteTemplate(String id) => delete(id);
}
