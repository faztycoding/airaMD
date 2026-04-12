import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/repositories.dart';

/// Supabase client provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Repository Providers ─────────────────────────────────────

final patientRepoProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(supabaseClientProvider));
});

final appointmentRepoProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(supabaseClientProvider));
});

final staffRepoProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(supabaseClientProvider));
});

final serviceRepoProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.watch(supabaseClientProvider));
});

final treatmentRepoProvider = Provider<TreatmentRepository>((ref) {
  return TreatmentRepository(ref.watch(supabaseClientProvider));
});

final productRepoProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseClientProvider));
});

final courseRepoProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(supabaseClientProvider));
});

final financialRepoProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepository(ref.watch(supabaseClientProvider));
});

final consentTemplateRepoProvider = Provider<ConsentTemplateRepository>((ref) {
  return ConsentTemplateRepository(ref.watch(supabaseClientProvider));
});

final consentFormRepoProvider = Provider<ConsentFormRepository>((ref) {
  return ConsentFormRepository(ref.watch(supabaseClientProvider));
});

final photoRepoProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(supabaseClientProvider));
});

final diagramRepoProvider = Provider<DiagramRepository>((ref) {
  return DiagramRepository(ref.watch(supabaseClientProvider));
});

final inventoryRepoProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(supabaseClientProvider));
});

final auditRepoProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(supabaseClientProvider));
});

final messageRepoProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.watch(supabaseClientProvider));
});

final notepadRepoProvider = Provider<NotepadRepository>((ref) {
  return NotepadRepository(ref.watch(supabaseClientProvider));
});

final scheduleRepoProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(supabaseClientProvider));
});

final treatmentRuleRepoProvider = Provider<TreatmentRuleRepository>((ref) {
  return TreatmentRuleRepository(ref.watch(supabaseClientProvider));
});
