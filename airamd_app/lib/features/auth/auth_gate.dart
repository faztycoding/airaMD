import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

// ═══════════════════════════════════════════════════════════════
// AUTH GATE — Routes to Login or Main App based on session
// ═══════════════════════════════════════════════════════════════

/// Watches Supabase auth state and returns the current session.
final authSessionProvider = StreamProvider<Session?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session,
  );
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
        child: CircularProgressIndicator(
          color: Color(0xFF8B6650), // AiraColors.woodMid
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
