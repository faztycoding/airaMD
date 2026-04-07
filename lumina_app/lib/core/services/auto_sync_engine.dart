import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'offline_sync_service.dart';

// ═══════════════════════════════════════════════════════════════
// AUTO-SYNC ENGINE — Processes queue when online + local cache
// ═══════════════════════════════════════════════════════════════

/// Sync result for a single operation.
class SyncResult {
  final String operationId;
  final bool success;
  final String? error;
  const SyncResult({required this.operationId, required this.success, this.error});
}

/// Auto-sync engine that:
/// 1. Monitors connectivity changes
/// 2. Processes pending queue when back online
/// 3. Caches data locally for offline reads
class AutoSyncEngine {
  static AutoSyncEngine? _instance;
  static AutoSyncEngine get instance => _instance ??= AutoSyncEngine._();

  AutoSyncEngine._();

  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;
  Timer? _retryTimer;
  final _syncStateController = StreamController<SyncState>.broadcast();

  /// Stream of sync state changes.
  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  /// Start listening for connectivity changes.
  void start() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (isOnline && !_isSyncing) {
        processQueue();
      }
    });

    // Also try syncing immediately on start
    processQueue();
    debugPrint('[AutoSync] Engine started');
  }

  /// Stop the sync engine.
  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    debugPrint('[AutoSync] Engine stopped');
  }

  /// Process all pending operations in the queue.
  Future<List<SyncResult>> processQueue() async {
    if (_isSyncing) return [];

    _isSyncing = true;
    _syncStateController.add(SyncState.syncing);
    final results = <SyncResult>[];

    try {
      final queue = await OfflineSyncService.getPendingQueue();
      if (queue.isEmpty) {
        _syncStateController.add(SyncState.synced);
        _isSyncing = false;
        return results;
      }

      debugPrint('[AutoSync] Processing ${queue.length} pending operations...');
      final client = Supabase.instance.client;

      for (final op in queue) {
        try {
          switch (op.action) {
            case 'INSERT':
              await client.from(op.table).insert(op.payload);
              break;
            case 'UPDATE':
              final id = op.payload.remove('_id');
              if (id != null) {
                await client.from(op.table).update(op.payload).eq('id', id);
              }
              break;
            case 'DELETE':
              final id = op.payload['id'];
              if (id != null) {
                await client.from(op.table).delete().eq('id', id);
              }
              break;
            case 'UPSERT':
              await client.from(op.table).upsert(op.payload);
              break;
          }

          // Successfully synced — remove from queue
          await OfflineSyncService.dequeue(op.id);
          results.add(SyncResult(operationId: op.id, success: true));
          debugPrint('[AutoSync] ✓ Synced: ${op.action} ${op.table}');
        } catch (e) {
          results.add(SyncResult(operationId: op.id, success: false, error: '$e'));
          debugPrint('[AutoSync] ✗ Failed: ${op.action} ${op.table}: $e');
        }
      }

      await OfflineSyncService.markSynced();
      _syncStateController.add(SyncState.synced);

      // Schedule retry for failed ops
      final failedCount = results.where((r) => !r.success).length;
      if (failedCount > 0) {
        _scheduleRetry();
        _syncStateController.add(SyncState.partialError);
      }
    } catch (e) {
      debugPrint('[AutoSync] Queue processing error: $e');
      _syncStateController.add(SyncState.error);
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }

    return results;
  }

  /// Schedule a retry after failure.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      processQueue();
    });
  }

  /// Dispose the engine.
  void dispose() {
    stop();
    _syncStateController.close();
  }
}

/// Sync states.
enum SyncState { idle, syncing, synced, partialError, error }

// ═══════════════════════════════════════════════════════════════
// LOCAL DATA CACHE — File-based cache for offline reads
// ═══════════════════════════════════════════════════════════════

class LocalDataCache {
  static const _cacheDirName = 'aira_cache';

  /// Get the cache directory.
  static Future<Directory> _cacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Cache a list of records for a table + clinic.
  static Future<void> cacheTableData({
    required String table,
    required String clinicId,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${table}_$clinicId.json');
      final cacheEntry = {
        'data': data,
        'cached_at': DateTime.now().toIso8601String(),
        'count': data.length,
      };
      await file.writeAsString(jsonEncode(cacheEntry));
      debugPrint('[LocalCache] Cached ${data.length} records for $table');
    } catch (e) {
      debugPrint('[LocalCache] Cache write error for $table: $e');
    }
  }

