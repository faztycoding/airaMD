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
  Future<AuditLog> logAction({
    required String clinicId,
    String? userId,
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    return create(AuditLog(
      id: '',
      clinicId: clinicId,
      userId: userId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      oldData: oldData,
      newData: newData,
    ));
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
