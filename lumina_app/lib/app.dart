import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/pin_lock_screen.dart';
import 'core/providers/locale_provider.dart';
import 'core/localization/app_localizations.dart';

/// Whether the app has been unlocked in this session.
/// Auto-unlock on web so we skip the PIN screen during dev.
final appUnlockedProvider = StateProvider<bool>((ref) => kIsWeb);

/// Whether auto-lock on background is enabled.
final autoLockEnabledProvider = StateProvider<bool>((ref) => true);

class AiraApp extends ConsumerStatefulWidget {
  const AiraApp({super.key});

  @override
  ConsumerState<AiraApp> createState() => _AiraAppState();
}

class _AiraAppState extends ConsumerState<AiraApp> {
  late final AppLifecycleListener _lifecycleListener;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleChange,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onLifecycleChange(AppLifecycleState state) {
    if (kIsWeb) return; // skip auto-lock on web during dev
    final autoLock = ref.read(autoLockEnabledProvider);
    if (!autoLock) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!);
        if (elapsed.inMinutes >= AppConstants.autoLockTimeout) {
          ref.read(appUnlockedProvider.notifier).state = false;
        }
        _pausedAt = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = ref.watch(appUnlockedProvider);
    final locale = ref.watch(localeProvider);

    // Layer 1: Auth Gate — must be authenticated first
    // Layer 2: PIN Lock — local security after auth
    // Layer 3: Main App with router

    const localizationsDelegates = [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    const supportedLocales = [
      Locale('th', 'TH'),
      Locale('en', 'US'),
    ];

    // PIN Lock layer (shown when authenticated but not unlocked)
    if (!isUnlocked) {
      return MaterialApp(
        title: 'airaMD',
        debugShowCheckedModeBanner: false,
        theme: AiraTheme.light,
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: AuthGate(
          child: PinLockScreen(
            onUnlocked: () {
              ref.read(appUnlockedProvider.notifier).state = true;
            },
          ),
        ),
      );
    }

    // Main app layer (authenticated + unlocked)
    return MaterialApp(
      title: 'airaMD',
      debugShowCheckedModeBanner: false,
      theme: AiraTheme.light,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      home: AuthGate(
        child: MaterialApp.router(
          title: 'airaMD',
          debugShowCheckedModeBanner: false,
          theme: AiraTheme.light,
          routerConfig: appRouter,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: localizationsDelegates,
        ),
      ),
    );
  }
}
