import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/repository_providers.dart';
import 'login_screen.dart';

// ═══════════════════════════════════════════════════════════════
// AUTH GATE — Routes to Login or Main App based on session
// ═══════════════════════════════════════════════════════════════

/// Manages auth session state. Synchronous — no loading flicker.
/// Only reacts to signedIn / signedOut events.
class _AuthSessionNotifier extends StateNotifier<Session?> {
  StreamSubscription<AuthState>? _sub;

  _AuthSessionNotifier(SupabaseClient client)
      : super(client.auth.currentSession) {
    _sub = client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        state = event.session;
      } else if (event.event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final _authSessionNotifier =
    StateNotifierProvider<_AuthSessionNotifier, Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return _AuthSessionNotifier(client);
});

/// Public auth session — use `overrideWithValue` in tests.
final authSessionProvider = Provider<Session?>((ref) {
  return ref.watch(_authSessionNotifier);
});

/// Whether the user is authenticated (has valid session).
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider) != null;
});

/// Gate widget: shows LoginScreen when not authenticated,
/// otherwise renders the child (main app).
class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session == null) return const LoginScreen();
    return child;
  }
}
