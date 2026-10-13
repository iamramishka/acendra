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
    final rows = await _client
        .from('enrollments')
        .select(
          'id, course_id, status, created_at, '
          'courses(id, title, short_description, thumbnail_url)',
        )
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => EnrolledCourseDto.fromJson(r as Map<String, dynamic>).toEntity())
        .toList();
  }
}

final myCoursesRepositoryProvider = Provider<MyCoursesRepository>((ref) {
  return SupabaseMyCoursesRepository(Supabase.instance.client);
});
