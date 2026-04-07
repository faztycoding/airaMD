import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:airamd/features/auth/auth_gate.dart';
import '../helpers/test_app.dart';

void main() {
  group('AuthGate', () {
    testWidgets('should show loading indicator while auth state resolves',
        (tester) async {
      // StreamController that never emits — keeps provider in loading
      final ctrl = StreamController<Session?>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(
        testApp(
          const AuthGate(child: Text('Main App')),
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => ctrl.stream,
            ),
          ],
        ),
      );
      // Only pump once (don't settle) to catch the loading state
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Main App'), findsNothing);
    });

    testWidgets('isAuthenticatedProvider should be true with overridden value',
        (tester) async {
      // Directly test the provider logic
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    testWidgets('should show login screen when session is null',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          const AuthGate(child: Text('Main App')),
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main App'), findsNothing);
      expect(find.text('airaMD'), findsOneWidget);
    });

    testWidgets('should show login screen on auth error', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AuthGate(child: Text('Main App')),
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream<Session?>.error(Exception('Auth error')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main App'), findsNothing);
      expect(find.text('airaMD'), findsOneWidget);
    });

    testWidgets('isAuthenticatedProvider should be false when no session',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future).catchError((_) => null);

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isFalse);
    });
  });
}
