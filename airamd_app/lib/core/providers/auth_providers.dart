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
///
/// IMPORTANT: watches [authUserProvider] so it rebuilds when the auth user
/// changes (e.g. logout → re-login as a different user). Without this, the
/// FutureProvider would cache the previous user's staff row indefinitely.
final currentStaffProvider = FutureProvider<Staff?>((ref) async {
  // Rebuild whenever the underlying auth user changes.
  final authUser = ref.watch(authUserProvider).valueOrNull;
  if (authUser == null) return null;
  final repo = ref.watch(staffRepoProvider);
  return repo.getCurrentStaff();
});

/// Current clinic ID (derived from current staff's clinic).
/// Returns null when not authenticated — AuthGate prevents this state in UI.
final currentClinicIdProvider = Provider<String?>((ref) {
  final staffAsync = ref.watch(currentStaffProvider);
  return staffAsync.valueOrNull?.clinicId;
});

/// Current clinic record (shared, invalidatable).
///
/// Both Settings → Clinic Info and the consent form read this provider so an
/// edit to the clinic name (or other info) reflects everywhere once the
/// provider is invalidated after saving.
final currentClinicProvider = FutureProvider<Clinic?>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final data =
      await client.from('clinics').select().eq('id', clinicId).maybeSingle();
  return data != null ? Clinic.fromJson(data) : null;
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

final canViewPatientsProvider = Provider<bool>((ref) {
  final staffAsync = ref.watch(currentStaffProvider);
  return staffAsync.valueOrNull != null;
});

final isLimitedStaffProvider = Provider<bool>((ref) {
  return !ref.watch(canManageClinicalDataProvider);
});
