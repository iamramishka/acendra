// Exercises the real screens and notifier; only repository I/O is synthetic.
@TestOn('browser')
library;

import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/learning/presentation/screens/course_overview_screen.dart';
import 'package:acendra/features/learning/presentation/screens/learning_workspace_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _course = 'synthetic-course';
const _overview = '/learn/$_course';
const _sections = [
  CurriculumSection(
    id: 'one',
    title: 'First module',
    position: 1,
    lessons: [
      LessonItem(
        id: 'a',
        title: 'First lesson',
        lessonType: 'text',
        position: 1,
        isPreview: false,
      ),
      LessonItem(
        id: 'b',
        title: 'Second lesson',
        lessonType: 'text',
        position: 2,
        isPreview: false,
      ),
    ],
  ),
  CurriculumSection(
    id: 'two',
    title: 'Second module',
    position: 2,
    lessons: [
      LessonItem(
        id: 'c',
        title: 'Final lesson',
        lessonType: 'text',
        position: 1,
        isPreview: false,
      ),
    ],
  ),
];

class _Lessons implements LearningRepository {
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async {
    expect(courseId, _course);
    return _sections;
  }

  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) async =>
      courseId == _course && ['a', 'b', 'c'].contains(lessonId);

  @override
  Future<LessonContent> getLessonContent(String lessonId) async =>
      LessonContent(
        id: lessonId,
        title: 'Content $lessonId',
        lessonType: 'text',
        position: 1,
        sectionId: lessonId == 'c' ? 'two' : 'one',
        contentText: 'Synthetic body $lessonId',
      );
}

class _Courses implements MyCoursesRepository {
  @override
  Future<List<EnrolledCourse>> listEnrolled() async => const [
    EnrolledCourse(
      id: 'synthetic-enrollment',
      courseId: _course,
      title: 'Synthetic acceptance course',
      shortDescription: 'Test fixture',
      status: 'active',
      enrolledAt: '2026-11-01',
    ),
  ];
}

// Retained across client reconstruction, standing in for persisted RPC data.
// This is not evidence of hosted database durability or RLS enforcement.
class _SavedProgress implements LearningProgressRepository {
  final rows = <String, SavedLessonProgress>{};
  final writes = <String>[];
  int reads = 0;
  bool failRead = false;
  bool failSave = false;
  Completer<void>? saveGate;

  @override
  Future<List<SavedLessonProgress>> read(String courseId) async {
    expect(courseId, _course);
    reads++;
    if (failRead) throw StateError('private read detail');
    return rows.values.toList();
  }

  @override
  Future<SavedLessonProgress> saveCompletion(
    String lessonId,
    bool completed,
    SavedLessonProgress? previous,
  ) async {
    writes.add(lessonId);
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('private save detail');
    final saved = SavedLessonProgress(
      lessonId: lessonId,
      completed: completed,
      pdfPage: previous?.pdfPage,
      pdfPosition: previous?.pdfPosition,
      videoSeconds: previous?.videoSeconds,
      lastOpenedAt: DateTime.utc(2026, 11, 1),
    );
    rows[lessonId] = saved;
    return saved;
  }

  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String lessonId,
    int videoSeconds,
    SavedLessonProgress? previous,
  ) => throw StateError('Text journey must not save video');
}