  /// Read cached data for a table + clinic.
  static Future<List<Map<String, dynamic>>?> readTableData({
    required String table,
    required String clinicId,
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${table}_$clinicId.json');
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      final entry = jsonDecode(raw) as Map<String, dynamic>;

      // Check cache age
      final cachedAt = DateTime.tryParse(entry['cached_at'] as String? ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt) > maxAge) {
        return null; // Cache expired
      }

      final data = (entry['data'] as List).cast<Map<String, dynamic>>();
      debugPrint('[LocalCache] Read ${data.length} cached records for $table');
      return data;
    } catch (e) {
      debugPrint('[LocalCache] Cache read error for $table: $e');
      return null;
    }
  }

  /// Get the last cache time for a table.
  static Future<DateTime?> lastCacheTime({
    required String table,
    required String clinicId,
  }) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${table}_$clinicId.json');
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.tryParse(entry['cached_at'] as String? ?? '');
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data.
  static Future<void> clearAll() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[LocalCache] Clear error: $e');
    }
  }

  /// Clear cache for a specific table.
  static Future<void> clearTable({
    required String table,
    required String clinicId,
  }) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${table}_$clinicId.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[LocalCache] Clear table error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// OFFLINE-AWARE REPOSITORY WRAPPER
// ═══════════════════════════════════════════════════════════════

/// Wraps Supabase calls with offline queue + cache support.
class OfflineAwareRepository {
  final SupabaseClient _client;

  OfflineAwareRepository(this._client);

  /// Fetch data with offline cache fallback.
  Future<List<Map<String, dynamic>>> getWithCache({
    required String table,
    required String clinicId,
    required Future<List<Map<String, dynamic>>> Function() onlineFetch,
    Duration cacheMaxAge = const Duration(hours: 24),
  }) async {
    try {
      // Try online fetch first
      final data = await onlineFetch();

      // Cache the result for offline use
      await LocalDataCache.cacheTableData(
        table: table,
        clinicId: clinicId,
        data: data,
      );

      return data;
    } catch (e) {
      // Offline or error — try cache
      debugPrint('[OfflineAware] Online fetch failed for $table, trying cache: $e');
      final cached = await LocalDataCache.readTableData(
        table: table,
        clinicId: clinicId,
        maxAge: cacheMaxAge,
      );

      if (cached != null) {
        return cached;
      }

      // No cache available — rethrow
      rethrow;
    }
  }

  /// Insert data with offline queue fallback.
  Future<Map<String, dynamic>> insertWithQueue({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final result = await _client.from(table).insert(data).select().single();
      return result;
    } catch (e) {
      // Queue for later sync
      debugPrint('[OfflineAware] Insert failed, queuing: $e');
      final op = PendingOperation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        table: table,
        action: 'INSERT',
        payload: data,
        createdAt: DateTime.now(),
      );
      await OfflineSyncService.enqueue(op);

      // Return the data with a temp ID so the UI can continue
      return {...data, 'id': 'pending_${op.id}', '_offline': true};
    }
  }

  /// Update data with offline queue fallback.
  Future<Map<String, dynamic>> updateWithQueue({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final result = await _client.from(table).update(data).eq('id', id).select().single();
      return result;
    } catch (e) {
      debugPrint('[OfflineAware] Update failed, queuing: $e');
      final op = PendingOperation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        table: table,
        action: 'UPDATE',
        payload: {...data, '_id': id},
        createdAt: DateTime.now(),
      );
      await OfflineSyncService.enqueue(op);
      return {...data, 'id': id, '_offline': true};
    }
  }

  /// Delete data with offline queue fallback.
  Future<void> deleteWithQueue({
    required String table,
    required String id,
  }) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('[OfflineAware] Delete failed, queuing: $e');
      final op = PendingOperation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        table: table,
        action: 'DELETE',
        payload: {'id': id},
        createdAt: DateTime.now(),
      );
      await OfflineSyncService.enqueue(op);
    }
  }
}

// ─── Riverpod Providers ─────────────────────────────────────

/// Auto-sync engine singleton provider.
final autoSyncEngineProvider = Provider<AutoSyncEngine>((ref) {
  final engine = AutoSyncEngine.instance;
  engine.start();
  ref.onDispose(() => engine.stop());
  return engine;
});

/// Sync state stream provider.
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final engine = ref.watch(autoSyncEngineProvider);
  return engine.syncStateStream;
});

/// Offline-aware repository provider.
final offlineAwareRepoProvider = Provider<OfflineAwareRepository>((ref) {
  return OfflineAwareRepository(Supabase.instance.client);
});
