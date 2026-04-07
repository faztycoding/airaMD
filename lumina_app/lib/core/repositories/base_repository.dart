import 'package:supabase_flutter/supabase_flutter.dart';

/// Generic base repository providing CRUD operations for any Supabase table.
/// All queries are scoped by [clinicId] for multi-tenant isolation.
class BaseRepository {
  final SupabaseClient _client;
  final String tableName;

  BaseRepository(this._client, this.tableName);

  SupabaseClient get client => _client;

  // ─── READ ────────────────────────────────────────────────────

  /// Fetch all rows for a clinic with optional ordering and pagination.
  Future<List<Map<String, dynamic>>> getAll({
    required String clinicId,
    String orderBy = 'created_at',
    bool ascending = false,
    int? limit,
    int? offset,
    String? select,
  }) async {
    var query = _client
        .from(tableName)
        .select(select ?? '*')
        .eq('clinic_id', clinicId)
        .order(orderBy, ascending: ascending);

    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

    return await query;
  }

  /// Fetch a single row by ID.
  Future<Map<String, dynamic>?> getById(String id) async {
    final result = await _client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    return result;
  }

  /// Count rows for a clinic with optional filters.
  /// Uses Postgres `count(*)` — efficient even on large tables.
  Future<int> count({
    required String clinicId,
    Map<String, dynamic>? filters,
  }) async {
    var query = _client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);

    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    final result = await query.count(CountOption.exact);
    return result.count;
  }

  // ─── CREATE ──────────────────────────────────────────────────

  /// Insert a new row and return the created record.
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    final result = await _client
        .from(tableName)
        .insert(data)
        .select()
        .single();
    return result;
  }

  /// Insert multiple rows.
  Future<List<Map<String, dynamic>>> insertMany(
      List<Map<String, dynamic>> data) async {
    final result = await _client
        .from(tableName)
        .insert(data)
        .select();
    return result;
  }

  // ─── UPDATE ──────────────────────────────────────────────────

  /// Update a row by ID and return the updated record.
  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final result = await _client
        .from(tableName)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return result;
  }

  // ─── DELETE ──────────────────────────────────────────────────

  /// Delete a row by ID.
  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }

  // ─── SEARCH ──────────────────────────────────────────────────

  /// Text search using PostgreSQL ilike on a specific column.
  Future<List<Map<String, dynamic>>> search({
    required String clinicId,
    required String column,
    required String query,
    String orderBy = 'created_at',
    bool ascending = false,
    int limit = 50,
  }) async {
    return await _client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .ilike(column, '%$query%')
        .order(orderBy, ascending: ascending)
        .limit(limit);
  }

  // ─── REALTIME ────────────────────────────────────────────────

  /// Subscribe to realtime changes for this table filtered by clinic.
  RealtimeChannel subscribeToChanges({
    required String clinicId,
    required void Function(PostgresChangePayload payload) onData,
  }) {
    return _client
        .channel('${tableName}_$clinicId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'clinic_id',
            value: clinicId,
          ),
          callback: onData,
        )
        .subscribe();
  }
}
