import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class PhotoRepository extends BaseRepository {
  PhotoRepository(SupabaseClient client) : super(client, 'patient_photos');

  Future<List<PatientPhoto>> getByPatient({
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
    return data.map(PatientPhoto.fromJson).toList();
  }

  Future<List<PatientPhoto>> getByTreatment(String treatmentRecordId) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('treatment_record_id', treatmentRecordId)
        .order('sort_order', ascending: true);
    return data.map(PatientPhoto.fromJson).toList();
  }

  Future<PatientPhoto> create(PatientPhoto photo) async {
    final data = await insert(photo.toInsertJson());
    return PatientPhoto.fromJson(data);
  }

  Future<void> deletePhoto(String id) => delete(id);

  /// Get before/after pairs for a patient.
  Future<Map<String, List<PatientPhoto>>> getBeforeAfterPairs({
    required String patientId,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .inFilter('image_type', [
          PhotoType.before.dbValue,
          PhotoType.after1m.dbValue,
          PhotoType.after3m.dbValue,
          PhotoType.after6m.dbValue,
        ])
        .order('treatment_date', ascending: false);

    final photos = data.map(PatientPhoto.fromJson).toList();
    final Map<String, List<PatientPhoto>> grouped = {};

    for (final photo in photos) {
      final key = photo.treatmentRecordId ?? 'unlinked';
      grouped.putIfAbsent(key, () => []).add(photo);
    }

    return grouped;
  }
}
