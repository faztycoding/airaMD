import 'package:flutter/foundation.dart';

/// Structured logging service for airaMD.
///
/// Replaces raw `debugPrint` with tagged, leveled log output.
/// In production, only warnings and errors are printed.
/// Easily extendable to forward logs to a remote service.
///
/// Usage:
/// ```dart
/// Log.i('PatientRepo', 'Loaded 42 patients');
/// Log.w('Sync', 'Retrying in 5s...');
/// Log.e('Auth', 'Login failed', stackTrace: stack);
/// ```
class Log {
  Log._();

  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  /// Info — skipped in release builds.
  static void i(String tag, String message) {
    if (_isRelease) return;
    debugPrint('💡 [$tag] $message');
  }

  /// Debug — skipped in release builds.
  static void d(String tag, String message) {
    if (_isRelease) return;
    debugPrint('🔍 [$tag] $message');
  }

  /// Warning — always logged.
  static void w(String tag, String message) {
    debugPrint('⚠️ [$tag] $message');
  }

  /// Error — always logged, with optional stack trace.
  static void e(String tag, String message, {StackTrace? stackTrace}) {
    debugPrint('❌ [$tag] $message');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
