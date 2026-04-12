import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/services/logger_service.dart';

void main() {
  group('Log', () {
    test('info does not throw', () {
      expect(() => Log.i('Test', 'info message'), returnsNormally);
    });

    test('debug does not throw', () {
      expect(() => Log.d('Test', 'debug message'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => Log.w('Test', 'warning message'), returnsNormally);
    });

    test('error without stack does not throw', () {
      expect(() => Log.e('Test', 'error message'), returnsNormally);
    });

    test('error with stack does not throw', () {
      expect(
        () => Log.e('Test', 'error message', stackTrace: StackTrace.current),
        returnsNormally,
      );
    });
  });
}
