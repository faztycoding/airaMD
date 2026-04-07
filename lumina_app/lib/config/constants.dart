/// App-wide constants
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

  // Supabase — injected via --dart-define, never hardcoded
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Storage bucket names
  static const String bucketPatientPhotos = 'patient-photos';
  static const String bucketFaceDiagrams = 'face-diagrams';
  static const String bucketConsentSignatures = 'consent-signatures';
  static const String bucketConsentPdfs = 'consent-pdfs';
  static const String bucketNotepads = 'notepads';

  // Image compression
  static const int imageMaxWidth = 2048;
  static const int imageQuality = 80;
  static const int thumbnailWidth = 400;

  // Treatment interval rules (days) — configurable in settings
  static const Map<String, Map<String, int>> treatmentIntervals = {
    'BOTOX': {'min': 60, 'recommended': 90},
    'FILLER': {'min': 120, 'recommended': 180},
    'LASER': {'min': 21, 'recommended': 30},
    'HIFU': {'min': 90, 'recommended': 180},
  };

  // Auto-lock timeout (minutes)
  static const int autoLockTimeout = 5;

  // PIN length
  static const int pinLength = 6;
}
