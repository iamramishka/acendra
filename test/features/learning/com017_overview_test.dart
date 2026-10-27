import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/course_overview_provider.dart';
import 'package:acendra/features/learning/presentation/providers/course_overview_metadata_provider.dart';
import 'package:acendra/features/learning/presentation/screens/course_overview_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/presentation/screens/my_courses_screen.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _sections = [
  CurriculumSection(
    id: 's',
    title: 'Getting started',
    position: 1,
    lessons: [
      LessonItem(
        id: 'a',
        title: 'First lesson',
        lessonType: 'video',
        position: 1,
        isPreview: false,
        durationSeconds: 180,
      ),
      LessonItem(
        id: 'b',
        title: 'Reading a long and useful lesson title',
        lessonType: 'pdf',
        position: 2,
        isPreview: false,
        durationSeconds: 120,
      ),
    ],
  ),
];

Session _session(String id) => Session(
  accessToken: 'synthetic-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-27T00:00:00Z',
  ),
);

class _Lessons implements LearningRepository {
  int contentReads = 0;
  List<CurriculumSection> sections = _sections;
  Completer<List<CurriculumSection>>? pending;
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(String id) async =>
      pending == null ? sections : pending!.future;
  @override
  Future<LessonContent> getLessonContent(String id) async {
    contentReads++;
    throw StateError('Overview must not fetch protected content');
  }

  @override
  Future<bool> isEnrolledOrPreview(String course, String lesson) async => false;
}

class _Progress implements LearningProgressRepository {
  List<SavedLessonProgress> rows = [];
  bool fail = false;
  int reads = 0;
  Completer<List<SavedLessonProgress>>? pending;
  @override
  Future<List<SavedLessonProgress>> read(String id) async {
    reads++;
    if (fail) throw StateError('private database failure');
    return pending == null ? rows : pending!.future;
  }

  @override
  Future<SavedLessonProgress> saveCompletion(
    String id,
    bool done,
    SavedLessonProgress? prior,
  ) => throw StateError('Overview must not write progress');
  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String id,
    int seconds,
    SavedLessonProgress? prior,
  ) => throw StateError('Overview must not write progress');
}

class _Courses implements MyCoursesRepository {
  bool fail = false;
  String title = 'Flutter Fundamentals';
  Completer<List<EnrolledCourse>>? pending;
  @override
  Future<List<EnrolledCourse>> listEnrolled() async {
    if (fail) throw StateError('private enrollment detail');
    if (pending != null) return pending!.future;
    return [
      EnrolledCourse(
        id: 'enrollment',
        courseId: 'course',
        title: title,
        shortDescription: 'Learn at your own pace.',
        status: 'active',
        enrolledAt: '2026-10-27',
      ),
    ];
  }
}

ProviderContainer _container(
  _Progress progress, {
  _Lessons? lessons,
  _Courses? courses,
  StateProvider<Session?>? identity,
}) => ProviderContainer(
  overrides: [
    if (identity == null)
      currentSessionProvider.overrideWithValue(_session('student'))
    else
      currentSessionProvider.overrideWith((ref) => ref.watch(identity)),
    learningRepositoryProvider.overrideWithValue(lessons ?? _Lessons()),
    learningProgressRepositoryProvider.overrideWithValue(progress),
    myCoursesRepositoryProvider.overrideWithValue(courses ?? _Courses()),
    courseProgressProvider.overrideWith(
      (ref) async => {
        'course': CourseProgress(
          courseId: 'course',
          totalLessons: 2,
          completedLessons: 0,
          nextLessonId: 'b',
          lastOpenedAt: DateTime.utc(2026, 10, 27),
        ),
      },
    ),
  ],
);

Widget _app(
  ProviderContainer container, {
  bool dark = false,
  double scale = 1,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: const bool.fromEnvironment('COM017_CAPTURE')
          ? Banner(
              message: 'SYNTHETIC',
              location: BannerLocation.topEnd,
              textStyle: const TextStyle(
                fontFamily: 'Inter_regular',
                fontSize: 10,
                color: Colors.white,
              ),
              child: child!,
            )
          : child!,
    ),
    home: const LearningShell(child: CourseOverviewScreen(courseId: 'course')),
  ),
);

