import 'dart:convert';

import 'package:airamd/core/services/pin_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests run against an in-memory fake of [FlutterSecureStorage] — we don't
/// need real keychain behaviour to exercise PBKDF2 derivation, migration of
/// legacy plaintext PINs, and constant-time comparison.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('PinAuthService — PBKDF2 hashing', () {
    test('setPin persists only a hash record, never the raw PIN', () async {
      const storage = FlutterSecureStorage();
      final svc = PinAuthService(storage: storage);

      await svc.setPin('246810');

      final raw = await storage.read(key: PinAuthService.legacyPinKey);
      expect(raw, isNull,
          reason: 'legacy plaintext key must never be written by setPin');

      final hashJson = await storage.read(key: PinAuthService.pinHashKey);
      expect(hashJson, isNotNull);
      final record = jsonDecode(hashJson!) as Map<String, dynamic>;
      expect(record['v'], 1);
      expect(record['iter'], greaterThanOrEqualTo(100000),
          reason: 'PBKDF2 iteration count must meet the hardening target');
      expect(record['salt'], isA<String>());
      expect(record['hash'], isA<String>());
      // The persisted blob must not contain the plaintext PIN anywhere.
      expect(hashJson.contains('246810'), isFalse);

      final enabled = await storage.read(key: PinAuthService.pinEnabledKey);
      expect(enabled, 'true');
    });

    test('verifyPin returns true for a matching PIN and false otherwise',
        () async {
      final svc = PinAuthService();

      await svc.setPin('135790');

      expect(await svc.verifyPin('135790'), isTrue);
      expect(await svc.verifyPin('135791'), isFalse);
      expect(await svc.verifyPin(''), isFalse);
    });

    test('salt is unique per setPin call — same PIN yields different hashes',
        () async {
      final svc = PinAuthService();

      await svc.setPin('000000');
      final first = await const FlutterSecureStorage()
          .read(key: PinAuthService.pinHashKey);

      await svc.setPin('000000');
      final second = await const FlutterSecureStorage()
          .read(key: PinAuthService.pinHashKey);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, isNot(equals(second)),
          reason: 'identical PINs must derive different hashes via random salt');
    });

    test('legacy plaintext PIN is accepted once then migrated to hash',
        () async {
      // Simulate an upgraded install that still has the old plaintext entry.
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        PinAuthService.legacyPinKey: '112233',
        PinAuthService.pinEnabledKey: 'true',
      });
      final svc = PinAuthService();

      expect(await svc.hasPin(), isTrue,
          reason: 'legacy entry must count as configured');
      expect(await svc.verifyPin('000000'), isFalse,
          reason: 'wrong PIN must not trigger migration');

      final okFirst = await svc.verifyPin('112233');
      expect(okFirst, isTrue);

      // After the first successful verify, the plaintext entry should be
      // deleted and replaced with a hash.
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: PinAuthService.legacyPinKey), isNull,
          reason: 'legacy key must be removed on migration');
      final hashJson = await storage.read(key: PinAuthService.pinHashKey);
      expect(hashJson, isNotNull);

      // Subsequent verifies take the hashed path.
      expect(await svc.verifyPin('112233'), isTrue);
      expect(await svc.verifyPin('999999'), isFalse);
    });

    test('clearPin removes all PIN state (hash + legacy + enabled flag)',
        () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        PinAuthService.legacyPinKey: '777777',
        PinAuthService.pinEnabledKey: 'true',
      });
      final svc = PinAuthService();
      await svc.setPin('654321');
      expect(await svc.hasPin(), isTrue);

      await svc.clearPin();

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: PinAuthService.pinHashKey), isNull);
      expect(await storage.read(key: PinAuthService.legacyPinKey), isNull);
      expect(await storage.read(key: PinAuthService.pinEnabledKey), isNull);
      expect(await svc.hasPin(), isFalse);
      expect(await svc.isEnabled(), isFalse);
    });

    test('setPin rejects non-numeric and out-of-range PINs', () async {
      final svc = PinAuthService();
      expect(() => svc.setPin('abc123'), throwsArgumentError);
      expect(() => svc.setPin('12'), throwsArgumentError,
          reason: 'too short');
      expect(() => svc.setPin('123456789'), throwsArgumentError,
          reason: 'too long');
    });

    test('corrupted hash record returns false instead of throwing', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        PinAuthService.pinHashKey: '{not-valid-json',
        PinAuthService.pinEnabledKey: 'true',
      });
      final svc = PinAuthService();

      // Must not throw — the lock screen relies on false to fall back to a
      // setup / recovery flow instead of crashing the app.
      expect(await svc.verifyPin('000000'), isFalse);
    });
  });
}
