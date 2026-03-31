import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'base_repository.dart';

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

  /// Increment sessions_used by 1.
  Future<Course> useSession(String courseId) async {
    final course = await get(courseId);
    if (course == null) throw Exception('Course not found');

    final newUsed = course.sessionsUsed + 1;
    final total = course.sessionsTotal ?? (course.sessionsBought + course.sessionsBonus);
    String newStatus = course.status.dbValue;
    if (newUsed >= total) {
      newStatus = CourseStatus.completed.dbValue;
    } else if (total - newUsed <= 1) {
      newStatus = CourseStatus.low.dbValue;
    }

    final data = await update(courseId, {
      'sessions_used': newUsed,
      'status': newStatus,
    });
    return Course.fromJson(data);
  }
}
