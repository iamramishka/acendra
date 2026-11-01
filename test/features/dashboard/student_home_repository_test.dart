import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/dashboard/data/student_home_repository.dart';
import 'package:acendra/features/dashboard/domain/entities/student_home.dart';
import 'package:acendra/features/dashboard/domain/repositories/student_home_repository.dart';
import 'package:acendra/features/dashboard/presentation/providers/student_home_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const homeCourse = EnrolledCourse(
  id: 'enrollment-a',
  courseId: 'course-a',
  title: 'Flutter Foundations',
  shortDescription: 'Build responsive interfaces.',
  status: 'active',
  enrolledAt: '2026-10-01',
);
const homeLesson = LessonItem(
  id: 'lesson-next',
  title: 'Responsive interfaces',
  lessonType: 'video',
  position: 2,
  isPreview: false,
);
const homePdf = LessonItem(
  id: 'lesson-pdf',
  title: 'Layouts Guide',
  lessonType: 'pdf',
  position: 1,
  isPreview: false,
);
final homeProgress = CourseProgress(
  courseId: homeCourse.courseId,
  totalLessons: 2,
  completedLessons: 1,
  nextLessonId: homeLesson.id,
  lastOpenedAt: DateTime.utc(2026, 10, 26),
);

class _Courses implements MyCoursesRepository {
  List<EnrolledCourse> value = [homeCourse];
  bool fail = false;
  @override
  Future<List<EnrolledCourse>> listEnrolled() async {
    if (fail) throw StateError('enrollment denied');
    return value;
  }
}

class _Progress implements CourseProgressRepository {
  Map<String, CourseProgress> value = {homeCourse.courseId: homeProgress};
  bool fail = false;
  @override
  Future<Map<String, CourseProgress>> summary() async {
    if (fail) throw StateError('RPC unavailable');
    return value;
  }
}

class _Learning implements LearningRepository {
  bool fail = false;
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(String id) async {
    if (fail) throw StateError('curriculum denied');
    return [
      const CurriculumSection(
        id: 'section',
        title: 'Module',
        position: 1,
        lessons: [homePdf, homeLesson],
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Content must not be opened');
}

class _Saved implements LearningProgressRepository {
  bool fail = false;
  @override
  Future<List<SavedLessonProgress>> read(String id) async {
    if (fail) throw StateError('progress denied');
    return [
      SavedLessonProgress(
        lessonId: homePdf.id,
        completed: true,
        pdfPage: 4,
        lastOpenedAt: DateTime.utc(2026, 10, 26),
      ),
      SavedLessonProgress(
        lessonId: homeLesson.id,
        completed: false,
        lastOpenedAt: DateTime.utc(2026, 10, 25),
      ),
      SavedLessonProgress(
        lessonId: 'unpublished-or-foreign',
        completed: false,
        lastOpenedAt: DateTime.utc(2026, 10, 27),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Home must not write progress');
}

class _PendingHome implements StudentHomeRepository {
  final requests = <Completer<StudentHome>>[];
  @override
  Future<StudentHome> load() {
    final request = Completer<StudentHome>();
    requests.add(request);
    return request.future;
  }
}

Session _identity(String id) => Session(
  accessToken: 'token-$id',
  tokenType: 'bearer',
  refreshToken: 'refresh-$id',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-10-01T00:00:00Z',
  ),
);
final _session = StateProvider<Session?>((_) => _identity('student-a'));

void main() {
  late _Courses courses;
  late _Progress progress;
  late _Learning learning;
  late _Saved saved;
  late ReadStudentHomeRepository repository;
  setUp(() {
    courses = _Courses();
    progress = _Progress();
    learning = _Learning();
    saved = _Saved();
    repository = ReadStudentHomeRepository(
      courses: courses,
      progress: progress,
      learning: learning,
      lessonProgress: saved,
    );
  });
  test(
    'resume uses next unfinished lesson; recent uses saved recency and PDF page',
    () async {
      final result = await repository.load();
      expect(result.resume!.path, '/learn/course-a/lesson-next');
      expect(result.resume!.lesson.title, homeLesson.title);
      expect(result.progress[homeCourse.courseId]!.percent, 50);
      expect(result.recent.map((r) => r.lesson.id), [
        homePdf.id,
        homeLesson.id,
      ]);
      expect(result.recent.first.pdfPage, 4);
      expect(result.recent.last.number, 2);
    },
  );
  test(
    'enrollment denial propagates instead of presenting another student data',
    () async {
      courses.fail = true;
      await expectLater(repository.load(), throwsStateError);
    },
  );
  test(
    'failed summary retains courses without inventing progress or recency',
    () async {
      progress.fail = true;
      final result = await repository.load();
      expect(result.courses, [homeCourse]);
      expect(result.progressUnavailable, isTrue);
      expect(result.progress, isEmpty);
      expect(result.resume, isNull);
      expect(result.recent, isEmpty);
    },
  );
  test('invalid summary cannot be displayed as a clamped percentage', () async {
    progress.value = {
      homeCourse.courseId: CourseProgress(
        courseId: homeCourse.courseId,
        totalLessons: 2,
        completedLessons: 3,
      ),
    };
    expect((await repository.load()).progressUnavailable, isTrue);
  });
  test(
    'no enrollments makes no curriculum or progress-dependent read',
    () async {
      courses.value = [];
      progress.fail = true;
      learning.fail = true;
      saved.fail = true;
      final result = await repository.load();
      expect(result.courses, isEmpty);
      expect(result.progressUnavailable, isFalse);
    },
  );
  test('unavailable course details do not invent a resume target', () async {
    saved.fail = true;
    final result = await repository.load();
    expect(result.progress[homeCourse.courseId]!.percent, 50);
    expect(result.recentUnavailable, isTrue);
    expect(result.resume, isNull);
    expect(result.recent, isEmpty);
  });
  test('completed and unstarted courses are not resume candidates', () async {
    for (final count in [0, 2]) {
      progress.value = {
        homeCourse.courseId: CourseProgress(
          courseId: homeCourse.courseId,
          totalLessons: 2,
          completedLessons: count,
        ),
      };
      expect((await repository.load()).resume, isNull);
    }
  });
  test(
    'account change drops old pending result; sign-out clears private Home',
    () async {
      final pending = _PendingHome();
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith((ref) => ref.watch(_session)),
          studentHomeRepositoryProvider.overrideWithValue(pending),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(studentHomeProvider, (_, _) {});
      addTearDown(listener.close);
      await container.pump();
      expect(pending.requests.length, 1);
      container.read(_session.notifier).state = _identity('student-b');
      await container.pump();
      expect(container.read(studentHomeProvider).isLoading, isTrue);
      expect(pending.requests.length, 2);
      pending.requests[1].complete(const StudentHome());
      await container.pump();
      pending.requests[0].complete(const StudentHome(courses: [homeCourse]));
      await container.pump();
      expect(container.read(studentHomeProvider).requireValue.courses, isEmpty);
      container.read(_session.notifier).state = null;
      await container.pump();
      expect(container.read(studentHomeProvider).requireValue.courses, isEmpty);
      expect(pending.requests.length, 2);
    },
  );
}
