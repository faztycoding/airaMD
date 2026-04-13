import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'repository_providers.dart';

typedef AuthSignOutAction = Future<void> Function();

/// Current Supabase auth user.
final authUserProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((state) => state.session?.user);
});

/// Current authenticated email address for UI display.
final currentAuthEmailProvider = Provider<String?>((ref) {
  final authUserAsync = ref.watch(authUserProvider);
  return authUserAsync.valueOrNull?.email;
});

/// Injectable sign-out action for UI flows and tests.
final authSignOutActionProvider = Provider<AuthSignOutAction>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return () => client.auth.signOut();
});

/// Current logged-in staff member (resolved from auth.uid → staff table).
final currentStaffProvider = FutureProvider<Staff?>((ref) async {
  final repo = ref.watch(staffRepoProvider);
  return repo.getCurrentStaff();
});

/// Current clinic ID (derived from current staff's clinic).
/// Returns null when not authenticated — AuthGate prevents this state in UI.
final currentClinicIdProvider = Provider<String?>((ref) {
  final staffAsync = ref.watch(currentStaffProvider);
  return staffAsync.valueOrNull?.clinicId;
});

final effectiveStaffRoleProvider = Provider<StaffRole>((ref) {
  final staffAsync = ref.watch(currentStaffProvider);
  return staffAsync.valueOrNull?.role ?? StaffRole.receptionist;
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
