import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCoursesNotifier extends AsyncNotifier<List<AdminCourse>> {
  @override
  Future<List<AdminCourse>> build() async {
    return ref.watch(adminCourseRepositoryProvider).listCourses();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteCourse(String courseId) async {
    await ref.read(adminCourseRepositoryProvider).deleteCourse(courseId);
    ref.invalidateSelf();
  }

  Future<void> publishCourse(String courseId) async {
    await ref.read(adminCourseRepositoryProvider).publishCourse(courseId);
    ref.invalidateSelf();
  }

  Future<void> unpublishCourse(String courseId) async {
    await ref.read(adminCourseRepositoryProvider).unpublishCourse(courseId);
    ref.invalidateSelf();
  }
}

final adminCoursesProvider =
    AsyncNotifierProvider<AdminCoursesNotifier, List<AdminCourse>>(
      AdminCoursesNotifier.new,
      retry: (retryCount, error) => null,
    );

final adminCourseDetailProvider = FutureProvider.autoDispose
    .family<AdminCourse, String>((ref, courseId) {
      return ref.watch(adminCourseRepositoryProvider).getCourse(courseId);
    }, retry: (retryCount, error) => null);

final adminCurriculumProvider = FutureProvider.autoDispose
    .family<List<AdminCurriculumSection>, String>((ref, courseId) {
      return ref.watch(adminCourseRepositoryProvider).getCurriculum(courseId);
    }, retry: (retryCount, error) => null);

final adminLessonDetailProvider = FutureProvider.autoDispose
    .family<AdminLesson?, ({String courseId, String lessonId})>((
      ref,
      args,
    ) async {
      if (args.lessonId == 'new') return null;
      final sections = await ref.watch(
        adminCurriculumProvider(args.courseId).future,
      );
      for (final section in sections) {
        for (final lesson in section.lessons) {
          if (lesson.id == args.lessonId) return lesson;
        }
      }
      return null;
    }, retry: (retryCount, error) => null);
