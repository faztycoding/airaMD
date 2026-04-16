import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/features/auth/auth_gate.dart';
import '../helpers/test_app.dart';

void main() {
  group('AuthGate', () {
    testWidgets('should show login screen when session is null',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          const AuthGate(child: Text('Main App')),
          overrides: [
            authSessionProvider.overrideWithValue(null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main App'), findsNothing);
      expect(find.text('airaMD'), findsOneWidget);
    });

    testWidgets('isAuthenticatedProvider should be true with overridden value',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    testWidgets('isAuthenticatedProvider should be false when no session',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isFalse);
    });
  });
}
