import 'package:acendra/features/marketplace/data/models/category_dto.dart';
import 'package:acendra/features/marketplace/data/models/course_detail_dto.dart';
import 'package:acendra/features/marketplace/data/models/course_summary_dto.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
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
          'id, slug, title, short_description, price_minor, currency_code, published_at, category_id',
        )
        .eq('status', 'published')
        .not('title', 'ilike', 'SANDBOX TEST%')
        .order('published_at', ascending: false)
        .limit(20);
    return (rows as List<dynamic>)
        .map((r) => CourseSummaryDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Category>> listCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, name, slug')
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List<dynamic>)
        .map((r) => CategoryDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CourseDetail> getCourseDetail(String courseId) async {
    final row = await _client
        .from('courses')
        .select(
          'id, slug, title, short_description, description, price_minor, currency_code, published_at, category_id, '
          'course_sections(id, title, position, lessons(id, title, lesson_type, position, is_preview, duration_seconds))',
        )
        .eq('id', courseId)
        .eq('status', 'published')
        .not('title', 'ilike', 'SANDBOX TEST%')
        .single();
    return CourseDetailDto.fromJson(row);
  }

  @override
  Future<bool> isEnrolled(String courseId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final rows = await _client
        .from('enrollments')
        .select('id')
        .eq('course_id', courseId)
        .eq('status', 'active')
        .limit(1);
    return (rows as List<dynamic>).isNotEmpty;
  }
}

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return SupabaseCourseRepository(Supabase.instance.client);
});
