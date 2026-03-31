import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class StaffRepository extends BaseRepository {
  StaffRepository(SupabaseClient client) : super(client, 'staff');

  Future<List<Staff>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);

    if (activeOnly) query = query.eq('is_active', true);

    final data = await query.order('full_name', ascending: true);
    return data.map(Staff.fromJson).toList();
  }

  Future<Staff?> get(String id) async {
    final data = await getById(id);
    return data != null ? Staff.fromJson(data) : null;
  }

  Future<Staff> create(Staff staff) async {
    final data = await insert(staff.toInsertJson());
    return Staff.fromJson(data);
  }

  Future<Staff> updateStaff(Staff staff) async {
    final data = await update(staff.id, staff.toUpdateJson());
    return Staff.fromJson(data);
  }

  /// Get the current logged-in staff member.
  Future<Staff?> getCurrentStaff() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await client
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    return data != null ? Staff.fromJson(data) : null;
  }

  /// Get doctors only.
  Future<List<Staff>> getDoctors(String clinicId) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('role', StaffRole.doctor.dbValue)
        .eq('is_active', true)
        .order('full_name', ascending: true);
    return data.map(Staff.fromJson).toList();
  }
}
