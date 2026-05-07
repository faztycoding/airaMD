import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

/// Initialize Supabase client.
///
/// Credentials MUST be injected at build time via --dart-define:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> initialize() async {
    // `assert` is stripped from release builds — a production binary built
    // without `--dart-define=SUPABASE_URL=...` would silently start with an
    // empty URL and fail on first request. Use StateError so the misconfig
    // is obvious at boot in ALL build modes, dev and release alike.
    if (AppConstants.supabaseUrl.isEmpty) {
      throw StateError(
        'SUPABASE_URL not set. Rebuild with --dart-define=SUPABASE_URL=<url>',
      );
    }
    if (AppConstants.supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY not set. Rebuild with --dart-define=SUPABASE_ANON_KEY=<key>',
      );
    }
    if (!AppConstants.supabaseUrl.startsWith('https://')) {
      throw StateError(
        'SUPABASE_URL must start with https:// — got "${AppConstants.supabaseUrl}"',
      );
    }

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
