import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';

class HomeLesson {
  const HomeLesson({
    required this.course,
    required this.lesson,
    required this.number,
    this.lastOpenedAt,
    this.pdfPage,
  });

  final EnrolledCourse course;
  final LessonItem lesson;
  final int number;
  final DateTime? lastOpenedAt;
  final int? pdfPage;
  String get path => '/learn/${course.courseId}/${lesson.id}';
}

class StudentHome {
  const StudentHome({
    this.courses = const [],
    this.progress = const {},
    this.nextLessons = const {},
    this.recent = const [],
    this.progressUnavailable = false,
    this.recentUnavailable = false,
  });

  final List<EnrolledCourse> courses;
  final Map<String, CourseProgress> progress;
  final Map<String, HomeLesson> nextLessons;
  final List<HomeLesson> recent;
  final bool progressUnavailable;
  final bool recentUnavailable;

  HomeLesson? get resume {
    final candidates = courses.where((course) {
      final p = progress[course.courseId];
      return p != null &&
          p.isStarted &&
          !p.isCompleted &&
          nextLessons.containsKey(course.courseId);
    }).toList();
    candidates.sort((a, b) {
      final openedA = progress[a.courseId]!.lastOpenedAt;
      final openedB = progress[b.courseId]!.lastOpenedAt;
      final order = (openedB ?? DateTime(1970)).compareTo(
        openedA ?? DateTime(1970),
      );
      return order == 0 ? a.courseId.compareTo(b.courseId) : order;
    });
    return candidates.isEmpty ? null : nextLessons[candidates.first.courseId];
  }
}
