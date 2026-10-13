import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';

class CourseDetailDto {
  static CourseDetail fromJson(Map<String, dynamic> json) {
    final sectionsRaw =
        (json['course_sections'] as List<dynamic>? ?? []);
    final sections = sectionsRaw
        .map((s) => _sectionFromJson(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return CourseDetail(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      shortDescription: (json['short_description'] as String?) ?? '',
      description: json['description'] as String?,
      priceMinor: json['price_minor'] as int,
      currencyCode: json['currency_code'] as String,
      publishedAt: json['published_at'] as String,
      categoryId: json['category_id'] as String?,
      sections: sections,
    );
  }

  static CurriculumSection _sectionFromJson(Map<String, dynamic> json) {
    final lessonsRaw = (json['lessons'] as List<dynamic>? ?? []);
    final lessons = lessonsRaw
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
