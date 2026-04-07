import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'config/constants.dart';
import 'config/supabase_config.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/logger_service.dart';
import 'app.dart';

void main() async {
  // Catch all errors in this zone and forward to Crashlytics
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase first (needed for Crashlytics)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ─── Crashlytics ───────────────────────────────────
    if (!kDebugMode) {
      // Pass all uncaught Flutter errors to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Pass all uncaught async errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      // In debug mode, print errors to console
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        Log.e('FlutterError', details.exceptionAsString(),
            stackTrace: details.stack);
      };
    }

    // Set environment tag in Crashlytics
    FirebaseCrashlytics.instance.setCustomKey('environment', AppConstants.environment);

    // ─── Supabase ──────────────────────────────────────
    await SupabaseConfig.initialize();

    // ─── Push Notifications ────────────────────────────
    await PushNotificationService.initialize();

    Log.i('main', 'airaMD started (env=${AppConstants.environment})');

    runApp(
      const ProviderScope(
        child: AiraApp(),
      ),
    );
  }, (error, stack) {
    // Zone-level error handler — catches everything not caught above
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    Log.e('Zone', error.toString(), stackTrace: stack);
  });
}
