import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure PIN storage using PBKDF2-HMAC-SHA256.
///
/// Prior to this service the PIN was written to `flutter_secure_storage`
/// in plaintext. That only protects against a casual attacker — a device
/// with a compromised keychain (jailbreak, forensic extraction) would
/// reveal the PIN instantly, and any PIN-recovery flow that leaked the
/// keychain file would hand the attacker a login credential.
///
/// This service replaces that with a derived key scheme:
///
///   1. On `setPin`, a 16-byte random salt is generated.
///   2. The PIN is stretched via PBKDF2-HMAC-SHA256 with [_iterations]
///      rounds into a 32-byte key.
///   3. Only `{version, salt, iter, hash}` is persisted — the PIN itself
///      never touches disk.
///   4. `verifyPin` re-derives the key with the same params and performs
///      a constant-time comparison.
///
/// PBKDF2 with 150k iterations on even a current iPad takes ~200ms per
/// guess, making a brute-force of a 6-digit PIN take ~55 hours of
/// uninterrupted work. Combined with the OS keychain and the 5-minute
/// auto-lock this raises the bar well past casual attackers.
///
/// Legacy plaintext PIN records are auto-migrated the first time a user
/// enters a correct PIN after upgrade — no user-visible prompt.
class PinAuthService {
  PinAuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // ─── Storage keys ──────────────────────────────────────────
  /// Legacy plaintext PIN key (pre-hardening). Kept for one-way migration.
  static const legacyPinKey = 'airamd_pin_code';

  /// New hashed-PIN JSON blob: `{"v":1,"salt":"...","iter":150000,"hash":"..."}`.
  static const pinHashKey = 'airamd_pin_hash_v1';

  /// "true" when PIN gating is enabled.
  static const pinEnabledKey = 'airamd_pin_enabled';

  // ─── Derivation params ─────────────────────────────────────
  /// OWASP 2023 recommended minimum for PBKDF2-SHA256 is 600k, but we're
  /// guarding a 6-digit PIN that the OS keychain already protects, so a
  /// ~200ms-per-guess target (150k rounds on iPad gen-9) is the right
  /// balance between responsiveness and brute-force resistance.
  static const int _iterations = 150000;
  static const int _saltBytes = 16;
  static const int _keyBytes = 32;
  static const int _currentVersion = 1;

  /// True if any PIN (legacy plaintext OR hashed) is stored.
  Future<bool> hasPin() async {
    final hashed = await _storage.read(key: pinHashKey);
    if (hashed != null && hashed.isNotEmpty) return true;
    final legacy = await _storage.read(key: legacyPinKey);
    return legacy != null && legacy.isNotEmpty;
  }

  /// True when PIN gating is explicitly enabled.
  Future<bool> isEnabled() async {
    final v = await _storage.read(key: pinEnabledKey);
    return v == 'true';
  }

  /// Hash and persist the PIN. Also marks PIN gating as enabled and
  /// removes any legacy plaintext entry.
  Future<void> setPin(String pin) async {
    _validatePinFormat(pin);
    final record = _deriveRecord(pin);
    await _storage.write(key: pinHashKey, value: jsonEncode(record));
    await _storage.write(key: pinEnabledKey, value: 'true');
    // Drop the legacy plaintext record so it can't be read back later.
    await _storage.delete(key: legacyPinKey);
  }

  /// Verify an entered PIN against the stored record. Auto-migrates any
  /// legacy plaintext PIN to the hashed format on a successful match.
  Future<bool> verifyPin(String pin) async {
    final hashedJson = await _storage.read(key: pinHashKey);
    if (hashedJson != null && hashedJson.isNotEmpty) {
      return _verifyAgainstHash(pin, hashedJson);
    }
    // Legacy plaintext path: compare, and if correct, migrate.
    final legacy = await _storage.read(key: legacyPinKey);
    if (legacy != null && legacy.isNotEmpty) {
      if (_constantTimeStringEquals(pin, legacy)) {
        await setPin(pin); // upgrade in place
        return true;
      }
    }
    return false;
  }

  /// Remove all PIN state — used by "forgot PIN" and sign-out flows.
  Future<void> clearPin() async {
    await _storage.delete(key: pinHashKey);
    await _storage.delete(key: legacyPinKey);
    await _storage.delete(key: pinEnabledKey);
  }

  // ─── Internals ─────────────────────────────────────────────

  /// Only allow 4-8 digit numeric PINs — wider than the current UI, but
  /// rejects obviously malformed input before we burn iteration cycles.
  void _validatePinFormat(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      throw ArgumentError('PIN must be 4-8 digits');
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw ArgumentError('PIN must be numeric');
    }
  }

  Map<String, dynamic> _deriveRecord(String pin) {
    final salt = _randomBytes(_saltBytes);
    final hash = _pbkdf2(pin, salt, _iterations, _keyBytes);
    return {
      'v': _currentVersion,
      'iter': _iterations,
      'salt': base64Encode(salt),
      'hash': base64Encode(hash),
    };
  }

  bool _verifyAgainstHash(String pin, String recordJson) {
    try {
      final record = jsonDecode(recordJson) as Map<String, dynamic>;
      final salt = base64Decode(record['salt'] as String);
      final expected = base64Decode(record['hash'] as String);
      final iter = record['iter'] as int;
      final actual = _pbkdf2(pin, salt, iter, expected.length);
      return _constantTimeBytesEquals(actual, expected);
    } catch (_) {
      // Corrupted record — treat as mismatch. Caller can offer "forgot PIN".
      return false;
    }
  }

  Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  /// PBKDF2-HMAC-SHA256. Implemented directly because `package:crypto`
  /// ships HMAC but no PBKDF2 primitive, and we want to avoid adding a
  /// heavier crypto dependency for a 20-line function.
  Uint8List _pbkdf2(String password, List<int> salt, int iterations, int keyLen) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final hashLen = sha256.convert([]).bytes.length; // 32
    final blockCount = (keyLen / hashLen).ceil();
    final out = BytesBuilder();

    for (var block = 1; block <= blockCount; block++) {
      final blockIdx = Uint8List(4)
        ..[0] = (block >> 24) & 0xff
        ..[1] = (block >> 16) & 0xff
        ..[2] = (block >> 8) & 0xff
        ..[3] = block & 0xff;

      var u = hmac.convert([...salt, ...blockIdx]).bytes;
      final result = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

      out.add(result);
    }

    final bytes = out.toBytes();
    return Uint8List.sublistView(bytes, 0, keyLen);
  }

  /// Constant-time byte comparison — avoids early-exit timing oracles.
  bool _constantTimeBytesEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  bool _constantTimeStringEquals(String a, String b) {
    final ab = utf8.encode(a);
    final bb = utf8.encode(b);
    return _constantTimeBytesEquals(ab, bb);
  }
}

/// Shared singleton — the service is stateless apart from the storage
/// handle, so there is no reason to instantiate it per-call.
final pinAuthService = PinAuthService();
