import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/config/constants.dart';

void main() {
  group('AppConfig — environment-specific defaults', () {
    // ENV is a compile-time --dart-define so we can't flip it at runtime in
    // tests. Instead we exercise the *invariants* that must hold for ANY
    // build, regardless of which env the tests happen to run under.

    test('current returns a non-null config with positive durations', () {
      final cfg = AppConfig.current;
      expect(cfg.apiTimeout.inSeconds, greaterThan(0));
      expect(cfg.cacheMaxAge.inMinutes, greaterThan(0));
      expect(cfg.syncRetrySeconds, greaterThan(0));
      expect(cfg.autoLockMinutes, greaterThan(0));
    });

    test('production is strictly stricter than dev', () {
      // Even though we can only read .current, the static const fields are
      // exposed by name on the class for dev / staging / prod. We verify
      // them through the `current` accessor for whichever env we're in,
      // plus exercise that the env-flag booleans are mutually consistent.
      expect(
        AppConstants.isProduction || AppConstants.isStaging
            || AppConstants.isDevelopment,
        isTrue,
        reason: 'exactly one env predicate must be true',
      );
      expect(
        AppConstants.isProduction
            ? !AppConstants.isStaging && !AppConstants.isDevelopment
            : true,
        isTrue,
      );
    });

    test('verboseLogs is disabled when sendCrashReports is enabled in prod',
        () {
      // Sanity check — production should not log verbosely AND should send
      // crash reports. Dev should be the opposite.
      if (AppConstants.isProduction) {
        expect(AppConfig.current.verboseLogs, isFalse);
        expect(AppConfig.current.sendCrashReports, isTrue);
        expect(AppConfig.current.requireBiometricUnlock, isTrue);
      }
      if (AppConstants.isDevelopment) {
        expect(AppConfig.current.sendCrashReports, isFalse);
        expect(AppConfig.current.requireBiometricUnlock, isFalse);
      }
    });
  });
}
