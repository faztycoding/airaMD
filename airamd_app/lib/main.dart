import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'config/constants.dart';
import 'config/supabase_config.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/logger_service.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Call runApp IMMEDIATELY so the Flutter scene connects on iOS.
  // Heavy async init happens inside _AppBootstrap.
  runApp(
    const ProviderScope(
      child: _AppBootstrap(),
    ),
  );
}

/// Initialises Firebase, Supabase, Push, Crashlytics, then shows AiraApp.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();
  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Lock to landscape only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics
    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
    FirebaseCrashlytics.instance
        .setCustomKey('environment', AppConstants.environment);

    // Supabase
    await SupabaseConfig.initialize();

    // Push Notifications (timeout on simulator — no APNs available)
    await PushNotificationService.initialize()
        .timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('[Bootstrap] Push init timed out (likely simulator)');
    });

    Log.i('main', 'airaMD started (env=${AppConstants.environment})');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFFF7F0E8),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF8B6650),
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 24),
                    Text('กำลังโหลด airaMD...',
                        style: TextStyle(
                            fontSize: 18, color: Color(0xFF8B6650))),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red,
              body: Center(
                child: Text('Init Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          );
        }
        return const AiraApp();
      },
    );
  }
}
