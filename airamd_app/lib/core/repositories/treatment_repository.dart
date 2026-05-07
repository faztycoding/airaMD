import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/offline_sync_service.dart';
import 'base_repository.dart';
import 'inventory_op.dart';
import 'repository_exceptions.dart';

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

  /// Atomically create a treatment record together with all of its inventory
  /// transactions in a single Postgres transaction.
  ///
  /// Backed by the `record_treatment_atomic` RPC introduced in migration 009.
  /// Either the treatment row, every inventory_transactions row, AND the
  /// per-product stock deduction all succeed, or nothing is persisted —
  /// eliminating the partial-state class of bugs the old multi-call flow had.
  ///
  /// Throws [InsufficientStockException] when any product op exceeds its
  /// available stock, [InvalidQuantityException] for non-positive quantities,
  /// and rethrows any other [PostgrestException] unchanged.
  Future<TreatmentRecord> createWithInventory({
    required TreatmentRecord record,
    required List<InventoryOp> inventory,
  }) async {
    // Forward the client-generated UUID so the saved row keeps the same id
    // the offline queue / audit log / follow-up-appointment notes already
    // reference. The RPC uses `COALESCE(r.id, gen_random_uuid())` so an
    // empty id still works.
    final treatmentPayload = <String, dynamic>{
      ...record.toInsertJson(),
      if (record.id.isNotEmpty) 'id': record.id,
    };
    final params = <String, dynamic>{
      'p_treatment': treatmentPayload,
      'p_inventory': inventory.map((op) => op.toJson()).toList(),
    };

    try {
      final result = await client.rpc(
        'record_treatment_atomic',
        params: params,
      );
      // The RPC returns the inserted row as JSONB which arrives as a Map.
      return TreatmentRecord.fromJson(
        Map<String, dynamic>.from(result as Map),
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('insufficient_stock')) {
        throw InsufficientStockException(cause: e);
      }
      if (e.message.contains('quantity_must_be_positive')) {
        throw InvalidQuantityException(e);
      }
      rethrow;
    } on Exception catch (e) {
      // Network / DNS / socket failures bubble up as plain Exceptions and
      // are the signal that we're offline. Queue the same RPC params for
      // replay when connectivity returns — the AutoSyncEngine handles `RPC`
      // ops as `client.rpc(table, params: payload)` so the deferred save is
      // still atomic. We rethrow afterwards so callers can show "saved
      // offline, will sync" UX instead of swallowing the failure.
      if (_looksLikeNetworkError(e)) {
        await OfflineSyncService.enqueueRpc(
          functionName: 'record_treatment_atomic',
          params: params,
        );
      }
      rethrow;
    }
  }

  /// Heuristic for "this exception means the device is offline / the host
  /// is unreachable" vs. "this is a real server / validation error". We
  /// keep it as a string match because supabase-flutter wraps the
  /// underlying SocketException / TimeoutException in different layers
  /// across platforms.
  static bool _looksLikeNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection refused') ||
        s.contains('connection closed') ||
        s.contains('timeout') ||
        s.contains('network is unreachable');
  }

  Future<TreatmentRecord> updateRecord(TreatmentRecord record) async {
    final data = await update(record.id, record.toUpdateJson());
    return TreatmentRecord.fromJson(data);
  }

  /// Optimistic-concurrency update.
  ///
  /// The caller passes the [expectedVersion] they last fetched. The DB's
  /// `bump_treatment_version` trigger raises `version_conflict` (SQLSTATE
  /// P0002) when the row has moved on under our feet, which we surface as
  /// [VersionConflictException] so the UI can prompt the user to refresh.
  Future<TreatmentRecord> updateRecordVersioned({
    required TreatmentRecord record,
    required int expectedVersion,
  }) async {
    try {
      final payload = {
        ...record.toUpdateJson(),
        'version': expectedVersion,
      };
      final data = await update(record.id, payload);
      return TreatmentRecord.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.message.contains('version_conflict')) {
        throw VersionConflictException(e);
      }
      rethrow;
    }
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

  /// Get treatments for a specific calendar day **in the device's local
  /// timezone**.
  ///
  /// `treatment_records.date` is stored as `TIMESTAMPTZ`, so we send full
  /// ISO-8601 instants (`gte` start-of-day, `lt` start-of-next-day) instead
  /// of comparing date prefixes as strings. The previous prefix-string
  /// approach silently shifted by one day for users whose `date` value sat
  /// near midnight UTC.
  Future<List<TreatmentRecord>> getByDate({
    required String clinicId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final startOfNext = startOfDay.add(const Duration(days: 1));

    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .gte('date', startOfDay.toUtc().toIso8601String())
        .lt('date', startOfNext.toUtc().toIso8601String())
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
