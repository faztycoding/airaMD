import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'repository_providers.dart';

// DEV MODE: Demo clinic ID from seed.sql — remove when auth is implemented
const _devClinicId = '00000000-0000-0000-0000-000000000001';

/// Current Supabase auth user.
final authUserProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((state) => state.session?.user);
});

/// Current logged-in staff member (resolved from auth.uid → staff table).
final currentStaffProvider = FutureProvider<Staff?>((ref) async {
  final repo = ref.watch(staffRepoProvider);
  return repo.getCurrentStaff();
});

/// Current clinic ID (derived from current staff, falls back to dev clinic).
final currentClinicIdProvider = Provider<String?>((ref) {
  final staffAsync = ref.watch(currentStaffProvider);
  return staffAsync.valueOrNull?.clinicId ?? _devClinicId;
});

final effectiveStaffRoleProvider = Provider<StaffRole>((ref) {
  final staffAsync = ref.watch(currentStaffProvider);
  return staffAsync.valueOrNull?.role ?? StaffRole.owner;
});

final canManageClinicalDataProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveStaffRoleProvider);
  return role == StaffRole.owner || role == StaffRole.doctor;
});

final canAccessFinancialDataProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveStaffRoleProvider);
  return role == StaffRole.owner || role == StaffRole.doctor;
});

final canAccessSettingsProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveStaffRoleProvider);
  return role == StaffRole.owner || role == StaffRole.doctor;
});

final isLimitedStaffProvider = Provider<bool>((ref) {
  return !ref.watch(canManageClinicalDataProvider);
});
