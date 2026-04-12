import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/config/theme.dart';

void main() {
  group('AiraColors', () {
    test('primary wood palette should be distinct colors', () {
      final colors = [
        AiraColors.woodDk,
        AiraColors.woodMid,
        AiraColors.woodLt,
        AiraColors.woodPale,
        AiraColors.woodWash,
      ];
      // All should be unique
      expect(colors.toSet().length, colors.length);
    });

    test('background colors should be light (high luminance)', () {
      expect(AiraColors.cream.computeLuminance(), greaterThan(0.7));
      expect(AiraColors.creamDk.computeLuminance(), greaterThan(0.6));
      expect(AiraColors.parchment.computeLuminance(), greaterThan(0.8));
    });

    test('text colors should be dark (low luminance)', () {
      expect(AiraColors.charcoal.computeLuminance(), lessThan(0.1));
    });

    test('functional aliases should map to correct colors', () {
      expect(AiraColors.error, equals(AiraColors.danger));
      expect(AiraColors.success, equals(AiraColors.sage));
      expect(AiraColors.warning, equals(AiraColors.gold));
      expect(AiraColors.info, equals(AiraColors.woodMid));
    });

    test('primaryGradient should use woodMid and woodDk', () {
      expect(AiraColors.primaryGradient.colors, contains(AiraColors.woodMid));
      expect(AiraColors.primaryGradient.colors, contains(AiraColors.woodDk));
    });

    test('accent colors should be fully opaque', () {
      expect(AiraColors.sage.a, 1.0);
      expect(AiraColors.terra.a, 1.0);
      expect(AiraColors.gold.a, 1.0);
    });
  });
}
