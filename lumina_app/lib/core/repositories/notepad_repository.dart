import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

class NotepadRepository extends BaseRepository {
  NotepadRepository(SupabaseClient client) : super(client, 'digital_notepads');

  Future<List<DigitalNotepad>> getByPatient({
    required String patientId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('updated_at', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(DigitalNotepad.fromJson).toList();
  }

  Future<DigitalNotepad> create(DigitalNotepad notepad) async {
    final data = await insert(notepad.toInsertJson());
    return DigitalNotepad.fromJson(data);
  }

  Future<DigitalNotepad> updateNotepad(DigitalNotepad notepad) async {
    final data = await update(notepad.id, notepad.toUpdateJson());
    return DigitalNotepad.fromJson(data);
  }

  Future<void> deleteNotepad(String id) => delete(id);
}
