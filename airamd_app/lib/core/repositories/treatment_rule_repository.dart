import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class TreatmentRuleRepository extends BaseRepository {
  TreatmentRuleRepository(SupabaseClient client)
      : super(client, 'treatment_rules');

  Future<List<TreatmentRule>> list({
    required String clinicId,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: 'treatment_type',
      ascending: true,
    );
    return data.map(TreatmentRule.fromJson).toList();
  }

  Future<TreatmentRule?> get(String id) async {
    final data = await getById(id);
    return data != null ? TreatmentRule.fromJson(data) : null;
  }

  Future<TreatmentRule> create(TreatmentRule rule) async {
    final data = await insert(rule.toInsertJson());
    return TreatmentRule.fromJson(data);
  }

  Future<TreatmentRule> updateRule(TreatmentRule rule) async {
    final data = await update(rule.id, rule.toUpdateJson());
    return TreatmentRule.fromJson(data);
  }

  Future<void> deleteRule(String id) => delete(id);

  /// Get rule for a specific treatment type.
  Future<TreatmentRule?> getByType({
    required String clinicId,
    required String treatmentType,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('treatment_type', treatmentType)
        .maybeSingle();
    return data != null ? TreatmentRule.fromJson(data) : null;
  }
}
