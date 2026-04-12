import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class AppointmentRepository extends BaseRepository {
  AppointmentRepository(SupabaseClient client) : super(client, 'appointments');

  Future<List<Appointment>> list({
    required String clinicId,
    String orderBy = 'date',
    bool ascending = true,
    int? limit,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: orderBy,
      ascending: ascending,
      limit: limit,
    );
    return data.map(Appointment.fromJson).toList();
  }

  Future<Appointment?> get(String id) async {
    final data = await getById(id);
    return data != null ? Appointment.fromJson(data) : null;
  }

  Future<Appointment> create(Appointment appt) async {
    final data = await insert(appt.toInsertJson());
    return Appointment.fromJson(data);
  }

  Future<Appointment> updateAppointment(Appointment appt) async {
    final data = await update(appt.id, appt.toUpdateJson());
    return Appointment.fromJson(data);
  }

  Future<void> deleteAppointment(String id) => delete(id);

  /// Get appointments for a specific date.
  Future<List<Appointment>> getByDate({
    required String clinicId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('date', dateStr)
        .order('start_time', ascending: true);
    return data.map(Appointment.fromJson).toList();
  }

  /// Get appointments for a date range.
  Future<List<Appointment>> getByDateRange({
    required String clinicId,
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .gte('date', fromStr)
        .lte('date', toStr)
        .order('date', ascending: true)
        .order('start_time', ascending: true);
    return data.map(Appointment.fromJson).toList();
  }

  /// Get appointments for a specific patient.
  Future<List<Appointment>> getByPatient({
    required String patientId,
    int limit = 50,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('date', ascending: false)
        .limit(limit);
    return data.map(Appointment.fromJson).toList();
  }

  /// Get appointments for a specific doctor on a date.
  Future<List<Appointment>> getByDoctorDate({
    required String doctorId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await client
        .from(tableName)
        .select()
        .eq('doctor_id', doctorId)
        .eq('date', dateStr)
        .order('start_time', ascending: true);
    return data.map(Appointment.fromJson).toList();
  }

  /// Count today's appointments for a clinic.
  Future<int> countToday(String clinicId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await client
        .from(tableName)
        .select('id')
        .eq('clinic_id', clinicId)
        .eq('date', today);
    return (data as List).length;
  }

  /// Update appointment status.
  Future<Appointment> updateStatus(String id, AppointmentStatus status) async {
    final data = await update(id, {'status': status.dbValue});
    return Appointment.fromJson(data);
  }
}
