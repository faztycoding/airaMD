import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class DiagramRepository extends BaseRepository {
  DiagramRepository(SupabaseClient client) : super(client, 'face_diagrams');

  Future<List<FaceDiagram>> getByPatient({
    required String patientId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(FaceDiagram.fromJson).toList();
  }

  Future<List<FaceDiagram>> getByTreatment(String treatmentRecordId) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('treatment_record_id', treatmentRecordId)
        .order('created_at', ascending: false);
    return data.map(FaceDiagram.fromJson).toList();
  }

  Future<FaceDiagram> create(FaceDiagram diagram) async {
    final data = await insert(diagram.toInsertJson());
    return FaceDiagram.fromJson(data);
  }

  Future<FaceDiagram> updateDiagram(FaceDiagram diagram) async {
    final data = await update(diagram.id, diagram.toUpdateJson());
    return FaceDiagram.fromJson(data);
  }

  Future<void> deleteDiagram(String id) => delete(id);
}
