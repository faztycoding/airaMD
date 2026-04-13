import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/providers/auth_providers.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('Auth Providers — RBAC logic', () {
    ProviderContainer createContainer(Staff? staff) {
      final container = ProviderContainer(
        overrides: [
          currentStaffProvider.overrideWith(
            (ref) => Future.value(staff),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    group('currentClinicIdProvider', () {
      test('should return clinic ID when staff is loaded', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(currentClinicIdProvider), TestFixtures.clinicId);
      });

      test('should return null when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        expect(container.read(currentClinicIdProvider), isNull);
      });
    });

    group('effectiveStaffRoleProvider', () {
      test('should return owner role for owner staff', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(effectiveStaffRoleProvider), StaffRole.owner);
      });

      test('should return doctor role for doctor staff', () async {
        final container = createContainer(TestFixtures.doctorStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(effectiveStaffRoleProvider), StaffRole.doctor);
      });

      test('should return receptionist role for receptionist staff', () async {
        final container = createContainer(TestFixtures.receptionistStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(effectiveStaffRoleProvider), StaffRole.receptionist);
      });

      test('should default to receptionist when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        expect(container.read(effectiveStaffRoleProvider), StaffRole.receptionist);
      });

      test('should default to receptionist while staff is loading', () {
        final completer = Completer<Staff?>();
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith((ref) => completer.future),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(effectiveStaffRoleProvider), StaffRole.receptionist);
      });

      test('should default to receptionist when staff loading fails', () async {
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future<Staff?>.error(Exception('staff lookup failed')),
            ),
          ],
        );
        addTearDown(container.dispose);

        try {
          await container.read(currentStaffProvider.future);
        } catch (_) {}

        expect(container.read(effectiveStaffRoleProvider), StaffRole.receptionist);
      });
    });

    group('canManageClinicalDataProvider', () {
      test('should be true for owner', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canManageClinicalDataProvider), isTrue);
      });

      test('should be true for doctor', () async {
        final container = createContainer(TestFixtures.doctorStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canManageClinicalDataProvider), isTrue);
      });

      test('should be false for receptionist', () async {
        final container = createContainer(TestFixtures.receptionistStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canManageClinicalDataProvider), isFalse);
      });

      test('should be false while staff is loading', () {
        final completer = Completer<Staff?>();
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith((ref) => completer.future),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(canManageClinicalDataProvider), isFalse);
      });

      test('should be false when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        expect(container.read(canManageClinicalDataProvider), isFalse);
      });

      test('should be false when staff loading fails', () async {
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future<Staff?>.error(Exception('staff lookup failed')),
            ),
          ],
        );
        addTearDown(container.dispose);

        try {
          await container.read(currentStaffProvider.future);
        } catch (_) {}

        expect(container.read(canManageClinicalDataProvider), isFalse);
      });
    });

    group('canAccessFinancialDataProvider', () {
      test('should be true for owner', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessFinancialDataProvider), isTrue);
      });

      test('should be true for doctor', () async {
        final container = createContainer(TestFixtures.doctorStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessFinancialDataProvider), isTrue);
      });

      test('should be false for receptionist', () async {
        final container = createContainer(TestFixtures.receptionistStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessFinancialDataProvider), isFalse);
      });

      test('should be false when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessFinancialDataProvider), isFalse);
      });

      test('should be false when staff loading fails', () async {
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future<Staff?>.error(Exception('staff lookup failed')),
            ),
          ],
        );
        addTearDown(container.dispose);

        try {
          await container.read(currentStaffProvider.future);
        } catch (_) {}

        expect(container.read(canAccessFinancialDataProvider), isFalse);
      });
    });

    group('canAccessSettingsProvider', () {
      test('should be true for owner', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessSettingsProvider), isTrue);
      });

      test('should be false for receptionist', () async {
        final container = createContainer(TestFixtures.receptionistStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessSettingsProvider), isFalse);
      });

      test('should be false when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        expect(container.read(canAccessSettingsProvider), isFalse);
      });

      test('should be false when staff loading fails', () async {
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future<Staff?>.error(Exception('staff lookup failed')),
            ),
          ],
        );
        addTearDown(container.dispose);

        try {
          await container.read(currentStaffProvider.future);
        } catch (_) {}

        expect(container.read(canAccessSettingsProvider), isFalse);
      });
    });

    group('isLimitedStaffProvider', () {
      test('should be false for owner', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(isLimitedStaffProvider), isFalse);
      });

      test('should be false for doctor', () async {
        final container = createContainer(TestFixtures.doctorStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(isLimitedStaffProvider), isFalse);
      });

      test('should be true for receptionist', () async {
        final container = createContainer(TestFixtures.receptionistStaff());
        await container.read(currentStaffProvider.future);
        expect(container.read(isLimitedStaffProvider), isTrue);
      });

      test('should be true when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        expect(container.read(isLimitedStaffProvider), isTrue);
      });

      test('should be true when staff loading fails', () async {
        final container = ProviderContainer(
          overrides: [
            currentStaffProvider.overrideWith(
              (ref) => Future<Staff?>.error(Exception('staff lookup failed')),
            ),
          ],
        );
        addTearDown(container.dispose);

        try {
          await container.read(currentStaffProvider.future);
        } catch (_) {}

        expect(container.read(isLimitedStaffProvider), isTrue);
      });
    });
  });
}
