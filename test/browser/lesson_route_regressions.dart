import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/learning/presentation/screens/learning_workspace_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Lessons implements LearningRepository {
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async => [
    const CurriculumSection(
      id: 'section',
      title: 'Synthetic section',
      position: 0,
      lessons: [
        LessonItem(
          id: 'first',
          title: 'First lesson',
          lessonType: 'text',
          position: 0,
          isPreview: false,
        ),
        LessonItem(
          id: 'second',
          title: 'Second lesson',
          lessonType: 'text',
          position: 1,
          isPreview: false,
        ),
      ],
    ),
  ];

  @override
  Future<LessonContent> getLessonContent(String lessonId) async =>
      LessonContent(
        id: lessonId,
        title: lessonId,
        lessonType: 'text',
        position: 0,
        sectionId: 'section',
        contentText: 'Synthetic $lessonId content',
      );

  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) async =>
      true;
}

class _Progress implements LearningProgressRepository {
  @override
  Future<List<SavedLessonProgress>> read(String courseId) async => [];

  @override
  Future<SavedLessonProgress> saveCompletion(
    String lessonId,
    bool completed,
    SavedLessonProgress? previous,
  ) async => SavedLessonProgress(lessonId: lessonId, completed: completed);

  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String lessonId,
    int videoSeconds,
    SavedLessonProgress? previous,
  ) => throw UnimplementedError();
}

void registerLessonRouteRegressionTests() {
  Future<GoRouter> mountRoutes(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/learn/course/first',
      routes: [
        GoRoute(
          path: '/learn/:courseId',
          builder: (_, _) => const Scaffold(body: Text('Course overview')),
        ),
        GoRoute(
          path: '/learn/:courseId/:lessonId',
          builder: (_, state) => Scaffold(
            body: LearningWorkspaceScreen(
              key: ValueKey(state.pathParameters['lessonId']),
              courseId: state.pathParameters['courseId']!,
              initialLessonId: state.pathParameters['lessonId'],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(null),
          learningRepositoryProvider.overrideWithValue(_RouteLessons()),
          learningProgressRepositoryProvider.overrideWithValue(_Progress()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'sidebar updates URL and restored history entries select their lesson',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = await mountRoutes(tester);
      await tester.tap(find.text('Second lesson'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/course/second',
      );
      expect(find.text('Synthetic second content'), findsOneWidget);
      // Browser Back/Forward deliver route information to this provider.
      await router.routeInformationProvider.didPushRouteInformation(
        RouteInformation(uri: Uri.parse('/learn/course/first')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic first content'), findsOneWidget);
      await router.routeInformationProvider.didPushRouteInformation(
        RouteInformation(uri: Uri.parse('/learn/course/second')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic second content'), findsOneWidget);
    },
  );

  testWidgets(
    'completion and previous/next keep lesson URLs and completion exits',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = await mountRoutes(tester);
      await tester.tap(find.text('Mark Complete & Continue'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/course/second',
      );
      expect(find.text('Synthetic second content'), findsOneWidget);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/course/first',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/course/second',
      );
      await tester.tap(find.text('Mark Complete & Continue'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/learn/course');
      expect(find.text('Course overview'), findsOneWidget);
      // The "Module finished" snackbar floats over the bottom-right button.
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).hideCurrentSnackBar();
      router.go('/learn/course/third');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/learn/course');
      expect(find.text('Course overview'), findsOneWidget);
    },
  );

  testWidgets(
    'mobile curriculum selection closes the drawer and updates the URL',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = await mountRoutes(tester);
      final mountError = tester.takeException();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second lesson'));
      await tester.pumpAndSettle();
      final actionError = tester.takeException();
      // Temporary diagnostic: CI only forwards print output.
      // ignore: avoid_print
      print(
        'DIAG mobile drawer: mount=$mountError action=$actionError '
        'path=${router.routeInformationProvider.value.uri.path} '
        'second=${find.text('Synthetic second content').evaluate().length} '
        'sheets=${find.byType(BottomSheet).evaluate().length} '
        'timers=${tester.binding.transientCallbackCount}',
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/course/second',
      );
      expect(find.text('Synthetic second content'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      // ignore: avoid_print
      print('DIAG mobile drawer: body finished');
    },
  );

  testWidgets(
    'opening a lesson route reuses loaded progress without changing state during build',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWithValue(null),
          learningRepositoryProvider.overrideWithValue(_Lessons()),
          learningProgressRepositoryProvider.overrideWithValue(_Progress()),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(
        learningWorkspaceProvider('course'),
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      // The constructor already schedules loading. Flush that work rather
      // than racing it with a second load that invalidates its request token.
      await tester.pump();
      expect(
        container.read(learningWorkspaceProvider('course')).currentLessonId,
        'first',
        reason: 'The retained workspace must be loaded before mounting it.',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: LearningWorkspaceScreen(
                courseId: 'course',
                initialLessonId: 'second',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        container.read(learningWorkspaceProvider('course')).currentLessonId,
        'second',
      );
      expect(find.text('Synthetic second content'), findsOneWidget);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic first content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RouteLessons extends _Lessons {
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async => [
    ...await super.getCurriculumWithLessons(courseId),
    const CurriculumSection(
      id: 'final-section',
      title: 'Final module',
      position: 1,
      lessons: [
        LessonItem(
          id: 'third',
          title: 'Third lesson',
          lessonType: 'text',
          position: 0,
          isPreview: false,
        ),
      ],
    ),
  ];
}
