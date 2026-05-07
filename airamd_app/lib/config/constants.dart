/// App-wide constants.
///
/// Anything that has to vary per build (dev / staging / prod) reads from
/// `--dart-define` so credentials and DSNs never live in source control.
/// `AppConfig` below derives env-specific defaults (log level, cache TTLs,
/// auto-lock window) from the `ENV` flag.
class AppConstants {
  AppConstants._();

  static const String appName = 'airaMD';
  static const String appVersion = '1.0.0';

  // ─── Environment (injected via --dart-define) ──────────────
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  static bool get isProduction => environment == 'prod';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => !isProduction && !isStaging;

  // Supabase — injected via --dart-define, never hardcoded.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // Optional Sentry DSN. Empty in dev means "don't initialise Sentry".
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // Storage bucket names.
  static const String bucketPatientPhotos = 'patient-photos';
  static const String bucketFaceDiagrams = 'face-diagrams';
  static const String bucketConsentSignatures = 'consent-signatures';
  static const String bucketConsentPdfs = 'consent-pdfs';
  static const String bucketNotepads = 'notepads';

  // Image compression.
  static const int imageMaxWidth = 2048;
  static const int imageQuality = 80;
  static const int thumbnailWidth = 400;

  // Treatment interval rules (days) — configurable in settings.
  static const Map<String, Map<String, int>> treatmentIntervals = {
    'BOTOX': {'min': 60, 'recommended': 90},
    'FILLER': {'min': 120, 'recommended': 180},
    'LASER': {'min': 21, 'recommended': 30},
    'HIFU': {'min': 90, 'recommended': 180},
  };

  // Auto-lock timeout (minutes) — overridable per environment via
  // [AppConfig.autoLockTimeout].
  static const int autoLockTimeout = 5;

  // PIN length.
  static const int pinLength = 6;
}

/// Environment-specific behaviour knobs.
///
/// Reading these through `AppConfig.current` instead of hard-coded literals
/// keeps the call sites the same across dev / staging / prod, while letting
/// us tune logging verbosity, cache freshness, retry behaviour, and the
/// auto-lock window per environment without touching feature code.
class AppConfig {
  final Duration apiTimeout;
  final Duration cacheMaxAge;
  final int syncRetrySeconds;
  final int autoLockMinutes;
  final bool verboseLogs;
  final bool sendCrashReports;
  final bool requireBiometricUnlock;

  const AppConfig({
    required this.apiTimeout,
    required this.cacheMaxAge,
    required this.syncRetrySeconds,
    required this.autoLockMinutes,
    required this.verboseLogs,
    required this.sendCrashReports,
    required this.requireBiometricUnlock,
  });

  /// The active config for the current build, derived from `ENV`.
  static AppConfig get current {
    if (AppConstants.isProduction) return _prod;
    if (AppConstants.isStaging) return _staging;
    return _dev;
  }

  static const AppConfig _dev = AppConfig(
    apiTimeout: Duration(seconds: 30),
    cacheMaxAge: Duration(hours: 1),
    syncRetrySeconds: 10,
    autoLockMinutes: 30, // generous so we don't fight the IDE during dev
    verboseLogs: true,
    sendCrashReports: false,
    requireBiometricUnlock: false,
  );

  static const AppConfig _staging = AppConfig(
    apiTimeout: Duration(seconds: 20),
    cacheMaxAge: Duration(hours: 6),
    syncRetrySeconds: 30,
    autoLockMinutes: 10,
    verboseLogs: true,
    sendCrashReports: true,
    requireBiometricUnlock: false,
  );

  static const AppConfig _prod = AppConfig(
    apiTimeout: Duration(seconds: 15),
    cacheMaxAge: Duration(hours: 24),
    syncRetrySeconds: 30,
    autoLockMinutes: 5,
    verboseLogs: false,
    sendCrashReports: true,
    requireBiometricUnlock: true,
  );
}
