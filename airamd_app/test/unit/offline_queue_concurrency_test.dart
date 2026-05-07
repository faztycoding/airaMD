import 'dart:io';

import 'package:airamd/core/services/offline_sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Bind Flutter so flutter_secure_storage's mock channel works.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tempRoot = await Directory.systemTemp.createTemp('aira_offline_test_');
    // The queue uses debugSetQueueDir to redirect file I/O off the
    // real getApplicationDocumentsDirectory() — no path_provider stub
    // needed for these tests.
    OfflineSyncService.debugSetQueueDir('${tempRoot.path}/aira_offline_queue');
    await OfflineSyncService.clearQueue();
  });

  tearDown(() async {
    OfflineSyncService.debugSetQueueDir(null);
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('OfflineSyncService — file-based queue', () {
    test('enqueue persists ops as separate files under the queue dir', () async {
      final op = PendingOperation(
        id: OfflineSyncService.newOperationId(),
        table: 'patients',
        action: 'INSERT',
        payload: const {'first_name': 'Alice'},
        createdAt: DateTime.utc(2026, 5, 8, 1, 0),
      );

      await OfflineSyncService.enqueue(op);

      final dir = Directory('${tempRoot.path}/aira_offline_queue');
      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1),
          reason: 'each op should be its own file, no shared blob');
      expect(files.single.path.endsWith('.json'), isTrue);
      // The filename must be the UUID, not a timestamp string.
      expect(files.single.uri.pathSegments.last,
          matches(r'^[0-9a-fA-F-]{36}\.json$'));
    });

    test('concurrent enqueue does NOT lose ops (regression for the race)',
        () async {
      // 50 concurrent enqueue calls — old impl read-modify-wrote the
      // single-key blob and dropped most of them. New impl serialises
      // through Lock and writes a separate file per op.
      const total = 50;
      final futures = List.generate(
        total,
        (i) => OfflineSyncService.enqueue(PendingOperation(
          id: OfflineSyncService.newOperationId(),
          table: 'appointments',
          action: 'INSERT',
          payload: {'index': i},
          createdAt: DateTime.utc(2026, 5, 8).add(Duration(microseconds: i)),
        )),
      );
      await Future.wait(futures);

      final queue = await OfflineSyncService.getPendingQueue();
      expect(queue, hasLength(total),
          reason: 'every concurrent enqueue must survive');

      // Every payload index 0..49 should appear exactly once.
      final indices = queue
          .map((o) => o.payload['index'] as int)
          .toList()
        ..sort();
      expect(indices, List.generate(total, (i) => i));
    });

    test('enqueue replaces non-UUID ids with a fresh UUID', () async {
      // The legacy auto-sync engine used millisecondsSinceEpoch — those
      // strings still flow in through old persisted callers / tests.
      // The service must not trust them.
      final op = PendingOperation(
        id: '1730000000123', // legacy timestamp string
        table: 'patients',
        action: 'INSERT',
        payload: const {'first_name': 'Bob'},
        createdAt: DateTime.utc(2026, 5, 8, 1, 0),
      );
      await OfflineSyncService.enqueue(op);

      final queue = await OfflineSyncService.getPendingQueue();
      expect(queue, hasLength(1));
      expect(queue.single.id, isNot('1730000000123'),
          reason: 'service should rewrite legacy id to a UUID');
      expect(queue.single.id, matches(r'^[0-9a-fA-F-]{36}$'));
    });

    test('dequeue removes a single op file without touching siblings',
        () async {
      final ids = <String>[];
      for (var i = 0; i < 3; i++) {
        final id = OfflineSyncService.newOperationId();
        ids.add(id);
        await OfflineSyncService.enqueue(PendingOperation(
          id: id,
          table: 'patients',
          action: 'INSERT',
          payload: {'i': i},
          createdAt: DateTime.utc(2026, 5, 8).add(Duration(seconds: i)),
        ));
      }
      expect(await OfflineSyncService.pendingCount(), 3);

      await OfflineSyncService.dequeue(ids[1]);

      final remaining = await OfflineSyncService.getPendingQueue();
      expect(remaining.map((o) => o.id), unorderedEquals([ids[0], ids[2]]));
    });

    test('clearQueue removes every op file', () async {
      for (var i = 0; i < 5; i++) {
        await OfflineSyncService.enqueue(PendingOperation(
          id: OfflineSyncService.newOperationId(),
          table: 't',
          action: 'INSERT',
          payload: {'i': i},
          createdAt: DateTime.utc(2026, 5, 8).add(Duration(seconds: i)),
        ));
      }
      expect(await OfflineSyncService.pendingCount(), 5);

      await OfflineSyncService.clearQueue();
      expect(await OfflineSyncService.pendingCount(), 0);
    });

    test('pruneOldOperations evicts ops older than maxAge', () async {
      final old = PendingOperation(
        id: OfflineSyncService.newOperationId(),
        table: 't',
        action: 'INSERT',
        payload: const {},
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      final fresh = PendingOperation(
        id: OfflineSyncService.newOperationId(),
        table: 't',
        action: 'INSERT',
        payload: const {},
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await OfflineSyncService.enqueue(old);
      await OfflineSyncService.enqueue(fresh);

      final removed = await OfflineSyncService.pruneOldOperations(
        maxAge: const Duration(days: 7),
      );
      expect(removed, 1);
      final left = await OfflineSyncService.getPendingQueue();
      expect(left.map((o) => o.id), [fresh.id]);
    });

    test('legacy single-key Keychain queue is migrated on first read',
        () async {
      // Prepare a legacy blob in the secure storage mock.
      const legacyJson =
          '[{"id":"legacy-1","table":"patients","action":"INSERT",'
          '"payload":{"first_name":"Migrated"},'
          '"created_at":"2026-04-01T10:00:00.000Z"}]';
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'aira_offline_queue': legacyJson,
      });
      // Reset the migration flag so the service tries the migration.
      const FlutterSecureStorage()
          .delete(key: 'aira_offline_queue_migrated_v2');

      final queue = await OfflineSyncService.getPendingQueue();
      expect(queue, hasLength(1),
          reason: 'legacy ops must reappear under the new file storage');
      expect(queue.single.payload['first_name'], 'Migrated');

      // Subsequent reads must NOT re-import (flag should be set).
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'aira_offline_queue'), isNull,
          reason: 'legacy key should be deleted post-migration');
      expect(
        await storage.read(key: 'aira_offline_queue_migrated_v2'),
        'true',
      );
    });

    test('newOperationId returns a unique UUID v4 each call', () {
      final ids = List.generate(100, (_) => OfflineSyncService.newOperationId());
      expect(ids.toSet(), hasLength(100));
      for (final id in ids) {
        expect(id, matches(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-'
            r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'));
      }
    });
  });
}
