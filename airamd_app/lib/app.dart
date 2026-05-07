import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/pin_lock_screen.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/repository_providers.dart';
import 'core/localization/app_localizations.dart';

/// Whether the app has been unlocked in this session.
/// Auto-unlock on web so we skip the PIN screen during dev.
final appUnlockedProvider = StateProvider<bool>((ref) => kIsWeb);

/// Whether auto-lock on background is enabled.
final autoLockEnabledProvider = StateProvider<bool>((ref) => true);

/// Auth session provider — watches Supabase auth state.
/// Returns null when not authenticated.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<Session?>.broadcast();

  // Emit current session first
  controller.add(client.auth.currentSession);

  // Then listen to auth state changes
  final sub = client.auth.onAuthStateChange
      .where((e) =>
          e.event == AuthChangeEvent.signedIn ||
          e.event == AuthChangeEvent.signedOut ||
          e.event == AuthChangeEvent.tokenRefreshed)
      .map((e) => e.session)
      .listen(
        (session) => controller.add(session),
        onError: (e) => controller.addError(e),
      );

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Whether user is authenticated (has valid session).
final isAuthenticatedProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(authSessionProvider).when(
        data: (s) => AsyncData(s != null),
        error: (e, st) => AsyncError(e, st),
        loading: () => const AsyncLoading(),
      );
});

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
    if (kIsWeb) return;
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
    final locale = ref.watch(localeProvider);

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

    // Single MaterialApp.router with integrated auth + PIN gates
    return MaterialApp.router(
      title: 'airaMD',
      debugShowCheckedModeBanner: false,
      theme: AiraTheme.light,
      routerConfig: _buildRouter(ref),
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
    );
  }

  /// Build the router with redirect-based auth and PIN gates.
  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/dashboard',
      refreshListenable: _RouterRefresh(ref),
      redirect: (context, state) {
        final authAsync = ref.read(isAuthenticatedProvider);
        final isUnlocked = ref.read(appUnlockedProvider);
        final path = state.uri.path;

        // Wait for auth state to load
        if (authAsync.isLoading) return null;
        final isAuthenticated = authAsync.valueOrNull ?? false;

        // 1. Auth gate — redirect to login when not authenticated
        if (!isAuthenticated) {
          // Allow access to login-related paths (none currently, but for future)
          if (path == '/login') return null;
          return '/login';
        }

        // 2. PIN gate — show lock screen when authenticated but locked
        if (!isUnlocked) {
          if (path == '/lock') return null;
          return '/lock';
        }

        // 3. If at /login or /lock but already unlocked, go to dashboard
        if (path == '/login' || path == '/lock') {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        // Lock screen route (outside shell)
        GoRoute(
          path: '/lock',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => PinLockScreen(
            onUnlocked: () {
              ref.read(appUnlockedProvider.notifier).state = true;
            },
          ),
        ),
        // Login screen route (used when signed out)
        GoRoute(
          path: '/login',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LoginScreen(),
        ),
        ...appRoutes, // Main app routes from routes.dart
      ],
    );
  }
}

/// Placeholder that redirects based on auth state.
/// The actual login UI is in login_screen.dart imported via auth_gate.dart.
class _LoginPlaceholder extends ConsumerWidget {
  const _LoginPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a placeholder; the router redirect handles the actual flow.
    // When auth completes, the router will redirect away.
    final authAsync = ref.watch(isAuthenticatedProvider);

    // Show loading while auth state resolves
    if (authAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Should not reach here due to redirect, but show error if it does
    return const Scaffold(
      body: Center(child: Text('Redirecting...')),
    );
  }
}

/// Refresh listenable that notifies GoRouter when auth/PIN state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(WidgetRef ref) {
    // Listen to auth state changes
    ref.listen(authSessionProvider, (_, __) => notifyListeners());
    // Listen to PIN unlock state changes
    ref.listen(appUnlockedProvider, (_, __) => notifyListeners());
  }
}
