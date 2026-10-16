// CSA-181 — Admin course publishing journey tests.
// Widget-level integration tests covering the full admin course publishing flow
// against fake repositories (no real Supabase needed).

import 'dart:async';

import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:acendra/features/admin/presentation/screens/admin_courses_screen.dart';
import 'package:acendra/features/admin/presentation/screens/course_editor_screen.dart';
import 'package:acendra/features/admin/presentation/screens/curriculum_builder_screen.dart';
import 'package:acendra/features/admin/presentation/screens/lesson_editor_screen.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeAdminCourseRepository implements AdminCourseRepository {
  _FakeAdminCourseRepository({
    List<AdminCourse>? courses,
    Map<String, List<AdminCurriculumSection>>? curriculum,
  }) : _courses = courses ?? _defaultCourses(),
       _curriculum = curriculum ?? _defaultCurriculum();

  final List<AdminCourse> _courses;
  final Map<String, List<AdminCurriculumSection>> _curriculum;

  static List<AdminCourse> _defaultCourses() => [
    AdminCourse(
      id: 'course-1',
      title: 'Flutter for Beginners',
      description: 'Learn Flutter from scratch.',
      price: 4500,
      currency: 'LKR',
      isPublished: true,
      enrollmentCount: 10,
      sectionCount: 2,
      lessonCount: 5,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    ),
    AdminCourse(
      id: 'course-draft',
      title: 'Draft Course',
      description: 'Work in progress.',
      price: 3000,
      currency: 'LKR',
      isPublished: false,
      enrollmentCount: 0,
      sectionCount: 1,
      lessonCount: 2,
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 2),
    ),
  ];

  static Map<String, List<AdminCurriculumSection>> _defaultCurriculum() => {
    'course-1': [
      const AdminCurriculumSection(
        id: 's1',
        courseId: 'course-1',
        title: 'Getting Started',
        sortOrder: 0,
        lessons: [
          AdminLesson(
            id: 'l1',
            sectionId: 's1',
            courseId: 'course-1',
            title: 'Introduction',
            description: 'Overview.',
            lessonType: LessonType.video,
            sortOrder: 0,
            isPreviewed: true,
            durationSeconds: 300,
          ),
        ],
      ),
    ],
    'course-draft': [],
  };

  @override
  Future<List<AdminCourse>> listCourses() async => List.unmodifiable(_courses);

  @override
  Future<AdminCourse> getCourse(String courseId) async =>
      _courses.firstWhere((c) => c.id == courseId);

  @override
  Future<void> createCourse(AdminCourse course) async {
    _courses.add(course);
  }

  @override
  Future<void> updateCourse(AdminCourse course) async {
    final i = _courses.indexWhere((c) => c.id == course.id);
    if (i != -1) _courses[i] = course;
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    _courses.removeWhere((c) => c.id == courseId);
  }

  @override
  Future<void> publishCourse(String courseId) async {
    final i = _courses.indexWhere((c) => c.id == courseId);
    if (i != -1) _courses[i] = _courses[i].copyWith(isPublished: true);
  }

  @override
  Future<void> unpublishCourse(String courseId) async {
    final i = _courses.indexWhere((c) => c.id == courseId);
    if (i != -1) _courses[i] = _courses[i].copyWith(isPublished: false);
  }

  @override
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId) async =>
      List<AdminCurriculumSection>.from(_curriculum[courseId] ?? []);

  @override
  Future<void> upsertSection(AdminCurriculumSection section) async {
    final sections = List<AdminCurriculumSection>.from(
      _curriculum[section.courseId] ?? [],
    );
    final i = sections.indexWhere((s) => s.id == section.id);
    if (i != -1) {
      sections[i] = section;
    } else {
      sections.add(section);
    }
    _curriculum[section.courseId] = sections;
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    for (final key in _curriculum.keys) {
      final sections = List<AdminCurriculumSection>.from(_curriculum[key]!);
      sections.removeWhere((s) => s.id == sectionId);
      _curriculum[key] = sections;
    }
  }

  @override
  Future<void> upsertLesson(AdminLesson lesson) async {
    final sections = List<AdminCurriculumSection>.from(
      _curriculum[lesson.courseId] ?? [],
    );
    final sIndex = sections.indexWhere((s) => s.id == lesson.sectionId);
    if (sIndex != -1) {
      final lessons = List<AdminLesson>.from(sections[sIndex].lessons);
      final lIndex = lessons.indexWhere((l) => l.id == lesson.id);
      if (lIndex != -1) {
        lessons[lIndex] = lesson;
      } else {
        lessons.add(lesson);
      }
      sections[sIndex] = sections[sIndex].copyWith(lessons: lessons);
      _curriculum[lesson.courseId] = sections;
    } else {
      // Create an implicit section when none exists for this sectionId.
      final newSection = AdminCurriculumSection(
        id: lesson.sectionId,
        courseId: lesson.courseId,
        title: 'Default',
        sortOrder: sections.length,
        lessons: [lesson],
      );
      _curriculum[lesson.courseId] = [...sections, newSection];
    }
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    for (final key in _curriculum.keys) {
      final sections = List<AdminCurriculumSection>.from(_curriculum[key]!);
      for (var i = 0; i < sections.length; i++) {
        final lessons = sections[i].lessons
            .where((l) => l.id != lessonId)
            .toList();
        sections[i] = sections[i].copyWith(lessons: lessons);
      }
      _curriculum[key] = sections;
    }
  }
}

