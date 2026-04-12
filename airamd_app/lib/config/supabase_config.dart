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
    assert(
      AppConstants.supabaseUrl.isNotEmpty,
      'SUPABASE_URL not set. Pass --dart-define=SUPABASE_URL=<url>',
    );
    assert(
      AppConstants.supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY not set. Pass --dart-define=SUPABASE_ANON_KEY=<key>',
    );

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
