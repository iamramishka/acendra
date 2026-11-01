import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
// CSA-181 — Admin course publishing journey tests.
// Widget-level integration tests covering the full admin course publishing flow
// against fake repositories (no real Supabase needed).

import 'dart:async';

import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:acendra/features/admin/presentation/screens/admin_courses_screen.dart';
import 'package:acendra/features/admin/presentation/screens/course_editor_screen.dart';
import 'package:acendra/features/admin/presentation/screens/curriculum_builder_screen.dart';
import 'package:acendra/features/admin/presentation/screens/lesson_editor_screen.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  @override
  Future<void> reorderSections(
    String courseId,
    List<String> ids, {
    String? expectedUpdatedAt,
  }) async {
    final sections = _curriculum[courseId]!;
    _curriculum[courseId] = [
      for (var i = 0; i < ids.length; i++)
        sections.firstWhere((s) => s.id == ids[i]).copyWith(sortOrder: i),
    ];
  }

  @override
  Future<void> reorderLessons(
    String courseId,
    String sectionId,
    List<String> ids, {
    String? expectedUpdatedAt,
  }) async {
    final section = _curriculum[courseId]!.firstWhere((s) => s.id == sectionId);
    await upsertSection(
      section.copyWith(
        lessons: [
          for (var i = 0; i < ids.length; i++)
            section.lessons
                .firstWhere((l) => l.id == ids[i])
                .copyWith(sortOrder: i),
        ],
      ),
    );
  }

  final publicationActions = <String>[];
  final archiveActions = <({String courseId, String? revision})>[];
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
  Future<void> archiveCourse(
    String courseId, {
    String? expectedUpdatedAt,
  }) async {
    archiveActions.add((courseId: courseId, revision: expectedUpdatedAt));
    _courses.removeWhere((c) => c.id == courseId);
  }

  @override
  Future<void> publishCourse(
    String courseId, {
    String? expectedUpdatedAt,
  }) async {
    publicationActions.add('publish:$courseId');
    final i = _courses.indexWhere((c) => c.id == courseId);
    if (i != -1) _courses[i] = _courses[i].copyWith(isPublished: true);
  }

  @override
  Future<void> unpublishCourse(
    String courseId, {
    String? expectedUpdatedAt,
  }) async {
    publicationActions.add('unpublish:$courseId');
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
  Future<void> deleteSection(
    String sectionId, {
    String? expectedUpdatedAt,
  }) async {
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
  Future<void> deleteLesson(
    String lessonId, {
    String? expectedUpdatedAt,
  }) async {
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
class _UnavailableCourseRepository extends _FakeAdminCourseRepository {
  int reads = 0;
  @override
  Future<List<AdminCourse>> listCourses() async {
    reads++;
    throw const AdminDataException('Course service unavailable. Retry.');
  }

  @override
  Future<AdminCourse> getCourse(String courseId) async {
    reads++;
    throw const AdminDataException('Course service unavailable. Retry.');
  }

  @override
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId) async {
    reads++;
    throw const AdminDataException('Course service unavailable. Retry.');
  }
}

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

class _FailPublicationRepository extends _FakeAdminCourseRepository {
  bool fail = true;
  @override
  Future<void> publishCourse(
    String courseId, {
    String? expectedUpdatedAt,
  }) async {
    if (fail) throw Exception('Publication unavailable');
    await super.publishCourse(courseId, expectedUpdatedAt: expectedUpdatedAt);
  }
}

class _RevisionCheckingPublicationRepository extends _FailPublicationRepository
    implements AdminCourseMutationRevisions {
  String? revision;
  int writes = 0;
  @override
  String? ownMutationRevision(String courseId) => revision;
  @override
  Future<void> updateCourse(AdminCourse course) async {
    if (revision != null && course.rawUpdatedAt != revision) {
      throw Exception('Stale revision');
    }
    await super.updateCourse(course);
    revision = 'own-revision-${++writes}';
  }
}

class _DelayedSaveRepository extends _FakeAdminCourseRepository {
  final started = Completer<void>();
  final complete = Completer<void>();
  @override
  Future<void> createCourse(AdminCourse course) async {
    started.complete();
    await complete.future;
    await super.createCourse(course);
  }
}

final _selectedRepository = StateProvider<AdminCourseRepository?>(
  (ref) => null,
);
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Wraps a screen in a minimal GoRouter that covers all admin paths screens
// navigate to via context.go(), overrides the repo provider, and starts at
// /test to avoid the admin shell or authentication guard.
Widget _wrap(
  Widget screen,
  AdminCourseRepository repo, {
  Brightness brightness = Brightness.light,
}) {
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
    overrides: [
      adminCourseRepositoryProvider.overrideWith(
        (ref) => ref.watch(_selectedRepository) ?? repo,
      ),
    ],
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true, brightness: brightness),
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

class _UnusedSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _sessionState = StateProvider<Session?>((ref) => null);
Session _session(
  String userId,
  String sessionId,
  int expiry, {
  String aal = 'aal2',
}) {
  final header = base64Url.encode(utf8.encode('{}'));
  final claims = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': userId,
        'session_id': sessionId,
        'aal': aal,
        'exp': expiry,
      }),
    ),
  );
  return Session(
    accessToken: '$header.$claims.signature',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-20T00:00:00Z',
    ),
  );
}

