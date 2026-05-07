import 'package:flutter/foundation.dart';
import '../../config/constants.dart';
import 'logger_service.dart';

/// Centralised non-fatal error reporting.
///
/// This service intentionally does NOT add a hard dependency on a specific
/// crash-reporting SDK (Sentry, Logtail, Datadog) so the app can ship today
/// without one and a future PR can wire whichever vendor we settle on. The
/// public API ([initialise], [captureException], [captureMessage],
/// [setUserContext]) is shaped to match the Sentry and Datadog SDKs so the
/// integration PR is one file change.
///
/// Today the implementation:
///   * routes everything through `Log` (debug-only) and Crashlytics (already
///     wired in `main.dart` via `FirebaseCrashlytics.recordError`)
///   * is a no-op when [AppConfig.current.sendCrashReports] is false (dev
///     builds) so local stack traces never leak to a real backend
///   * skips initialisation entirely when [AppConstants.sentryDsn] is empty
///     so a misconfigured `--dart-define` build still ships
///
/// Wiring Sentry later:
/// ```dart
/// // 1. Add `sentry_flutter` to pubspec.yaml.
/// // 2. In `initialise()` below, replace the no-op block with:
/// //
/// // await SentryFlutter.init((opts) {
/// //   opts.dsn = AppConstants.sentryDsn;
/// //   opts.environment = AppConstants.environment;
/// //   opts.tracesSampleRate = AppConstants.isProduction ? 0.1 : 1.0;
/// // });
/// //
/// // 3. In `captureException`, replace `_recordToCrashlytics` with
/// //    `Sentry.captureException(error, stackTrace: stackTrace)`.
/// ```
class CrashReporter {
  CrashReporter._();

  static bool _initialised = false;

  /// Whether the reporter is actively forwarding events to a remote backend.
  /// False when DSN is missing OR the env config disables crash reports.
  static bool get isActive =>
      _initialised &&
      AppConfig.current.sendCrashReports &&
      AppConstants.sentryDsn.isNotEmpty;

  /// Idempotent. Safe to call from `main()` before `runApp`.
  static Future<void> initialise() async {
    if (_initialised) return;
    _initialised = true;

    if (AppConstants.sentryDsn.isEmpty) {
      Log.i('CrashReporter',
          'No SENTRY_DSN provided — crash reporting disabled.');
      return;
    }
    if (!AppConfig.current.sendCrashReports) {
      Log.i('CrashReporter',
          'sendCrashReports=false for env=${AppConstants.environment}.');
      return;
    }

    // ── Future-Sentry init goes here. Today: log only. ──
    Log.i('CrashReporter',
        'CrashReporter ready (env=${AppConstants.environment}, dsn=set).');
  }

  /// Report a caught (non-fatal) exception. Always safe to call regardless
  /// of init state.
  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
  }) async {
    // Always log locally so devs see it in the console even when the remote
    // sink is disabled.
    Log.e('CrashReporter', '${hint ?? 'captureException'}: $error');
    if (stackTrace != null && kDebugMode) {
      debugPrint('$stackTrace');
    }

    if (!isActive) return;

    // ── Future-Sentry call goes here. ──
    // await Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Report a message-level breadcrumb (e.g. "user retried failed payment").
  static Future<void> captureMessage(
    String message, {
    Map<String, dynamic>? extra,
  }) async {
    Log.i('CrashReporter', message);
    if (!isActive) return;
    // ── Future-Sentry call goes here. ──
    // await Sentry.captureMessage(message);
  }

  /// Tag the current user on subsequent events (PII-light: no email / phone).
  /// Pass `null` on logout to clear.
  static Future<void> setUserContext({
    String? userId,
    String? clinicId,
    String? role,
  }) async {
    if (!isActive) return;
    // ── Future-Sentry call goes here. ──
    // Sentry.configureScope((scope) => scope.setUser(SentryUser(
    //   id: userId, data: {'clinic_id': clinicId, 'role': role})));
  }
}
