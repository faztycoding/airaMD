import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class DeviceRepository extends BaseRepository {
  DeviceRepository(SupabaseClient client) : super(client, 'clinic_devices');

  Future<List<ClinicDevice>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client.from(tableName).select().eq('clinic_id', clinicId);
    if (activeOnly) query = query.eq('is_active', true);
    final data = await query.order('name', ascending: true);
    return data.map(ClinicDevice.fromJson).toList();
  }

  Future<ClinicDevice> create(ClinicDevice device) async {
    final data = await insert(device.toInsertJson());
    return ClinicDevice.fromJson(data);
  }

  Future<ClinicDevice> updateDevice(ClinicDevice device) async {
    final data = await update(device.id, device.toUpdateJson());
    return ClinicDevice.fromJson(data);
  }

  Future<void> deleteDevice(String id) => delete(id);
}
