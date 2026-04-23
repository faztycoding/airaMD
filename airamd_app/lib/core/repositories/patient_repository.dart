import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class PatientRepository extends BaseRepository {
  PatientRepository(SupabaseClient client) : super(client, 'patients');

  Future<List<Patient>> list({
    required String clinicId,
    String orderBy = 'created_at',
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
    return data.map(Patient.fromJson).toList();
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

  /// Soft-delete: set is_active = false (data preserved for legal/medical compliance).
  Future<void> softDelete(String id) async {
    await client.from(tableName).update({'is_active': false}).eq('id', id);
  }

  /// Search patients by name, nickname, HN, or phone.
  Future<List<Patient>> searchPatients({
    required String clinicId,
    required String query,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return list(clinicId: clinicId, limit: limit);

    // Supabase `.or()` parses commas as condition separators and parentheses
    // as grouping, so strip those chars to avoid malformed queries when users
    // include them in their search term.
    final safe = trimmed.replaceAll(RegExp(r'[(),]'), ' ').trim();
    if (safe.isEmpty) return list(clinicId: clinicId, limit: limit);

    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
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

  /// Get patients by status (VIP, STAR, etc.)
  Future<List<Patient>> getByStatus({
    required String clinicId,
    required PatientStatus status,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('status', status.dbValue)
        .order('first_name', ascending: true);

    return data.map(Patient.fromJson).toList();
  }

  /// Count total patients for a clinic.
  Future<int> countPatients(String clinicId) => count(clinicId: clinicId);
}
