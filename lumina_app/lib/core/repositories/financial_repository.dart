import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class FinancialRepository extends BaseRepository {
  FinancialRepository(SupabaseClient client)
      : super(client, 'financial_records');

  Future<List<FinancialRecord>> list({
    required String clinicId,
    String orderBy = 'created_at',
    bool ascending = false,
    int? limit,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: orderBy,
      ascending: ascending,
      limit: limit,
    );
    return data.map(FinancialRecord.fromJson).toList();
  }

  Future<FinancialRecord> create(FinancialRecord record) async {
    final data = await insert(record.toInsertJson());
    return FinancialRecord.fromJson(data);
  }

  /// Get financial records for a patient.
  Future<List<FinancialRecord>> getByPatient({
    required String patientId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(FinancialRecord.fromJson).toList();
  }

  /// Get outstanding (unpaid) records.
  Future<List<FinancialRecord>> getOutstanding(String clinicId) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .eq('is_outstanding', true)
        .order('created_at', ascending: false);
    return data.map(FinancialRecord.fromJson).toList();
  }

  /// Get revenue for a date range.
  Future<List<FinancialRecord>> getByDateRange({
    required String clinicId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId)
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String())
        .order('created_at', ascending: false);
    return data.map(FinancialRecord.fromJson).toList();
  }

  /// Calculate today's revenue for a clinic.
  Future<double> todayRevenue(String clinicId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final records = await getByDateRange(
      clinicId: clinicId,
      from: startOfDay,
      to: endOfDay,
    );

    double total = 0;
    for (final r in records) {
      if (r.type == FinancialType.payment) {
        total += r.amount;
      } else if (r.type == FinancialType.refund) {
        total -= r.amount;
      }
    }
    return total;
  }
}
