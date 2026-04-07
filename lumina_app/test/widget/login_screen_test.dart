import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/features/auth/login_screen.dart';
import '../helpers/test_app.dart';

/// Helper to tap an AiraTapEffect widget (which uses onTapDown/onTapUp
/// instead of onTap). We need to simulate a full press gesture.
Future<void> tapWidget(WidgetTester tester, Finder finder) async {
  final center = tester.getCenter(finder);
  final gesture = await tester.startGesture(center);
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

void main() {
  group('LoginScreen', () {
    // Set a large screen to avoid overflow in all tests
    setUp(() {
      // Will be applied per test via tester.view
    });

    Widget buildLoginScreen({Locale locale = const Locale('th')}) {
      return testApp(const LoginScreen(), locale: locale);
    }

    // ─── Initial Render ────────────────────────────────────

    testWidgets('should render login mode by default', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('airaMD'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsWidgets); // title + button
    });

    testWidgets('should show email and password fields', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
    });

    testWidgets('should show forgot password link', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
    });

    testWidgets('should show sign up link', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีบัญชี?'), findsOneWidget);
      expect(find.text('ลงทะเบียน'), findsOneWidget);
    });

    // ─── Form Validation ───────────────────────────────────

    testWidgets('should show validation errors on empty login submit',
        (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Tap the primary button
      await tapWidget(tester, find.text('เข้าสู่ระบบ').last);

      // Should show validation errors
      expect(find.text('กรุณากรอกข้อมูล'), findsWidgets);
    });

    testWidgets('should validate email format', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'notanemail');

      // Enter a password to avoid that error
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Submit
      await tapWidget(tester, find.text('เข้าสู่ระบบ').last);

      expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
    });

    // ─── Mode Switching ────────────────────────────────────

    testWidgets('should switch to signup mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Ensure the signup link is visible by scrolling
      await tester.ensureVisible(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      // Tap "ลงทะเบียน" link (AiraTapEffect)
      await tapWidget(tester, find.text('ลงทะเบียน'));

      // Should now show signup form with more fields
      expect(find.text('สร้างบัญชี'), findsOneWidget);
      // In signup mode: name, clinic, email, password, confirm = 5 fields
      expect(find.byType(TextFormField), findsNWidgets(5));
    });

    testWidgets('should switch to forgot password mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Tap forgot password link (AiraTapEffect)
      await tester.ensureVisible(find.text('ลืมรหัสผ่าน?'));
      await tapWidget(tester, find.text('ลืมรหัสผ่าน?'));

      // Should show forgot password form with only email field
      expect(find.text('ลืมรหัสผ่าน'), findsWidgets); // title + mode label
      expect(find.byType(TextFormField), findsNWidgets(1)); // email only
    });

    testWidgets('should switch back from signup to login', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Go to signup
      await tester.ensureVisible(find.text('ลงทะเบียน'));
      await tapWidget(tester, find.text('ลงทะเบียน'));

      // Switch back to login
      await tapWidget(tester, find.text('เข้าสู่ระบบ').last);

      // Should be back in login mode with 2 fields
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should switch back from forgot password to login',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Go to forgot password
      await tester.ensureVisible(find.text('ลืมรหัสผ่าน?'));
      await tapWidget(tester, find.text('ลืมรหัสผ่าน?'));

      // Should show "จำรหัสผ่านได้แล้ว?" with login link
      expect(find.text('จำรหัสผ่านได้แล้ว?'), findsOneWidget);

      // Click back to login
      await tapWidget(tester, find.text('เข้าสู่ระบบ').last);

      // Back to login mode
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    // ─── Signup Validation ─────────────────────────────────

    testWidgets('should validate password length in signup', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Switch to signup
      await tester.ensureVisible(find.text('ลงทะเบียน'));
      await tapWidget(tester, find.text('ลงทะเบียน'));

      // Fill in fields: name, clinic, email, short password, confirm
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Dr. Test'); // name
      // skip clinic (optional)
      await tester.enterText(fields.at(2), 'test@clinic.com'); // email
      await tester.enterText(fields.at(3), '123'); // short password
      await tester.enterText(fields.at(4), '123'); // confirm

      // Submit
      await tapWidget(tester, find.text('ลงทะเบียน').last);

      expect(
          find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
    });

    testWidgets('should validate password mismatch in signup', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Switch to signup
      await tester.ensureVisible(find.text('ลงทะเบียน'));
      await tapWidget(tester, find.text('ลงทะเบียน'));

      // Fill fields
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Dr. Test');
      await tester.enterText(fields.at(2), 'test@clinic.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'different456');

      // Submit
      await tapWidget(tester, find.text('ลงทะเบียน').last);

      expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    });

    // ─── English Locale ────────────────────────────────────

    testWidgets('should render in English when locale is en', (tester) async {
      // Use a large surface to avoid overflow in English text
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        testApp(const LoginScreen(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('airaMD'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    // ─── Password Visibility Toggle ────────────────────────

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Password should be obscured initially
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'testpassword');

      // Find and tap the visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility_off_rounded);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // Should now show visibility icon (password visible)
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });
  });
}
