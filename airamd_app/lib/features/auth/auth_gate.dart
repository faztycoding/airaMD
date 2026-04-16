import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/repository_providers.dart';
import 'login_screen.dart';

// ═══════════════════════════════════════════════════════════════
// AUTH GATE — Routes to Login or Main App based on session
// ═══════════════════════════════════════════════════════════════

/// Watches Supabase auth state and returns the current session.
/// Emits the current session immediately, then listens for changes.
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  // Emit current session right away (avoids timeout hacks).
  yield client.auth.currentSession;

  // Only relay meaningful auth changes — ignore tokenRefreshed which
  // can emit null session on iOS simulator and kick users to login.
  await for (final event in client.auth.onAuthStateChange) {
    switch (event.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.signedOut:
      case AuthChangeEvent.initialSession:
        yield event.session;
      default:
        break; // ignore tokenRefreshed, userUpdated, etc.
    }
  }
});

/// Whether the user is authenticated (has valid session).
final isAuthenticatedProvider = Provider<bool>((ref) {
  final sessionAsync = ref.watch(authSessionProvider);
  return sessionAsync.valueOrNull != null;
});

/// Gate widget: shows LoginScreen when not authenticated,
/// otherwise renders the child (main app).
class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const LoginScreen();
        }
        return child;
      },
      loading: () => const _SplashLoading(),
      error: (_, __) => const LoginScreen(),
    );
  }
}

/// Beautiful splash loading while checking auth state.
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F0E8), // AiraColors.cream
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF8B6650), // AiraColors.woodMid
              strokeWidth: 2.5,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
