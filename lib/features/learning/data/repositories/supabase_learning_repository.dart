import 'package:acendra/features/learning/data/models/lesson_content_dto.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLearningRepository implements LearningRepository {
  const SupabaseLearningRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async {
    final rows = await _client
        .from('course_sections')
        .select(
          'id, title, position, lessons(id, title, lesson_type, position, is_preview, duration_seconds)',
        )
        .eq('course_id', courseId)
        .order('position');

    return (rows as List<dynamic>)
        .map((s) => _sectionFromJson(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  @override
  Future<LessonContent> getLessonContent(String lessonId) async {
    final row = await _client
        .from('lessons')
        // content_text and content_image_url are fetched here once the DB migration
        // adds those columns (see Codex content-delivery tasks).
        .select('id, title, lesson_type, position, section_id')
        .eq('id', lessonId)
        .single();
    return LessonContentDto.fromJson(row);
  }

  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) async {
    // Check if lesson is a preview
    final lessonRows = await _client
        .from('lessons')
        .select('is_preview')
        .eq('id', lessonId)
        .limit(1);
    final lessons = lessonRows as List<dynamic>;
    if (lessons.isNotEmpty) {
      final isPreview = lessons.first['is_preview'] as bool? ?? false;
      if (isPreview) return true;
    }

    // Check enrollment
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final enrollmentRows = await _client
        .from('enrollments')
        .select('id')
        .eq('course_id', courseId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .limit(1);
    return (enrollmentRows as List<dynamic>).isNotEmpty;
  }

  static CurriculumSection _sectionFromJson(Map<String, dynamic> json) {
    final lessonsRaw = (json['lessons'] as List<dynamic>? ?? []);
    final lessons =
        lessonsRaw
            .map((l) => _lessonFromJson(l as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    return CurriculumSection(
      id: json['id'] as String,
      title: json['title'] as String,
      position: json['position'] as int,
      lessons: lessons,
    );
  }

  static LessonItem _lessonFromJson(Map<String, dynamic> json) => LessonItem(
    id: json['id'] as String,
    title: json['title'] as String,
    lessonType: json['lesson_type'] as String,
    position: json['position'] as int,
    isPreview: json['is_preview'] as bool,
    durationSeconds: json['duration_seconds'] as int?,
  );
}

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return SupabaseLearningRepository(Supabase.instance.client);
});
