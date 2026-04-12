import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/localization/app_localizations.dart';

void main() {
  group('AppL10n', () {
    test('Thai locale should return Thai strings', () {
      final l10n = AppL10n(const Locale('th', 'TH'));
      expect(l10n.isThai, isTrue);
      expect(l10n.loginTitle, isNotEmpty);
      expect(l10n.email, isNotEmpty);
      expect(l10n.password, isNotEmpty);
    });

    test('English locale should return English strings', () {
      final l10n = AppL10n(const Locale('en', 'US'));
      expect(l10n.isThai, isFalse);
      expect(l10n.loginTitle, isNotEmpty);
      expect(l10n.email, isNotEmpty);
      expect(l10n.password, isNotEmpty);
    });

    test('Thai and English strings should differ for localized keys', () {
      final th = AppL10n(const Locale('th', 'TH'));
      final en = AppL10n(const Locale('en', 'US'));
      expect(th.loginTitle, isNot(equals(en.loginTitle)));
      expect(th.email, isNot(equals(en.email)));
      expect(th.password, isNot(equals(en.password)));
    });

    test('isThai should be false for non-Thai locales', () {
      expect(AppL10n(const Locale('en', 'US')).isThai, isFalse);
      expect(AppL10n(const Locale('ja')).isThai, isFalse);
      expect(AppL10n(const Locale('th')).isThai, isTrue);
    });

    test('parameterized strings should interpolate correctly', () {
      final l10n = AppL10n(const Locale('en', 'US'));
      final err = l10n.errorMsg('timeout');
      expect(err, contains('timeout'));
    });
  });
}
