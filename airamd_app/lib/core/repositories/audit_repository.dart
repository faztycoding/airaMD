import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class AuditRepository extends BaseRepository {
  AuditRepository(SupabaseClient client) : super(client, 'audit_logs');

  Future<AuditLog> create(AuditLog log) async {
    final data = await insert(log.toInsertJson());
    return AuditLog.fromJson(data);
  }

  /// Log an action for PDPA compliance.
  ///
  /// Routes through the `record_audit_log` SECURITY DEFINER RPC introduced
  /// in migration 010 so:
  ///   * `user_id` and `timestamp` are forced server-side from `auth.uid()`
  ///     and `now()` — the client cannot spoof either.
  ///   * Direct INSERT on `audit_logs` is REVOKEd from `authenticated`, so
  ///     even if this code path is bypassed nothing can write a fake row.
  ///
  /// The [userId] parameter is intentionally ignored: the RPC resolves the
  /// staff row from the authenticated session.
  Future<AuditLog> logAction({
    required String clinicId,
    String? userId, // ignored, kept for API compatibility
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    final result = await client.rpc(
      'record_audit_log',
      params: {
        'p_clinic_id': clinicId,
        'p_action': action,
        'p_entity_type': entityType,
        'p_entity_id': entityId,
        'p_old_data': oldData,
        'p_new_data': newData,
      },
    );
    return AuditLog.fromJson(Map<String, dynamic>.from(result as Map));
  }

  /// Get audit history for a specific entity.
  Future<List<AuditLog>> getByEntity({
    required String entityType,
    required String entityId,
    int limit = 50,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('timestamp', ascending: false)
        .limit(limit);
    return data.map(AuditLog.fromJson).toList();
  }

  /// Get recent audit logs for a clinic.
  Future<List<AuditLog>> getRecent({
    required String clinicId,
    int limit = 100,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: 'timestamp',
      ascending: false,
      limit: limit,
    );
    return data.map(AuditLog.fromJson).toList();
  }
}
