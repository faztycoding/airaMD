import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class ServiceRepository extends BaseRepository {
  ServiceRepository(SupabaseClient client) : super(client, 'services');

  Future<List<Service>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);

    if (activeOnly) query = query.eq('is_active', true);

    final data = await query.order('name', ascending: true);
    return data.map(Service.fromJson).toList();
  }

  Future<Service?> get(String id) async {
    final data = await getById(id);
    return data != null ? Service.fromJson(data) : null;
  }

  Future<Service> create(Service service) async {
    final data = await insert(service.toInsertJson());
    return Service.fromJson(data);
  }

  Future<Service> updateService(Service service) async {
    final data = await update(service.id, service.toUpdateJson());
    return Service.fromJson(data);
  }

  Future<void> deleteService(String id) => delete(id);

  /// Get services by category.
  Future<List<Service>> getByCategory({
    required String clinicId,
    required ServiceCategory category,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('category', category.dbValue)
        .eq('is_active', true)
        .order('name', ascending: true);
    return data.map(Service.fromJson).toList();
  }
}
