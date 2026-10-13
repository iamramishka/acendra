import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';

abstract class LearningRepository {
  Future<List<CurriculumSection>> getCurriculumWithLessons(String courseId);
  Future<LessonContent> getLessonContent(String lessonId);
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId);
}
