import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

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

  /// Mark an outstanding record as fully paid (legacy — prefer settleCharge).
  Future<void> markAsPaid(String recordId) async {
    await client
        .from(tableName)
        .update({'is_outstanding': false})
        .eq('id', recordId);
  }

  /// Atomically settle part or all of an outstanding charge via the
  /// `settle_charge` RPC (migration 028). Increments `amount_paid` by
  /// [amount], flips `is_outstanding=false` when fully paid, and inserts
  /// a matching PAYMENT record — all in a single server-side transaction.
  ///
  /// [method] is the [PaymentMethod.dbValue] string ('CASH', 'TRANSFER', …).
  /// Throws [UnknownRepositoryException] on server-side errors such as
  /// `payment_exceeds_remaining` or `record_already_paid`.
  Future<FinancialRecord> settleCharge(
    String recordId,
    double amount,
    String method,
  ) async {
    try {
      final result = await client.rpc('settle_charge', params: {
        'p_record_id': recordId,
        'p_amount': amount,
        'p_method': method.isEmpty ? null : method,
      });
      if (result == null) throw const NotFoundException('financial_record');
      return FinancialRecord.fromJson(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (e) {
      if (e.code == 'P0002' || e.message.contains('not found')) {
        throw const NotFoundException('financial_record');
      }
      throw UnknownRepositoryException(e.message, e);
    }
  }

  /// Sum of PAYMENT records for a specific calendar day.
  /// Used by [revenueTrendProvider] to compare today vs same weekday last week.
  Future<double> revenueForDate(String clinicId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final records = await getByDateRange(
      clinicId: clinicId,
      from: dayStart,
      to: dayEnd,
    );
    return records
        .where((r) => r.type == FinancialType.payment)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Calculate today's revenue for a clinic.
  ///
  /// Pushes the SUM down to Postgres via the `get_today_revenue` RPC
  /// (migration 009) so the dashboard does a single round trip even on
  /// clinics with thousands of daily transactions, instead of fetching every
  /// row to the client and summing in Dart.
  Future<double> todayRevenue(String clinicId) async {
    final result = await client.rpc(
      'get_today_revenue',
      params: {'p_clinic_id': clinicId},
    );
    if (result == null) return 0;
    return (result as num).toDouble();
  }
}