void main() {
  if (const bool.fromEnvironment('COM017_CAPTURE')) {
    setUpAll(() async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      for (final name in [
        'Inter_regular',
        'Inter_500',
        'Inter_600',
        'Manrope_600',
        'Manrope_700',
        'Manrope_800',
      ]) {
        await (FontLoader(name)..addFont(
              File(
                'build/com017-fonts/$name.ttf',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      }
    });
    for (final size in [390.0, 768.0, 1440.0]) {
      for (final dark in [false, true]) {
        testWidgets('capture overview $size dark=$dark', (tester) async {
          tester.view.physicalSize = Size(size, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final progress = _Progress()
            ..rows = [
              const SavedLessonProgress(lessonId: 'a', completed: true),
            ];
          final container = _container(progress);
          addTearDown(container.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: _app(container, dark: dark),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/com017-evidence/synthetic-${size.toInt()}-${dark ? 'dark' : 'light'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        });
      }
    }
  }
  test('reload rereads saved completion and curriculum markers', () async {
    final progress = _Progress();
    final container = _container(progress);
    addTearDown(container.dispose);
    final provider = courseOverviewProvider('course');
    container.listen(provider, (_, _) {});
    expect((await container.read(provider.future)).percent, 0);
    progress.rows = [const SavedLessonProgress(lessonId: 'a', completed: true)];
    container.invalidate(provider);
    final updated = await container.read(provider.future);
    expect(updated.percent, 50);
    expect(updated.isCompleted('a'), isTrue);
    expect(updated.nextLesson?.id, 'b');
    expect(progress.reads, 2);
  });

  test(
    'late prior-account progress cannot replace the current account',
    () async {
      final identity = StateProvider<Session?>((ref) => _session('A'));
      final pending = Completer<List<SavedLessonProgress>>();
      final progress = _Progress()..pending = pending;
      final container = _container(progress, identity: identity);
      addTearDown(container.dispose);
      final provider = courseOverviewProvider('course');
      container.listen(provider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      progress.pending = null;
      container.read(identity.notifier).state = _session('B');
      await container.pump();
      expect((await container.read(provider.future)).percent, 0);
      pending.complete([
        const SavedLessonProgress(lessonId: 'a', completed: true),
      ]);
      await container.pump();
      expect(container.read(provider).requireValue.percent, 0);
    },
  );

  test(
    'sign out during curriculum read prevents a late progress read',
    () async {
      final identity = StateProvider<Session?>((ref) => _session('A'));
      final pending = Completer<List<CurriculumSection>>();
      final lessons = _Lessons()..pending = pending;
      final progress = _Progress();
      final container = _container(
        progress,
        lessons: lessons,
        identity: identity,
      );
      addTearDown(container.dispose);
      final provider = courseOverviewProvider('course');
      container.listen(provider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      container.read(identity.notifier).state = null;
      await container.pump();
      await expectLater(container.read(provider.future), throwsStateError);
      expect(container.read(provider).hasError, isTrue);
      pending.complete(_sections);
      await container.pump();
      expect(progress.reads, 0);
    },
  );

  testWidgets('metadata retry preserves independently loaded progress', (
    tester,
  ) async {
    final courses = _Courses()..fail = true;
    final progress = _Progress();
    final container = _container(progress, courses: courses);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Retry course details'), findsOneWidget);
    expect(find.textContaining('private enrollment'), findsNothing);
    courses.fail = false;
    await tester.tap(find.text('Retry course details'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Fundamentals'), findsOneWidget);
    expect(progress.reads, 1);
  });

  test(
    'late prior-account course title cannot replace current metadata',
    () async {
      final identity = StateProvider<Session?>((ref) => _session('A'));
      final pending = Completer<List<EnrolledCourse>>();
      final courses = _Courses()..pending = pending;
      final container = _container(
        _Progress(),
        courses: courses,
        identity: identity,
      );
      addTearDown(container.dispose);
      final provider = courseOverviewMetadataProvider('course');
      container.listen(provider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      courses.pending = null;
      courses.title = 'Current account course';
      container.read(identity.notifier).state = _session('B');
      await container.pump();
      expect(
        (await container.read(provider.future))?.title,
        'Current account course',
      );
      pending.complete([]);
      await container.pump();
      expect(
        container.read(provider).requireValue?.title,
        'Current account course',
      );
    },
  );

  for (final state in ['ready', 'loading', 'error', 'empty']) {
    testWidgets('My Courses exit works in $state state', (tester) async {
      final progress = _Progress()..fail = state == 'error';
      final lessons = _Lessons();
      if (state == 'empty') lessons.sections = [];
      if (state == 'loading') {
        lessons.pending = Completer<List<CurriculumSection>>();
      }
      final container = _container(progress, lessons: lessons);
      addTearDown(container.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: CourseOverviewScreen(courseId: 'course')),
          ),
          GoRoute(
            path: '/dashboard/courses',
            builder: (_, _) => const Text('Library'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      if (state == 'loading') {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('My Courses'));
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsOneWidget);
      lessons.pending?.complete([]);
    });
  }

  testWidgets(
    'resume navigates to the exact course and saved unfinished lesson',
    (tester) async {
      final progress = _Progress()
        ..rows = [
          SavedLessonProgress(
            lessonId: 'b',
            completed: false,
            pdfPage: 8,
            lastOpenedAt: DateTime.utc(2026, 10, 27),
          ),
        ];
      final container = _container(progress);
      addTearDown(container.dispose);
      String? openedCourse;
      String? openedLesson;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: CourseOverviewScreen(courseId: 'course')),
          ),
          GoRoute(
            path: '/learn/:courseId/:lessonId',
            builder: (_, state) {
              openedCourse = state.pathParameters['courseId'];
              openedLesson = state.pathParameters['lessonId'];
              return const Text('Lesson destination');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Resume'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(openedCourse, 'course');
      expect(openedLesson, 'b');
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('overview layout $width dark=$dark text=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = _container(_Progress());
          addTearDown(container.dispose);
          await tester.pumpWidget(_app(container, dark: dark, scale: scale));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Up next'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('3 min'), findsOneWidget);
          expect(find.text('2 min'), findsOneWidget);
          final progress =
              container.read(learningProgressRepositoryProvider) as _Progress;
          progress.fail = true;
          container.invalidate(courseOverviewProvider('course'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Retry'), findsOneWidget);
        });
      }
    }
  }
  test('saved unfinished reading is started and resumes its exact lesson', () {
    final summary = CourseProgressSummary.from(_sections, {
      'b': SavedLessonProgress(
        lessonId: 'b',
        completed: false,
        pdfPage: 8,
        lastOpenedAt: DateTime.utc(2026, 10, 27),
      ),
    });
    expect(summary.hasStarted, isTrue);
    expect(summary.percent, 0);
    expect(summary.nextLesson?.id, 'b');
    expect(summary.sectionStatus('s'), SectionStatus.current);
  });

  testWidgets(
    'an unopened next lesson remains Up next after earlier completion',
    (tester) async {
      final progress = _Progress()
        ..rows = [const SavedLessonProgress(lessonId: 'a', completed: true)];
      final container = _container(progress);
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      expect(find.text('In Progress'), findsNothing);
      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('1 module · 2 lessons'), findsOneWidget);
    },
  );

  testWidgets('library card opens overview and saved progress reloads on return', (
    tester,
  ) async {
    final progress = _Progress()
      ..rows = [
        SavedLessonProgress(
          lessonId: 'b',
          completed: false,
          pdfPage: 8,
          lastOpenedAt: DateTime.utc(2026, 10, 27),
        ),
      ];
    final container = _container(progress);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/dashboard/courses',
      routes: [
        GoRoute(
          path: '/dashboard/courses',
          builder: (_, _) => const MyCoursesScreen(),
        ),
        GoRoute(
          path: '/learn/:courseId',
          builder: (_, state) => LearningShell(
            child: CourseOverviewScreen(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
        ),
        GoRoute(
          path: '/learn/:courseId/:lessonId',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                Text(
                  'Opened ${state.pathParameters['courseId']}/${state.pathParameters['lessonId']}',
                ),
                TextButton(
                  onPressed: () {
                    // Simulates the repository returning a newly persisted server record.
                    progress.rows = [
                      const SavedLessonProgress(lessonId: 'a', completed: true),
                    ];
                    context.go('/learn/course');
                  },
                  child: const Text('Return after saved progress'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter Fundamentals'));
    await tester.pumpAndSettle();
    expect(find.text('Your Learning Progress'), findsOneWidget);
    await tester.ensureVisible(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('Opened course/b'), findsOneWidget);
    await tester.tap(find.text('Return after saved progress'));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 of 2 lessons completed'), findsOneWidget);
    expect(progress.reads, 2);
  });

  testWidgets('overview identifies the course and fresh lesson honestly', (
    tester,
  ) async {
    final lessons = _Lessons();
    final container = _container(_Progress(), lessons: lessons);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Fundamentals'), findsOneWidget);
    expect(find.text('My Courses'), findsOneWidget);
    expect(find.text('In Progress'), findsNothing);
    expect(find.text('Up next'), findsOneWidget);
    expect(lessons.contentReads, 0);
  });

  testWidgets('progress failure offers retry and never fabricates zero', (
    tester,
  ) async {
    final progress = _Progress()..fail = true;
    final container = _container(progress);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.text('Could not load course content.'), findsOneWidget);
    expect(find.text('private database failure'), findsNothing);
    expect(find.text('0%'), findsNothing);
    expect(find.text('My Courses'), findsOneWidget);
    progress.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
  });
}
