import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/widgets/aira_tap_effect.dart';

void main() {
  group('AiraTapEffect — accessibility semantics', () {
    /// Walks the widget tree for the Semantics widget that AiraTapEffect
    /// adds with the given label. We assert against the WIDGET's properties
    /// rather than against `tester.getSemantics(...)` because the runtime
    /// SemanticsNode tree merges children in ways that make label-based
    /// finders flaky here — we still get full coverage of the contract
    /// (label / hint / button flag / enabled flag) through the widget.
    Semantics findSemantics(WidgetTester tester, String label) {
      return tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere((s) => s.properties.label == label);
    }

    testWidgets('exposes itself as a button with the provided label',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiraTapEffect(
              onTap: () {},
              semanticsLabel: 'Save patient',
              child: const Text('Save'),
            ),
          ),
        ),
      );

      // The Semantics wrapper should expose the label, mark the element
      // as a button, and report enabled because we provided onTap.
      final s = findSemantics(tester, 'Save patient');
      expect(s.properties.label, 'Save patient');
      expect(s.properties.button, isTrue);
      expect(s.properties.enabled, isTrue);

      handle.dispose();
    });

    testWidgets('reports enabled=false when no callbacks are provided',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiraTapEffect(
              semanticsLabel: 'Disabled action',
              child: Text('No-op'),
            ),
          ),
        ),
      );

      final s = findSemantics(tester, 'Disabled action');
      expect(s.properties.enabled, isFalse);

      handle.dispose();
    });

    testWidgets('exposes hint text + button flag through the Semantics widget',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiraTapEffect(
              onTap: () {},
              semanticsLabel: 'Edit profile',
              semanticsHint: 'Opens the edit form',
              child: const Icon(Icons.edit),
            ),
          ),
        ),
      );

      final s = findSemantics(tester, 'Edit profile');
      expect(s.properties.hint, 'Opens the edit form');
      expect(s.properties.button, isTrue);

      handle.dispose();
    });

    testWidgets('isButton=false drops the button flag', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiraTapEffect(
              onTap: () {},
              isButton: false,
              semanticsLabel: 'Decorative tap',
              child: const Text('Touch me'),
            ),
          ),
        ),
      );

      final s = findSemantics(tester, 'Decorative tap');
      expect(s.properties.button, isFalse);

      handle.dispose();
    });
  });
}
