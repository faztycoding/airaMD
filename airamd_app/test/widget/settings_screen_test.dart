import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/providers/auth_providers.dart';
import 'package:airamd/features/settings/settings_screen.dart';
import '../helpers/test_app.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders auth email as displayName and subtitle when no staff profile', (tester) async {
      await tester.pumpWidget(
        testApp(
          const SettingsScreen(),
          overrides: [
            currentStaffProvider.overrideWith((ref) => Future.value(null)),
            currentAuthEmailProvider.overrideWithValue('owner@aira.test'),
            authSignOutActionProvider.overrideWithValue(() async {}),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Auth email appears as both displayName and subtitle fallback
      expect(find.text('owner@aira.test'), findsNWidgets(2));
    });

    testWidgets('prefers staff profile name over auth email when available', (tester) async {
      await tester.pumpWidget(
        testApp(
          const SettingsScreen(),
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future.value(TestFixtures.ownerStaff()),
            ),
            currentAuthEmailProvider.overrideWithValue('owner@aira.test'),
            authSignOutActionProvider.overrideWithValue(() async {}),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dr. Somchai'), findsOneWidget);
      // Email should NOT appear since staff profile is available
      expect(find.text('owner@aira.test'), findsNothing);
    });

    testWidgets('shows role label when staff profile is loaded', (tester) async {
      await tester.pumpWidget(
        testApp(
          const SettingsScreen(),
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future.value(TestFixtures.doctorStaff()),
            ),
            currentAuthEmailProvider.overrideWithValue('doc@aira.test'),
            authSignOutActionProvider.overrideWithValue(() async {}),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dr. Ploy'), findsOneWidget);
    });

    testWidgets('logout button calls injected sign-out action', (tester) async {
      var signOutCalled = false;

      await tester.pumpWidget(
        testApp(
          const SettingsScreen(),
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future.value(TestFixtures.ownerStaff()),
            ),
            currentAuthEmailProvider.overrideWithValue('owner@aira.test'),
            authSignOutActionProvider.overrideWithValue(() async {
              signOutCalled = true;
            }),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to find and tap the logout button
      final logoutFinder = find.byIcon(Icons.logout_rounded);
      await tester.ensureVisible(logoutFinder);
      await tester.pumpAndSettle();
      await tester.tap(logoutFinder);
      await tester.pumpAndSettle();

      // Confirm dialog appeared — find confirm button by its terra color style
      expect(find.text('ออกจากระบบ'), findsAtLeast(2)); // title + button (+ original behind dialog)
      // Tap the last "ออกจากระบบ" which is the confirm TextButton in the dialog
      await tester.tap(find.text('ออกจากระบบ').last);
      await tester.pumpAndSettle();

      expect(signOutCalled, isTrue);
    });
  });
}