// Returns a Future that never completes — keeps providers in loading state.
class _NeverLoadingRepository extends _FakeAdminCourseRepository {
  @override
  Future<List<AdminCourse>> listCourses() =>
      Completer<List<AdminCourse>>().future;
}

// Throws on write operations to simulate server errors.
class _FailSaveAdminCourseRepository extends _FakeAdminCourseRepository {
  @override
  Future<void> createCourse(AdminCourse course) async =>
      throw Exception('Server error');

  @override
  Future<void> updateCourse(AdminCourse course) async =>
      throw Exception('Server error');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Wraps a screen in a minimal GoRouter that covers all admin paths screens
// navigate to via context.go(), overrides the repo provider, and starts at
// /test to avoid the admin shell or authentication guard.
Widget _wrap(Widget screen, AdminCourseRepository repo) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (_, _) => Scaffold(body: screen),
      ),
      GoRoute(
        path: '/admin/courses',
        builder: (_, _) => const Scaffold(body: Text('Admin Courses')),
      ),
      GoRoute(
        path: '/admin/courses/new/edit',
        builder: (_, _) => const Scaffold(body: Text('New Course Editor')),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/edit',
        builder: (_, _) => const Scaffold(body: Text('Course Editor')),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/curriculum',
        builder: (_, _) => const Scaffold(body: Text('Curriculum Builder')),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/curriculum/new/edit',
        builder: (_, _) => const Scaffold(body: Text('New Lesson Editor')),
      ),
      GoRoute(
        path: '/admin/courses/:courseId/curriculum/:lessonId/edit',
        builder: (_, _) => const Scaffold(body: Text('Lesson Editor')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [adminCourseRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true),
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // 1. Course list: loading state → populated state
  // -------------------------------------------------------------------------
  group('AdminCoursesScreen — course list', () {
    testWidgets('shows skeleton loading state before courses load', (
      tester,
    ) async {
      // Use a repo whose Future never resolves so the provider stays loading.
      final repo = _NeverLoadingRepository();
      await tester.pumpWidget(_wrap(const AdminCoursesScreen(), repo));

      // After the first frame the provider is AsyncLoading → skeleton appears.
      await tester.pump();
      expect(find.byType(AppSkeleton), findsWidgets);
    });

    testWidgets('shows course titles after loading completes', (tester) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(_wrap(const AdminCoursesScreen(), repo));
      await tester.pumpAndSettle();

      expect(find.text('Flutter for Beginners'), findsOneWidget);
      expect(find.text('Draft Course'), findsOneWidget);
    });

    testWidgets('shows empty-state message when no courses exist', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository(courses: []);
      await tester.pumpWidget(_wrap(const AdminCoursesScreen(), repo));
      await tester.pumpAndSettle();

      expect(
        find.text('No courses yet. Create your first course.'),
        findsOneWidget,
      );
    });

    testWidgets('search box filters course list by title', (tester) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(_wrap(const AdminCoursesScreen(), repo));
      await tester.pumpAndSettle();

      // Only one TextField — the search bar.
      await tester.enterText(find.byType(TextField), 'Draft');
      await tester.pump();

      expect(find.text('Draft Course'), findsOneWidget);
      expect(find.text('Flutter for Beginners'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // 2. Create course: fill fields → save → success feedback
  // -------------------------------------------------------------------------
  group('CourseEditorScreen — create new course', () {
    testWidgets('shows New Course heading for courseId "new"', (tester) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'new'), repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Course'), findsOneWidget);
    });

    testWidgets('saving with empty title shows title validation error', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'new'), repo),
      );
      await tester.pumpAndSettle();

      // Leave title empty; tap Save.
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('saving with empty price shows price validation error', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'new'), repo),
      );
      await tester.pumpAndSettle();

      // Fill title, leave price empty.
      // TextFields order: Title(0), Description(1), Price(2), Thumbnail(3).
      await tester.enterText(find.byType(TextField).at(0), 'My Course');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Price is required'), findsOneWidget);
    });

    testWidgets('valid title and price shows success snackbar on save', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'new'), repo),
      );
      await tester.pumpAndSettle();

      // Fill Title (0) and Price (2); Description and Thumbnail are optional.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'New Test Course');
      await tester.enterText(fields.at(2), '4999');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Course created.'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 3. Open existing draft course → editor loads with pre-filled data
  // -------------------------------------------------------------------------
  group('CourseEditorScreen — edit existing course', () {
    testWidgets('shows Edit Course heading for an existing courseId', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Course'), findsOneWidget);
    });

    testWidgets('pre-fills title and price from existing course data', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();

      // course-draft has title 'Draft Course' and price 3000.
      // find.text() matches EditableText (controller value) as well as Text widgets.
      expect(find.text('Draft Course'), findsOneWidget);
      expect(find.text('3000'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 4. Curriculum builder: add section → add lesson → lesson appears
  // -------------------------------------------------------------------------
  group('CurriculumBuilderScreen', () {
    testWidgets('loads and shows existing sections', (tester) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-1'), repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Getting Started'), findsOneWidget);
    });

    testWidgets('tapping Add Section reveals the section title form', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Section'));
      await tester.pump();

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('saved section title appears in the curriculum list', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Section'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Module 1: Foundations');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Module 1: Foundations'), findsOneWidget);
    });

    testWidgets('expanding a section shows its lessons and Add Lesson button', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-1'), repo),
      );
      await tester.pumpAndSettle();

      // Tap section header to expand.
      await tester.tap(find.text('Getting Started'));
      await tester.pump();

      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Add Lesson'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 5. Lesson editor: open → save → success feedback
  // -------------------------------------------------------------------------
  group('LessonEditorScreen — create new lesson', () {
    testWidgets('shows New Lesson heading for lessonId "new"', (tester) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(
          const LessonEditorScreen(courseId: 'course-1', lessonId: 'new'),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Lesson'), findsOneWidget);
    });

    testWidgets('saving with empty title shows title validation error', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(
          const LessonEditorScreen(courseId: 'course-1', lessonId: 'new'),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('valid title shows success snackbar on save', (tester) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(
          const LessonEditorScreen(courseId: 'course-1', lessonId: 'new'),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      // Title is the first TextField.
      await tester.enterText(
        find.byType(TextField).first,
        'Introduction Video',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson created.'), findsOneWidget);
    });
  });

  group('LessonEditorScreen — edit existing lesson', () {
    testWidgets('shows Edit Lesson heading and pre-fills lesson title', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(
          const LessonEditorScreen(courseId: 'course-1', lessonId: 'l1'),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Lesson'), findsOneWidget);
      // l1 has title 'Introduction' — pre-filled into the title controller.
      expect(find.text('Introduction'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 6. Admin publishes a course (draft → published)
  // -------------------------------------------------------------------------
  group('CourseEditorScreen — publish course', () {
    testWidgets(
      'toggling the Published switch and saving shows success snackbar',
      (tester) async {
        final repo = _FakeAdminCourseRepository();
        await tester.pumpWidget(
          _wrap(const CourseEditorScreen(courseId: 'course-draft'), repo),
        );
        await tester.pumpAndSettle();

        // 'course-draft' has isPublished = false; the Switch is off.
        final publishSwitch = find.byType(Switch);
        expect(publishSwitch, findsOneWidget);

        // Toggle to published.
        await tester.tap(publishSwitch);
        await tester.pump();

        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Course updated.'), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // 7. Error path: save fails → error snackbar shown, user stays on editor
  // -------------------------------------------------------------------------
  group('CourseEditorScreen — save error', () {
    testWidgets(
      'failed save shows error snackbar and keeps user on editor screen',
      (tester) async {
        final repo = _FailSaveAdminCourseRepository();
        await tester.pumpWidget(
          _wrap(const CourseEditorScreen(courseId: 'new'), repo),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Test Course');
        await tester.enterText(fields.at(2), '1000');
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Error snackbar visible.
        expect(find.text('Failed to save course.'), findsOneWidget);
        // User remains on editor (no navigation occurred).
        expect(find.text('New Course'), findsOneWidget);
      },
    );
  });
}
