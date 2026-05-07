import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

class CourseRepository extends BaseRepository {
  CourseRepository(SupabaseClient client) : super(client, 'courses');

  Future<List<Course>> list({
    required String clinicId,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    final data = await getAll(clinicId: clinicId, orderBy: orderBy, ascending: ascending);
    return data.map(Course.fromJson).toList();
  }

  Future<Course?> get(String id) async {
    final data = await getById(id);
    return data != null ? Course.fromJson(data) : null;
  }

  Future<Course> create(Course course) async {
    final data = await insert(course.toInsertJson());
    return Course.fromJson(data);
  }

  Future<Course> updateCourse(Course course) async {
    final data = await update(course.id, course.toUpdateJson());
    return Course.fromJson(data);
  }

  Future<void> deleteCourse(String id) => delete(id);

  /// Get active courses for a patient.
  Future<List<Course>> getByPatient({
    required String patientId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId);

    if (activeOnly) {
      query = query.inFilter('status', [
        CourseStatus.active.dbValue,
        CourseStatus.low.dbValue,
      ]);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map(Course.fromJson).toList();
  }

  /// Atomically increment `sessions_used` by 1 and refresh status.
  ///
  /// Backed by the `use_course_session` RPC (migration 015). Two
  /// concurrent calls are serialised by a row-level lock inside the
  /// RPC — the previous client-side read-modify-write could double-
  /// spend a session when two staff members clicked at the same time.
  ///
  /// Throws [NotFoundException] when the course id is unknown and
  /// [UnknownRepositoryException] for the `course_exhausted` case
  /// (all sessions already used) — callers can `toString()` to
  /// surface the server message.
  Future<Course> useSession(String courseId) async {
    try {
      final result = await client.rpc(
        'use_course_session',
        params: {'p_course_id': courseId},
      );
      if (result == null) {
        throw const NotFoundException('course');
      }
      // The RPC returns a single courses row (as JSONB via PostgREST).
      return Course.fromJson(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (e) {
      if (e.code == 'P0002' || e.message.contains('not found')) {
        throw const NotFoundException('course');
      }
      throw UnknownRepositoryException(e.message, e);
    }
  }
}
