import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class ScheduleRepository extends BaseRepository {
  ScheduleRepository(SupabaseClient client)
      : super(client, 'staff_schedules');

  Future<List<StaffSchedule>> getByDate({
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
    return data.map(StaffSchedule.fromJson).toList();
  }

  Future<List<StaffSchedule>> getByStaff({
    required String staffId,
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;
    final data = await client
        .from(tableName)
        .select()
        .eq('staff_id', staffId)
        .gte('date', fromStr)
        .lte('date', toStr)
        .order('date', ascending: true);
    return data.map(StaffSchedule.fromJson).toList();
  }

  Future<StaffSchedule> create(StaffSchedule schedule) async {
    final data = await insert(schedule.toInsertJson());
    return StaffSchedule.fromJson(data);
  }

  Future<StaffSchedule> updateSchedule(StaffSchedule schedule) async {
    final data = await update(schedule.id, schedule.toUpdateJson());
    return StaffSchedule.fromJson(data);
  }

  Future<void> deleteSchedule(String id) => delete(id);
}
