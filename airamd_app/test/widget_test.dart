import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/features/auth/login_screen.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('App smoke test — LoginScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(const LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('airaMD'), findsOneWidget);
  });
}
