import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'features/auth/pin_lock_screen.dart';
import 'core/providers/locale_provider.dart';
import 'core/localization/app_localizations.dart';

/// Whether the app has been unlocked in this session.
/// Auto-unlock on web so we skip the PIN screen during dev.
final appUnlockedProvider = StateProvider<bool>((ref) => kIsWeb);

class AiraApp extends ConsumerWidget {
  const AiraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked = ref.watch(appUnlockedProvider);
    final locale = ref.watch(localeProvider);

    // Show PIN Lock as a completely separate MaterialApp
    // This avoids the router interfering with the lock screen.
    if (!isUnlocked) {
      return MaterialApp(
        title: 'airaMD',
        debugShowCheckedModeBanner: false,
        theme: AiraTheme.light,
        locale: locale,
        supportedLocales: const [
          Locale('th', 'TH'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PinLockScreen(
          onUnlocked: () {
            ref.read(appUnlockedProvider.notifier).state = true;
          },
        ),
      );
    }

    return MaterialApp.router(
      title: 'airaMD',
      debugShowCheckedModeBanner: false,
      theme: AiraTheme.light,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