void main() {
  testWidgets(
    'archive confirmation preserves history and pins the displayed revision',
    (tester) async {
      final repo = _FakeAdminCourseRepository();
      repo._courses[0] = repo._courses[0].copyWith(
        rawUpdatedAt: '2026-10-20T00:00:00.123456Z',
      );
      final retained = await repo.getCurriculum('course-1');
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(const AdminCoursesScreen(), repo));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Archive').first);
      await tester.tap(find.text('Archive').first);
      await tester.pumpAndSettle();
      expect(find.text('Archive Course'), findsOneWidget);
      expect(
        find.textContaining('audit history will be preserved'),
        findsOneWidget,
      );
      expect(repo.archiveActions, isEmpty);
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();
      expect(repo.archiveActions.single, (
        courseId: 'course-1',
        revision: '2026-10-20T00:00:00.123456Z',
      ));
      expect(
        find.text('Course archived. Existing history has been preserved.'),
        findsOneWidget,
      );
      expect(await repo.getCurriculum('course-1'), retained);
      expect(find.text('Flutter for Beginners'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final screen in <Widget>[
    const AdminCoursesScreen(),
    const CourseEditorScreen(courseId: 'course-draft'),
    const CurriculumBuilderScreen(courseId: 'course-1'),
    const LessonEditorScreen(courseId: 'course-1', lessonId: 'l1'),
  ]) {
    testWidgets(
      'known admin failure immediately exposes retry on ${screen.runtimeType}',
      (tester) async {
        final repo = _UnavailableCourseRepository();
        await tester.pumpWidget(_wrap(screen, repo));
        await tester.pumpAndSettle();
        expect(find.text('Course service unavailable. Retry.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        await tester.pump(const Duration(seconds: 30));
        expect(repo.reads, 1);
      },
    );
  }
  for (final categories in <Map<String, String>>[
    {},
    {'other-category': 'Other category'},
  ]) {
    testWidgets(
      'inactive category remains editable with ${categories.length} active categories',
      (tester) async {
        final repo = _FakeAdminCourseRepository(
          courses: [
            AdminCourse(
              id: 'course-draft',
              title: 'Old category course',
              description: 'Description',
              price: 10,
              priceMinor: '1000',
              categoryId: 'inactive-category',
              categories: categories,
              isPublished: false,
              enrollmentCount: 0,
              sectionCount: 0,
              lessonCount: 0,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ],
        );
        await tester.pumpWidget(
          _wrap(const CourseEditorScreen(courseId: 'course-draft'), repo),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        expect(
          find.text('Current category (inactive or unavailable)'),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.text('Current category (inactive or unavailable)'),
        );
        await tester.tap(
          find.text('Current category (inactive or unavailable)'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('No category').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect((await repo.getCourse('course-draft')).categoryId, null);
      },
    );
  }

  testWidgets(
    'same-session token refresh retains unsaved form; account switch clears it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSessionProvider.overrideWith(
              (ref) => ref.watch(_sessionState),
            ),
            _sessionState.overrideWith(
              (ref) => _session('admin', 'same-session', 1),
            ),
            adminCourseClientProvider.overrideWithValue(
              _UnusedSupabaseClient(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CourseEditorScreen(courseId: 'new')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CourseEditorScreen)),
      );
      await tester.enterText(
        find.byType(TextField).first,
        'Unsaved during token refresh',
      );
      await tester.enterText(find.byType(TextField).at(2), '19.99');
      container.read(_sessionState.notifier).state = _session(
        'admin',
        'same-session',
        2,
      );
      await tester.pumpAndSettle();
      expect(find.text('Unsaved during token refresh'), findsOneWidget);
      expect(find.text('19.99'), findsOneWidget);
      container.read(_sessionState.notifier).state = _session(
        'other-admin',
        'other-session',
        3,
      );
      await tester.pumpAndSettle();
      expect(find.text('Unsaved during token refresh'), findsNothing);
      expect(find.text('19.99'), findsNothing);
    },
  );

  testWidgets(
    'account switch while section delete dialog is open cancels old command',
    (tester) async {
      final repo = _FakeAdminCourseRepository();
      final replacement = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-1'), repo),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CurriculumBuilderScreen)),
      );
      await tester.tap(find.byTooltip('Section actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete section'));
      await tester.pumpAndSettle();
      container.read(_selectedRepository.notifier).state = replacement;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect((await repo.getCurriculum('course-1')).length, 1);
      expect((await replacement.getCurriculum('course-1')).length, 1);
      expect(find.text('Getting Started'), findsOneWidget);
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets('course list preserves exact fractional price at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _FakeAdminCourseRepository();
      repo._courses[0] = repo._courses[0].copyWith(
        price: 123.45,
        priceMinor: '12345',
      );
      await tester.pumpWidget(_wrap(const AdminCoursesScreen(), repo));
      await tester.pumpAndSettle();
      expect(find.text('LKR 123.45'), findsOneWidget);
      expect(find.text('LKR 123'), findsNothing);
      expect(tester.takeException(), null);
    });
  }

  testWidgets('metadata can be edited after own save and publication failure', (
    tester,
  ) async {
    final repo = _RevisionCheckingPublicationRepository();
    await tester.pumpWidget(
      _wrap(const CourseEditorScreen(courseId: 'course-draft'), repo),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(
      find.byType(TextField).first,
      'Updated after publication failure',
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    repo.fail = false;
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.writes, 2);
    expect(find.text('Course updated.'), findsOneWidget);
    expect(
      (await repo.getCourse('course-draft')).title,
      'Updated after publication failure',
    );
  });
  testWidgets(
    'session change during save cannot show success or navigate new account',
    (tester) async {
      final repo = _DelayedSaveRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'new'), repo),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Old account draft');
      await tester.enterText(find.byType(TextField).at(2), '10');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CourseEditorScreen)),
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(repo.started.isCompleted, true);
      container.read(_selectedRepository.notifier).state =
          _FakeAdminCourseRepository();
      await tester.pumpAndSettle();
      repo.complete.complete();
      await tester.pumpAndSettle();
      expect(find.text('Course created.'), findsNothing);
      expect(find.text('New Course'), findsOneWidget);
      expect(find.text('Old account draft'), findsNothing);
    },
  );

  testWidgets(
    'retry after publication failure does not create duplicate course',
    (tester) async {
      final repo = _FailPublicationRepository();
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'new'), repo),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Retry publication');
      await tester.enterText(find.byType(TextField).at(2), '10.99');
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Course details saved. Unable to change publication. Retry.'),
        findsOneWidget,
      );
      expect(
        repo._courses.where((c) => c.title == 'Retry publication').length,
        1,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      repo.fail = false;
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        repo._courses.where((c) => c.title == 'Retry publication').length,
        1,
      );
      expect(
        repo._courses
            .firstWhere((c) => c.title == 'Retry publication')
            .isPublished,
        true,
      );
    },
  );
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('course and lesson editors fit $width in $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _FakeAdminCourseRepository();
        await tester.pumpWidget(
          _wrap(
            const CourseEditorScreen(courseId: 'new'),
            repo,
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          _wrap(
            const LessonEditorScreen(
              courseId: 'course-1',
              lessonId: 'new',
              sectionId: 's1',
            ),
            repo,
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
      });
    }
  }
  for (final isNew in [false, true]) {
    testWidgets(
      'lesson save preserves selected section and position (new: $isNew)',
      (tester) async {
        final repo = _FakeAdminCourseRepository(
          curriculum: {
            'course-1': [
              const AdminCurriculumSection(
                id: 'first',
                courseId: 'course-1',
                title: 'First',
                sortOrder: 0,
                lessons: [],
              ),
              const AdminCurriculumSection(
                id: 'second',
                courseId: 'course-1',
                title: 'Second',
                sortOrder: 1,
                lessons: [
                  AdminLesson(
                    id: 'existing',
                    sectionId: 'second',
                    courseId: 'course-1',
                    title: 'Existing',
                    description: 'Metadata',
                    lessonType: LessonType.text,
                    sortOrder: 7,
                    isPreviewed: false,
                    isPublished: true,
                  ),
                ],
              ),
            ],
          },
        );
        await tester.pumpWidget(
          _wrap(
            LessonEditorScreen(
              courseId: 'course-1',
              lessonId: isNew ? 'new' : 'existing',
              sectionId: isNew ? 'second' : null,
            ),
            repo,
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Saved lesson');
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        final sections = await repo.getCurriculum('course-1');
        expect(sections.first.lessons, isEmpty);
        final saved = sections.last.lessons.firstWhere(
          (l) => l.title == 'Saved lesson',
        );
        expect(saved.sectionId, 'second');
        expect(saved.sortOrder, isNew ? 8 : 7);
        if (isNew) expect(saved.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
        if (!isNew) expect(saved.isPublished, true);
      },
    );
  }
  testWidgets(
    'course editor preserves fractional price without changing publication',
    (tester) async {
      final repo = _FakeAdminCourseRepository();
      final original = repo._courses[1];
      repo._courses[1] = original.copyWith(price: 123.45, priceMinor: '12345');
      await tester.pumpWidget(
        _wrap(const CourseEditorScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();
      expect(find.text('123.45'), findsOneWidget);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect((await repo.getCourse('course-draft')).priceMinor, '12345');
      expect(repo.publicationActions, isEmpty);
    },
  );

  for (final courseId in ['new', 'course-draft']) {
    testWidgets('Cancel leaves $courseId editor without saving', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(CourseEditorScreen(courseId: courseId), repo),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Unsaved changes');
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Admin Courses'), findsOneWidget);
      expect(find.text('Unsaved changes'), findsNothing);
      expect(
        (await repo.listCourses()).any(
          (course) => course.title == 'Unsaved changes',
        ),
        isFalse,
      );
    });
  }
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

    testWidgets('empty-state Add Section reveals the section title form', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AppEmptyState),
          matching: find.text('Add Section'),
        ),
      );
      await tester.pump();

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets(
      'cancel restores one empty-state action and session switch clears the form',
      (tester) async {
        final repo = _FakeAdminCourseRepository();
        await tester.pumpWidget(
          _wrap(const CurriculumBuilderScreen(courseId: 'course-draft'), repo),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add Section'), findsOneWidget);
        await tester.tap(find.text('Add Section'));
        await tester.pump();
        expect(find.text('Add Section'), findsNothing);
        await tester.enterText(find.byType(TextField), 'Private unsaved title');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Add Section'), findsOneWidget);
        await tester.tap(find.text('Add Section'));
        await tester.pump();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CurriculumBuilderScreen)),
        );
        final replacement = _FakeAdminCourseRepository();
        container.read(_selectedRepository.notifier).state = replacement;
        await tester.pumpAndSettle();
        expect(find.text('Private unsaved title'), findsNothing);
        expect(find.text('Add Section'), findsOneWidget);
        expect(await repo.getCurriculum('course-draft'), isEmpty);
        expect(await replacement.getCurriculum('course-draft'), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('saved section title appears in the curriculum list', (
      tester,
    ) async {
      final repo = _FakeAdminCourseRepository();
      await tester.pumpWidget(
        _wrap(const CurriculumBuilderScreen(courseId: 'course-draft'), repo),
      );
      await tester.pumpAndSettle();

      // Empty courses expose one action; save uses the trusted repository.
      expect(find.text('Add Section'), findsOneWidget);
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
        await tester.ensureVisible(publishSwitch);
        await tester.tap(publishSwitch);
        await tester.pump();

        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Course updated.'), findsOneWidget);
        expect(repo.publicationActions, ['publish:course-draft']);
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
