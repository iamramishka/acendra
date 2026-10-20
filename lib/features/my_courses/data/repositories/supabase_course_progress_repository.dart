import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class CourseProgressRepository {
  Future<Map<String, CourseProgress>> summary();
}

/// Calls the read-only com015_my_course_progress RPC (one request for all
/// enrolled courses; ownership and entitlement are enforced server-side).
class SupabaseCourseProgressRepository implements CourseProgressRepository {
  const SupabaseCourseProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, CourseProgress>> summary() async {
    final rows = await _client.rpc('com015_my_course_progress');
    return {
      for (final r in (rows as List<dynamic>))
        (r as Map<String, dynamic>)['course_id'] as String:
            CourseProgress.fromJson(r),
    };
  }
}

final courseProgressRepositoryProvider = Provider<CourseProgressRepository>(
  (ref) => SupabaseCourseProgressRepository(Supabase.instance.client),
);

/// Progress is an enhancement: if it cannot be read, screens still list the
/// student's courses and simply omit progress.
final courseProgressProvider =
    FutureProvider.autoDispose<Map<String, CourseProgress>>((ref) async {
      try {
        return await ref.read(courseProgressRepositoryProvider).summary();
      } catch (_) {
        return const {};
      }
    });
