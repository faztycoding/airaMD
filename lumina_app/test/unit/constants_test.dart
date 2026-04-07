import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/config/constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is airaMD', () {
      expect(AppConstants.appName, 'airaMD');
    });

    test('appVersion is set', () {
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('environment defaults to dev in tests', () {
      // In test mode, --dart-define is not set, so defaults to 'dev'
      expect(AppConstants.environment, 'dev');
    });

    test('isProduction is false by default', () {
      expect(AppConstants.isProduction, false);
    });

    test('isStaging is false by default', () {
      expect(AppConstants.isStaging, false);
    });

    test('supabaseUrl reads from dart-define (empty in tests)', () {
      // In tests without --dart-define, these are empty strings
      expect(AppConstants.supabaseUrl, isA<String>());
    });

    test('bucketPatientPhotos is defined', () {
      expect(AppConstants.bucketPatientPhotos, 'patient-photos');
    });

    test('treatmentIntervals has expected keys', () {
      expect(AppConstants.treatmentIntervals, containsPair('BOTOX', isA<Map>()));
      expect(AppConstants.treatmentIntervals, containsPair('FILLER', isA<Map>()));
      expect(AppConstants.treatmentIntervals, containsPair('LASER', isA<Map>()));
      expect(AppConstants.treatmentIntervals, containsPair('HIFU', isA<Map>()));
    });

    test('autoLockTimeout is 5 minutes', () {
      expect(AppConstants.autoLockTimeout, 5);
    });

    test('pinLength is 6', () {
      expect(AppConstants.pinLength, 6);
    });

    test('imageMaxWidth is 2048', () {
      expect(AppConstants.imageMaxWidth, 2048);
    });

    test('imageQuality is 80', () {
      expect(AppConstants.imageQuality, 80);
    });
  });
}
