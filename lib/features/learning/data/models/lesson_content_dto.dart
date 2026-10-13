import 'package:acendra/features/learning/domain/entities/lesson_content.dart';

class LessonContentDto extends LessonContent {
  const LessonContentDto({
    required super.id,
    required super.title,
    required super.lessonType,
    required super.position,
    required super.sectionId,
    super.contentText,
    super.contentImageUrl,
  });

  factory LessonContentDto.fromJson(Map<String, dynamic> json) {
    return LessonContentDto(
      id: json['id'] as String,
      title: json['title'] as String,
      lessonType: json['lesson_type'] as String,
      position: json['position'] as int,
      sectionId: json['section_id'] as String,
    );
  }
}
