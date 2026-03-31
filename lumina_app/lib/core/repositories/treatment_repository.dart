import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class TreatmentRepository extends BaseRepository {
  TreatmentRepository(SupabaseClient client)
      : super(client, 'treatment_records');

  Future<List<TreatmentRecord>> list({
    required String clinicId,
    String orderBy = 'date',
    bool ascending = false,
    int? limit,
    int? offset,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: orderBy,
      ascending: ascending,
      limit: limit,
      offset: offset,
    );
    return data.map(TreatmentRecord.fromJson).toList();
  }

  Future<TreatmentRecord?> get(String id) async {
    final data = await getById(id);
    return data != null ? TreatmentRecord.fromJson(data) : null;
  }

  Future<TreatmentRecord> create(TreatmentRecord record) async {
    final data = await insert(record.toInsertJson());
    return TreatmentRecord.fromJson(data);
  }

  Future<TreatmentRecord> updateRecord(TreatmentRecord record) async {
    final data = await update(record.id, record.toUpdateJson());
    return TreatmentRecord.fromJson(data);
  }

  Future<void> deleteRecord(String id) => delete(id);

  /// Get treatment history for a patient.
  Future<List<TreatmentRecord>> getByPatient({
    required String patientId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('date', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(TreatmentRecord.fromJson).toList();
  }

  /// Get treatments for a specific date.
  Future<List<TreatmentRecord>> getByDate({
    required String clinicId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final nextDateStr =
        date.add(const Duration(days: 1)).toIso8601String().split('T').first;

    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .gte('date', dateStr)
        .lt('date', nextDateStr)
        .order('date', ascending: false);

    return data.map(TreatmentRecord.fromJson).toList();
  }

  /// Get treatments with pending follow-ups.
  Future<List<TreatmentRecord>> getPendingFollowUps({
    required String clinicId,
    int limit = 20,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .not('follow_up_date', 'is', null)
        .gte('follow_up_date', today)
        .order('follow_up_date', ascending: true)
        .limit(limit);

    return data.map(TreatmentRecord.fromJson).toList();
  }

  /// Get pending commissions.
  Future<List<TreatmentRecord>> getPendingCommissions({
    required String clinicId,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('commission_status', CommissionStatus.pending.dbValue)
        .order('date', ascending: false);

    return data.map(TreatmentRecord.fromJson).toList();
  }
}
