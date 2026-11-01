import 'package:acendra/features/dashboard/domain/entities/student_home.dart';
import 'package:acendra/features/dashboard/domain/repositories/student_home_repository.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';

/// Composes existing owner/session-checked reads. Never opens lesson content or
/// writes progress just to render Home.
class ReadStudentHomeRepository implements StudentHomeRepository {
  const ReadStudentHomeRepository({
    required this.courses,
    required this.progress,
    required this.learning,
    required this.lessonProgress,
  });

  final MyCoursesRepository courses;
  final CourseProgressRepository progress;
  final LearningRepository learning;
  final LearningProgressRepository lessonProgress;

  @override
  Future<StudentHome> load() async {
    final enrolled = await courses.listEnrolled();
    if (enrolled.isEmpty) return const StudentHome();
    final summaries = <String, CourseProgress>{};
    try {
      final result = await progress.summary();
      for (final course in enrolled) {
        final p = result[course.courseId];
        if (p == null) continue;
        if (p.courseId != course.courseId ||
            p.totalLessons < 0 ||
            p.completedLessons < 0 ||
            p.completedLessons > p.totalLessons) {
          throw const FormatException('Invalid progress summary');
        }
        summaries[course.courseId] = p;
      }
    } catch (_) {
      return StudentHome(
        courses: enrolled,
        progressUnavailable: true,
        recentUnavailable: true,
      );
    }

    final next = <String, HomeLesson>{};
    final recent = <HomeLesson>[];
    var recentUnavailable = summaries.length != enrolled.length;
    // Read one course at a time to bound concurrent requests. Only courses with
    // recorded activity need lesson metadata; unstarted courses open overview.
    for (final course in enrolled) {
      final p = summaries[course.courseId];
      if (p == null || !p.isStarted) continue;
      try {
        final sections = await learning.getCurriculumWithLessons(
          course.courseId,
        );
        final lessons = [for (final section in sections) ...section.lessons];
        final saved = await lessonProgress.read(course.courseId);
        for (var i = 0; i < lessons.length; i++) {
          final lesson = lessons[i];
          if (lesson.id == p.nextLessonId && !p.isCompleted) {
            next[course.courseId] = HomeLesson(
              course: course,
              lesson: lesson,
              number: i + 1,
            );
          }
          final matches = saved.where((entry) => entry.lessonId == lesson.id);
          if (matches.length != 1 || matches.single.lastOpenedAt == null) {
            continue;
          }
          recent.add(
            HomeLesson(
              course: course,
              lesson: lesson,
              number: i + 1,
              lastOpenedAt: matches.single.lastOpenedAt,
              pdfPage: matches.single.pdfPage,
            ),
          );
        }
      } catch (_) {
        recentUnavailable = true;
      }
    }
    recent.sort((a, b) {
      final order = b.lastOpenedAt!.compareTo(a.lastOpenedAt!);
      return order == 0 ? a.path.compareTo(b.path) : order;
    });
    return StudentHome(
      courses: enrolled,
      progress: summaries,
      nextLessons: next,
      recent: recent.take(4).toList(),
      progressUnavailable: summaries.length != enrolled.length,
      recentUnavailable: recentUnavailable,
    );
  }
}
