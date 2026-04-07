import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

/// Manages an offline queue and local cache using secure storage.
class OfflineSyncService {
  static const _storage = FlutterSecureStorage();
  static const _queueKey = 'aira_offline_queue';
  static const _cachePrefix = 'aira_cache_';
  static const _lastSyncKey = 'aira_last_sync';

  // ─── Queue Management ──────────────────────────────────────

  /// Get all pending operations.
  static Future<List<PendingOperation>> getPendingQueue() async {
    try {
      final raw = await _storage.read(key: _queueKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => PendingOperation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[OfflineSync] Error reading queue: $e');
      return [];
    }
  }

  /// Add an operation to the pending queue.
  static Future<void> enqueue(PendingOperation op) async {
    final queue = await getPendingQueue();
    queue.add(op);
    await _storage.write(key: _queueKey, value: jsonEncode(queue.map((e) => e.toJson()).toList()));
    debugPrint('[OfflineSync] Enqueued: ${op.action} ${op.table} (${op.id})');
  }

  /// Remove a specific operation from the queue.
  static Future<void> dequeue(String operationId) async {
    final queue = await getPendingQueue();
    queue.removeWhere((op) => op.id == operationId);
    await _storage.write(key: _queueKey, value: jsonEncode(queue.map((e) => e.toJson()).toList()));
  }

  /// Clear the entire pending queue.
  static Future<void> clearQueue() async {
    await _storage.delete(key: _queueKey);
  }

  /// Get the number of pending operations.
  static Future<int> pendingCount() async {
    final queue = await getPendingQueue();
    return queue.length;
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
      final raw = await _storage.read(key: _queueKey);
      return raw?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Remove all failed operations older than [maxAge].
  static Future<int> pruneOldOperations({Duration maxAge = const Duration(days: 7)}) async {
    final queue = await getPendingQueue();
    final cutoff = DateTime.now().subtract(maxAge);
    final before = queue.length;
    queue.removeWhere((op) => op.createdAt.isBefore(cutoff));
    if (queue.length != before) {
      await _storage.write(key: _queueKey, value: jsonEncode(queue.map((e) => e.toJson()).toList()));
    }
    return before - queue.length;
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
