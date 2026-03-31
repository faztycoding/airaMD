import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AiraApp());
    expect(find.text('สวัสดีค่ะ, คุณหมอ'), findsOneWidget);
  });
}
