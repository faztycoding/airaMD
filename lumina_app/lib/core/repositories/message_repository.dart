import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class MessageRepository extends BaseRepository {
  MessageRepository(SupabaseClient client) : super(client, 'message_logs');

  Future<List<MessageLog>> list({
    required String clinicId,
    int? limit,
  }) async {
    final data = await getAll(
      clinicId: clinicId,
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
    );
    return data.map(MessageLog.fromJson).toList();
  }

  Future<MessageLog> create(MessageLog log) async {
    final data = await insert(log.toInsertJson());
    return MessageLog.fromJson(data);
  }

  Future<List<MessageLog>> getByPatient({
    required String patientId,
    int limit = 50,
  }) async {
    final data = await client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map(MessageLog.fromJson).toList();
  }
}
