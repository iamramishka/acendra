import 'package:acendra/features/my_courses/data/models/enrolled_course_dto.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMyCoursesRepository implements MyCoursesRepository {
  const SupabaseMyCoursesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EnrolledCourse>> listEnrolled() async {
    final user = _client.auth.currentUser;
    var query = _client
        .from('enrollments')
        .select(
          'id, course_id, status, created_at, '
          // thumbnail_path is a storage reference, not a deliverable URL.
          // Keep the card placeholder until authorized thumbnail delivery exists.
          'courses(id, title, short_description)',
        )
        .eq('status', 'active');
    // Defense-in-depth: add explicit user filter when session is available;
    // RLS enforces user_id = auth.uid() at the database level regardless.
    if (user != null) query = query.eq('user_id', user.id);
    final rows = await query.order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map(
          (r) =>
              EnrolledCourseDto.fromJson(r as Map<String, dynamic>).toEntity(),
        )
        .toList();
  }
}

final myCoursesRepositoryProvider = Provider<MyCoursesRepository>((ref) {
  return SupabaseMyCoursesRepository(Supabase.instance.client);
});
