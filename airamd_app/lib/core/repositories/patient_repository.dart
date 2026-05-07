import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '_helpers.dart';
import 'base_repository.dart';

class PatientRepository extends BaseRepository {
  PatientRepository(SupabaseClient client) : super(client, 'patients');

  /// List patients. Soft-deleted rows (`is_active = false`) are excluded by
  /// default to match the UI's expectation — pass `includeInactive: true`
  /// for admin / recovery flows.
  Future<List<Patient>> list({
    required String clinicId,
    String orderBy = 'created_at',
    bool ascending = false,
    int? limit,
    int? offset,
    bool includeInactive = false,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);
    if (!includeInactive) {
      query = query.eq('is_active', true);
    }
    var ordered = query.order(orderBy, ascending: ascending);
    if (limit != null) ordered = ordered.limit(limit);
    if (offset != null && limit != null) {
      ordered = ordered.range(offset, offset + limit - 1);
    }
    final data = await ordered;
    return (data as List).cast<Map<String, dynamic>>().map(Patient.fromJson).toList();
  }

  Future<Patient?> get(String id) async {
    final data = await getById(id);
    return data != null ? Patient.fromJson(data) : null;
  }

  Future<Patient> create(Patient patient) async {
    final data = await insert(patient.toInsertJson());
    return Patient.fromJson(data);
  }

  Future<Patient> updatePatient(Patient patient) async {
    final data = await update(patient.id, patient.toUpdateJson());
    return Patient.fromJson(data);
  }

  Future<void> deletePatient(String id) => delete(id);

  /// Soft-delete: set is_active = false. Requires the column added in
  /// migration 013 — prior to that this call was a silent no-op that
  /// actually raised "column does not exist".
  Future<void> softDelete(String id) async {
    await client.from(tableName).update({'is_active': false}).eq('id', id);
  }

  /// Restore a previously soft-deleted patient.
  Future<void> restore(String id) async {
    await client.from(tableName).update({'is_active': true}).eq('id', id);
  }

  /// Search patients by name, nickname, HN, or phone.
  ///
  /// User input is sanitised in two stages:
  ///   1. Strip `(`, `)`, `,` because PostgREST's `.or()` parser treats
  ///      commas as condition separators and parens as grouping, so leaving
  ///      them in lets the user produce malformed queries.
  ///   2. Escape `%`, `_`, `\` because they are wildcards inside ILIKE and
  ///      otherwise let any user enumerate the entire clinic's patient list
  ///      with a single `%` keystroke.
  Future<List<Patient>> searchPatients({
    required String clinicId,
    required String query,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return list(clinicId: clinicId, limit: limit);

    final stripped = trimmed.replaceAll(RegExp(r'[(),]'), ' ').trim();
    if (stripped.isEmpty) return list(clinicId: clinicId, limit: limit);

    final safe = escapeLike(stripped);

    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('is_active', true)
        .or('first_name.ilike.%$safe%,'
            'last_name.ilike.%$safe%,'
            'nickname.ilike.%$safe%,'
            'hn.ilike.%$safe%,'
            'phone.ilike.%$safe%,'
            'national_id.ilike.%$safe%')
        .order('created_at', ascending: false)
        .limit(limit);

    return data.map(Patient.fromJson).toList();
  }

  /// Get patients by status (VIP, STAR, etc.) — active only.
  Future<List<Patient>> getByStatus({
    required String clinicId,
    required PatientStatus status,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('is_active', true)
        .eq('status', status.dbValue)
        .order('first_name', ascending: true);

    return data.map(Patient.fromJson).toList();
  }

  /// Count total patients for a clinic.
  Future<int> countPatients(String clinicId) => count(clinicId: clinicId);

  /// Single-call patient profile aggregator (migration 009).
  ///
  /// Returns the patient row plus their recent treatments, recent
  /// appointments, courses, and outstanding balance — all in one round
  /// trip — to replace the 4–5 sequential `FutureProvider` calls the
  /// patient profile screen used to make.
  ///
  /// Returns `null` when the patient row isn't found / not visible under
  /// RLS, or when the RPC returns a JSON null because the row was deleted
  /// between RPC dispatch and execution.
  Future<PatientProfileBundle?> getFullProfile(String patientId) async {
    final result = await client.rpc(
      'get_patient_full',
      params: {'p_patient_id': patientId},
    );
    if (result == null) return null;
    final map = Map<String, dynamic>.from(result as Map);
    if (map['patient'] == null) return null;
    return PatientProfileBundle.fromJson(map);
  }
}
