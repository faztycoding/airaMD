import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/providers/auth_providers.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('Auth Providers — RBAC logic', () {
    // ─── Helper: Create a container with a pre-set staff ───

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

    // ─── currentClinicIdProvider ────────────────────────────

    group('currentClinicIdProvider', () {
      test('should return clinic ID when staff is loaded', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        // Wait for the future to resolve
        await container.read(currentStaffProvider.future);
        final clinicId = container.read(currentClinicIdProvider);
        expect(clinicId, TestFixtures.clinicId);
      });

      test('should return null when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        final clinicId = container.read(currentClinicIdProvider);
        expect(clinicId, isNull);
      });
    });

    // ─── effectiveStaffRoleProvider ─────────────────────────

    group('effectiveStaffRoleProvider', () {
      test('should return owner role for owner staff', () async {
        final container = createContainer(TestFixtures.ownerStaff());
        await container.read(currentStaffProvider.future);
        final role = container.read(effectiveStaffRoleProvider);
        expect(role, StaffRole.owner);
      });

      test('should return doctor role for doctor staff', () async {
        final container = createContainer(TestFixtures.doctorStaff());
        await container.read(currentStaffProvider.future);
        final role = container.read(effectiveStaffRoleProvider);
        expect(role, StaffRole.doctor);
      });

      test('should return receptionist role for receptionist staff', () async {
        final container = createContainer(TestFixtures.receptionistStaff());
        await container.read(currentStaffProvider.future);
        final role = container.read(effectiveStaffRoleProvider);
        expect(role, StaffRole.receptionist);
      });

      test('should default to owner when staff is null', () async {
        final container = createContainer(null);
        await container.read(currentStaffProvider.future);
        final role = container.read(effectiveStaffRoleProvider);
        expect(role, StaffRole.owner); // fallback
      });
    });

    // ─── canManageClinicalDataProvider ──────────────────────

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
    });

    // ─── canAccessFinancialDataProvider ─────────────────────

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
    });

    // ─── canAccessSettingsProvider ──────────────────────────

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
    });

    // ─── isLimitedStaffProvider ─────────────────────────────

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
    });
  });
}