class _App {
  _App(
    _SavedProgress progress, {
    String location = _overview,
    bool dark = false,
  }) {
    container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWithValue(
          Session(
            accessToken: 'synthetic',
            tokenType: 'bearer',
            user: const User(
              id: 'synthetic-student',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-11-01T00:00:00Z',
            ),
          ),
        ),
        learningRepositoryProvider.overrideWithValue(_Lessons()),
        learningProgressRepositoryProvider.overrideWithValue(progress),
        myCoursesRepositoryProvider.overrideWithValue(_Courses()),
      ],
    );
    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/learn/:courseId',
          builder: (_, state) => Scaffold(
            body: CourseOverviewScreen(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
        ),
        GoRoute(
          path: '/learn/:courseId/:lessonId',
          builder: (_, state) => Scaffold(
            body: LearningWorkspaceScreen(
              courseId: state.pathParameters['courseId']!,
              initialLessonId: state.pathParameters['lessonId'],
            ),
          ),
        ),
      ],
    );
    widget = UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        routerConfig: router,
      ),
    );
  }

  late final ProviderContainer container;
  late final GoRouter router;
  late final Widget widget;
  String get path => router.routeInformationProvider.value.uri.path;
  void dispose() {
    router.dispose();
    container.dispose();
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'save, advance, complete and reconstruct at $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final progress = _SavedProgress();
          var app = _App(progress, dark: dark);
          addTearDown(() => app.dispose());
          await tester.pumpWidget(app.widget);
          await tester.pumpAndSettle();
          expect(find.text('0%'), findsOneWidget);
          expect(progress.writes, isEmpty);
          await _tap(tester, 'Start Lesson');
          expect(app.path, '$_overview/a');
          expect(find.text('Synthetic body a'), findsOneWidget);
          await _tap(tester, 'Mark Complete & Continue');
          expect(progress.rows['a']?.completed, isTrue);
          expect(app.path, '$_overview/b');
          expect(find.text('Synthetic body b'), findsOneWidget);

          // Discard all providers/router/widgets, retaining only saved I/O data.
          final path = app.path;
          final readsBefore = progress.reads;
          await tester.pumpWidget(const SizedBox.shrink());
          app.dispose();
          app = _App(progress, location: path, dark: dark);
          await tester.pumpWidget(app.widget);
          await tester.pumpAndSettle();
          expect(progress.reads, greaterThan(readsBefore));
          expect(app.path, '$_overview/b');
          expect(find.text('Synthetic body b'), findsOneWidget);
          expect(
            app.container
                .read(learningWorkspaceProvider(_course))
                .progress['a']
                ?.completed,
            isTrue,
          );

          // Completing a module returns to overview; Resume selects next module.
          await _tap(tester, 'Mark Complete & Continue');
          expect(app.path, _overview);
          expect(find.text('67%'), findsOneWidget);
          expect(find.text('2 of 3 lessons completed'), findsOneWidget);
          expect(find.text('Completed'), findsOneWidget);
          expect(find.text('Module finished'), findsOneWidget);
          // Resume immediately while the completion notice is still visible.
          await _tap(tester, 'Resume');
          expect(app.path, '$_overview/c');
          expect(find.text('Module finished'), findsNothing);
          await _tap(tester, 'Mark Complete');
          expect(app.path, _overview);
          expect(find.text('100%'), findsOneWidget);
          expect(find.text('Course completed'), findsOneWidget);
          expect(find.text('Resume'), findsNothing);
          expect(progress.writes, ['a', 'b', 'c']);

          await tester.pumpWidget(const SizedBox.shrink());
          app.dispose();
          app = _App(progress, dark: dark);
          await tester.pumpWidget(app.widget);
          await tester.pumpAndSettle();
          expect(find.text('100%'), findsOneWidget);
          expect(find.text('3 of 3 lessons completed'), findsOneWidget);
          expect(find.text('Completed'), findsNWidgets(2));
          expect(progress.writes, ['a', 'b', 'c']);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Resume opens the exact saved unfinished lesson without writing',
    (tester) async {
      final progress = _SavedProgress();
      progress.rows['b'] = SavedLessonProgress(
        lessonId: 'b',
        completed: false,
        lastOpenedAt: DateTime.utc(2026, 11, 1),
        videoSeconds: 45,
      );
      final app = _App(progress);
      addTearDown(app.dispose);
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      await _tap(tester, 'Resume');
      expect(app.path, '$_overview/b');
      expect(find.text('Synthetic body b'), findsOneWidget);
      expect(progress.writes, isEmpty);
    },
  );

  testWidgets('pending save cannot advance or submit duplicate completion', (
    tester,
  ) async {
    final progress = _SavedProgress()..saveGate = Completer<void>();
    final app = _App(progress, location: '$_overview/a');
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Complete & Continue'));
    await tester.pump();
    expect(app.path, '$_overview/a');
    expect(progress.rows, isEmpty);
    await app.container
        .read(learningWorkspaceProvider(_course).notifier)
        .completeAndContinue();
    expect(progress.writes, ['a']);
    progress.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(app.path, '$_overview/b');
    expect(progress.rows['a']?.completed, isTrue);
  });

  testWidgets('failed save stays on lesson and explicit reload allows retry', (
    tester,
  ) async {
    final progress = _SavedProgress()..failSave = true;
    final app = _App(progress, location: '$_overview/a');
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await _tap(tester, 'Mark Complete & Continue');
    expect(app.path, '$_overview/a');
    expect(progress.rows, isEmpty);
    expect(
      find.text('Could not save progress. Retry to reload it.'),
      findsOneWidget,
    );
    expect(find.textContaining('private save'), findsNothing);
    progress.failSave = false;
    await _tap(tester, 'Reload progress');
    await _tap(tester, 'Mark Complete & Continue');
    expect(app.path, '$_overview/b');
    expect(progress.rows['a']?.completed, isTrue);
  });

  testWidgets(
    'failed progress read offers retry instead of false zero progress',
    (tester) async {
      final progress = _SavedProgress()..failRead = true;
      progress.rows['a'] = const SavedLessonProgress(
        lessonId: 'a',
        completed: true,
      );
      final app = _App(progress);
      addTearDown(app.dispose);
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      expect(find.text('Could not load course content.'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
      expect(find.text('Resume'), findsNothing);
      expect(find.textContaining('private read'), findsNothing);
      progress.failRead = false;
      await _tap(tester, 'Retry');
      expect(find.text('33%'), findsOneWidget);
      await _tap(tester, 'Resume');
      expect(app.path, '$_overview/b');
      expect(progress.writes, isEmpty);
    },
  );
}
