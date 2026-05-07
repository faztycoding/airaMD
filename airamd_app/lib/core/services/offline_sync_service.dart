import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../providers/connectivity_provider.dart';

// ═══════════════════════════════════════════════════════════════
// OFFLINE SYNC SERVICE — Queue + Local Cache
// ═══════════════════════════════════════════════════════════════

/// A pending operation queued when offline.
class PendingOperation {
  final String id;
  final String table;
  final String action; // INSERT, UPDATE, DELETE
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const PendingOperation({
    required this.id,
    required this.table,
    required this.action,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'action': action,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) => PendingOperation(
    id: json['id'] as String,
    table: json['table'] as String,
    action: json['action'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// Manages an offline queue and local cache.
///
/// Storage architecture (post-Phase-2):
///
///   - **Queue** — one JSON file per pending op under
///     `<app docs>/aira_offline_queue/<uuid>.json`. This bypasses the
///     ~4 KB per-key Keychain limit on iOS that silently truncated the
///     legacy single-blob queue, and makes individual op deletion atomic
///     (just delete the file) instead of read-modify-write the whole list.
///
///   - **Lock** — a single static [Lock] serialises every queue mutation
///     (`enqueue` / `dequeue` / `pruneOldOperations`). Concurrent writers
///     can no longer overwrite each other.
///
///   - **Op IDs** — UUID v4 (was `microsecondsSinceEpoch` which collides
///     when two ops happen in the same microsecond, e.g. rapid double-tap).
///
///   - **Cache + lastSync** — still in `flutter_secure_storage` because
///     they're small (a single JSON blob each) and don't suffer from
///     concurrent multi-writer access.
///
///   - **Migration** — the first call after upgrading reads the legacy
///     `aira_offline_queue` Keychain entry, splits it into per-op files,
///     and deletes the original key. This keeps any in-flight ops the
///     user had before installing the new build.
class OfflineSyncService {
  static const _storage = FlutterSecureStorage();
  static const _legacyQueueKey = 'aira_offline_queue';
  static const _cachePrefix = 'aira_cache_';
  static const _lastSyncKey = 'aira_last_sync';
  static const _queueDirName = 'aira_offline_queue';
  static const _migrationFlagKey = 'aira_offline_queue_migrated_v2';

  // Static lock — every queue operation goes through here.
  // ignore: unused_field
  static final Lock _lock = Lock(reentrant: true);
  static const _uuid = Uuid();

  // ─── Test seam ─────────────────────────────────────────────
  // In unit tests we override the storage root so we don't depend on
  // the platform's real getApplicationDocumentsDirectory().
  static String? _testQueueDirOverride;

  /// Override the queue directory (testing only).
  ///
  /// Pass `null` to revert to the platform default.
  @visibleForTesting
  static void debugSetQueueDir(String? path) {
    _testQueueDirOverride = path;
  }

  /// Reset all in-process state (testing only).
  @visibleForTesting
  static Future<void> debugReset() async {
    _testQueueDirOverride = null;
  }

  /// Resolve the on-disk queue directory, creating it if missing.
  static Future<Directory> _queueDir() async {
    if (_testQueueDirOverride != null) {
      final dir = Directory(_testQueueDirOverride!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_queueDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// One-shot migration from the legacy single-key Keychain queue.
  ///
  /// Idempotent — guarded by the `_migrationFlagKey` flag in secure
  /// storage. Called from every public read/write entry point so users
  /// who immediately go offline after upgrading still see their old ops.
  static Future<void> _migrateLegacyQueueIfNeeded() async {
    final flag = await _storage.read(key: _migrationFlagKey);
    if (flag == 'true') return;

    try {
      final raw = await _storage.read(key: _legacyQueueKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        final dir = await _queueDir();
        for (final entry in list) {
          try {
            final op = PendingOperation.fromJson(
              Map<String, dynamic>.from(entry as Map),
            );
            final f = File('${dir.path}/${op.id}.json');
            await f.writeAsString(jsonEncode(op.toJson()));
          } catch (e) {
            debugPrint('[OfflineSync] Skipped corrupt legacy op: $e');
          }
        }
      }
      await _storage.delete(key: _legacyQueueKey);
    } catch (e) {
      // Best-effort: even if migration fails we still flip the flag so
      // we don't retry forever and block the new file-based queue.
      debugPrint('[OfflineSync] Legacy migration error (non-fatal): $e');
    }
    await _storage.write(key: _migrationFlagKey, value: 'true');
  }

  // ─── Queue Management ──────────────────────────────────────

  /// Get all pending operations, oldest first.
  static Future<List<PendingOperation>> getPendingQueue() async {
    return _lock.synchronized(() async {
      await _migrateLegacyQueueIfNeeded();
      try {
        final dir = await _queueDir();
        if (!await dir.exists()) return <PendingOperation>[];
        final files = (await dir.list().toList())
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList();
        final ops = <PendingOperation>[];
        for (final f in files) {
          try {
            final raw = await f.readAsString();
            ops.add(PendingOperation.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            ));
          } catch (e) {
            debugPrint('[OfflineSync] Skipping corrupt op file ${f.path}: $e');
          }
        }
        ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return ops;
      } catch (e) {
        debugPrint('[OfflineSync] Error reading queue: $e');
        return <PendingOperation>[];
      }
    });
  }

  /// Add an operation to the pending queue.
  ///
  /// Always writes a fresh UUID-based id even if the caller passed
  /// something else — guarantees uniqueness across concurrent enqueues.
  static Future<void> enqueue(PendingOperation op) async {
    return _lock.synchronized(() async {
      await _migrateLegacyQueueIfNeeded();
      // Substitute a UUID id if the caller supplied a non-UUID one.
      final safeId = _looksLikeUuid(op.id) ? op.id : _uuid.v4();
      final stored = PendingOperation(
        id: safeId,
        table: op.table,
        action: op.action,
        payload: op.payload,
        createdAt: op.createdAt,
      );
      try {
        final dir = await _queueDir();
        final file = File('${dir.path}/$safeId.json');
        await file.writeAsString(jsonEncode(stored.toJson()));
        debugPrint('[OfflineSync] Enqueued: ${stored.action} '
            '${stored.table} ($safeId)');
      } catch (e) {
        debugPrint('[OfflineSync] Error enqueueing: $e');
        rethrow;
      }
    });
  }

  /// Convenience wrapper for queuing an atomic Postgres RPC call.
  ///
  /// Used when the device is offline and an `INSERT` would fall back to the
  /// generic queue: instead of replaying a non-atomic INSERT-then-update
  /// sequence, we record the original `client.rpc(...)` call so the replay
  /// preserves the same all-or-nothing transaction semantics.
  static Future<void> enqueueRpc({
    required String functionName,
    required Map<String, dynamic> params,
  }) async {
    await enqueue(PendingOperation(
      id: _uuid.v4(),
      table: functionName,
      action: 'RPC',
      payload: params,
      createdAt: DateTime.now(),
    ));
  }

  /// Remove a specific operation from the queue.
  static Future<void> dequeue(String operationId) async {
    return _lock.synchronized(() async {
      await _migrateLegacyQueueIfNeeded();
      try {
        final dir = await _queueDir();
        final file = File('${dir.path}/$operationId.json');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[OfflineSync] Error dequeueing: $e');
      }
    });
  }

  /// Clear the entire pending queue.
  static Future<void> clearQueue() async {
    return _lock.synchronized(() async {
      await _migrateLegacyQueueIfNeeded();
      try {
        final dir = await _queueDir();
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            if (entity is File && entity.path.endsWith('.json')) {
              await entity.delete();
            }
          }
        }
      } catch (e) {
        debugPrint('[OfflineSync] Error clearing queue: $e');
      }
    });
  }

  /// Get the number of pending operations.
  static Future<int> pendingCount() async {
    return _lock.synchronized(() async {
      await _migrateLegacyQueueIfNeeded();
      try {
        final dir = await _queueDir();
        if (!await dir.exists()) return 0;
        return (await dir.list().toList())
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .length;
      } catch (_) {
        return 0;
      }
    });
  }

  // ─── Local Cache ──────────────────────────────────────────

  /// Cache data locally for a given key.
  static Future<void> cacheData(String key, dynamic data) async {
    try {
      final cacheEntry = {
        'data': data,
        'cached_at': DateTime.now().toIso8601String(),
      };
      await _storage.write(key: '$_cachePrefix$key', value: jsonEncode(cacheEntry));
    } catch (e) {
      debugPrint('[OfflineSync] Error caching data for $key: $e');
    }
  }

  /// Retrieve cached data for a given key.
  static Future<dynamic> getCachedData(String key) async {
    try {
      final raw = await _storage.read(key: '$_cachePrefix$key');
      if (raw == null) return null;
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return entry['data'];
    } catch (e) {
      debugPrint('[OfflineSync] Error reading cache for $key: $e');
      return null;
    }
  }

  /// Get the cache timestamp for a key.
  static Future<DateTime?> getCacheTime(String key) async {
    try {
      final raw = await _storage.read(key: '$_cachePrefix$key');
      if (raw == null) return null;
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.tryParse(entry['cached_at'] as String);
    } catch (e) {
      return null;
    }
  }

  /// Remove a specific cache entry.
  static Future<void> clearCache(String key) async {
    await _storage.delete(key: '$_cachePrefix$key');
  }

  // ─── Sync Status ──────────────────────────────────────────

  /// Record the last successful sync time.
  static Future<void> markSynced() async {
    await _storage.write(key: _lastSyncKey, value: DateTime.now().toIso8601String());
  }

  /// Get the last successful sync time.
  static Future<DateTime?> lastSyncTime() async {
    try {
      final raw = await _storage.read(key: _lastSyncKey);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      return null;
    }
  }

  // ─── Bulk Operations ─────────────────────────────────────

  /// Get the total size of the queue in bytes (for diagnostics).
  static Future<int> queueSizeBytes() async {
    try {
      final dir = await _queueDir();
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Remove all failed operations older than [maxAge].
  static Future<int> pruneOldOperations({Duration maxAge = const Duration(days: 7)}) async {
    return _lock.synchronized(() async {
      await _migrateLegacyQueueIfNeeded();
      final cutoff = DateTime.now().subtract(maxAge);
      var removed = 0;
      try {
        final dir = await _queueDir();
        if (!await dir.exists()) return 0;
        final files = (await dir.list().toList())
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList();
        for (final f in files) {
          try {
            final raw = await f.readAsString();
            final op = PendingOperation.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            );
            if (op.createdAt.isBefore(cutoff)) {
              await f.delete();
              removed++;
            }
          } catch (_) {
            // Corrupt file — also evict.
            await f.delete();
            removed++;
          }
        }
      } catch (e) {
        debugPrint('[OfflineSync] Prune error: $e');
      }
      return removed;
    });
  }

  /// Generate a UUID for a new pending operation. Exposed so the few
  /// callers that build a [PendingOperation] inline (e.g. the auto-sync
  /// engine wrapper) get a collision-free id without importing `uuid`
  /// directly.
  static String newOperationId() => _uuid.v4();

  static bool _looksLikeUuid(String s) {
    // 8-4-4-4-12 hex with dashes. Cheap regex avoids a uuid parse cost.
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(s);
  }
}

// ─── Riverpod Providers ─────────────────────────────────────

/// Stream that indicates whether the app is currently online.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(data: (v) => v, loading: () => true, error: (_, __) => false);
});

/// The current count of pending offline operations.
final pendingOpsCountProvider = FutureProvider<int>((ref) async {
  return OfflineSyncService.pendingCount();
});

/// Last sync time.
final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  return OfflineSyncService.lastSyncTime();
});
