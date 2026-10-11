import 'package:acendra/features/marketplace/data/models/course_summary_dto.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCourseRepository implements CourseRepository {
  const SupabaseCourseRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseSummary>> listPublished() async {
    final rows = await _client
        .from('courses')
        .select(
          'id, slug, title, short_description, price_minor, currency_code, published_at',
        )
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .limit(20);
    return (rows as List<dynamic>)
        .map((r) => CourseSummaryDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return SupabaseCourseRepository(Supabase.instance.client);
});
