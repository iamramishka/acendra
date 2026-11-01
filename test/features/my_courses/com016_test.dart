import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/presentation/screens/my_courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fakes/fake_my_courses_repository.dart';

const _progress = CourseProgress(
  courseId: 'course-1',
  totalLessons: 10,
  completedLessons: 3,
  nextLessonId: 'next-lesson',
);

class _Progress implements CourseProgressRepository {
  _Progress(this.load);
  Future<Map<String, CourseProgress>> Function() load;
  int calls = 0;
  @override
  Future<Map<String, CourseProgress>> summary() {
    calls++;
    return load();
  }
}

ProviderContainer _container(_Progress progress) => ProviderContainer(
  overrides: [
    myCoursesRepositoryProvider.overrideWithValue(
      FakeMyCoursesRepository(result: [fakeEnrolledCourse]),
    ),
    courseProgressRepositoryProvider.overrideWithValue(progress),
  ],
);

Widget _app(
  ProviderContainer container, {
  ThemeData? theme,
  double scale = 1,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: const bool.fromEnvironment('COM016_CAPTURE')
          ? Banner(
              message: 'SYNTHETIC',
              location: BannerLocation.topEnd,
              textStyle: const TextStyle(
                fontFamily: 'Inter_regular',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              child: child!,
            )
          : child!,
    ),
    home: const MyCoursesScreen(),
  ),
);

void main() {
  if (const bool.fromEnvironment('COM016_CAPTURE')) {
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
        final loader = FontLoader(name);
        loader.addFont(
          File(
            'build/com016-fonts/$name.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
        await loader.load();
      }
    });
    for (final dark in [false, true]) {
      for (final fail in [false, true]) {
        testWidgets('capture synthetic $dark $fail', (tester) async {
          tester.view.physicalSize = const Size(390, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = _container(
            _Progress(() async {
              if (fail) throw Exception('offline');
              return {'course-1': _progress};
            }),
          );
          addTearDown(container.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: _app(
                container,
                theme: dark ? AppTheme.dark : AppTheme.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/com016-evidence/synthetic-390-${dark ? 'dark' : 'light'}-${fail ? 'error' : 'progress'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        });
      }
    }
  }
  for (final action in ['card', 'button', 'keyboard']) {
    testWidgets('$action opens overview even with a resumable lesson', (
      tester,
    ) async {
      final container = _container(
        _Progress(() async => {'course-1': _progress}),
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const MyCoursesScreen()),
          GoRoute(
            path: '/learn/:courseId',
            builder: (_, _) => const Text('Overview'),
          ),
          GoRoute(
            path: '/learn/:courseId/:lessonId',
            builder: (_, _) => const Text('Lesson'),
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
      if (action == 'card') {
        await tester.tap(find.text('Flutter Fundamentals'));
      } else if (action == 'button') {
        await tester.tap(find.text('Continue Learning'));
      } else {
        Focus.of(tester.element(find.text('Continue Learning'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Lesson'), findsNothing);
    });
  }

  testWidgets('progress failure keeps courses and retries to real progress', (
    tester,
  ) async {
    final repo = _Progress(
      () async => throw Exception('private backend detail'),
    );
    final container = _container(repo);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Couldn't load your progress. You can still open your courses.",
      ),
      findsOneWidget,
    );
    expect(find.text('Flutter Fundamentals'), findsOneWidget);
    expect(find.text('Open Course'), findsOneWidget);
    expect(find.textContaining('private backend'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    repo.load = () async => {'course-1': _progress};
    await tester.tap(find.text('Retry progress'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.text('3 of 10 lessons completed • 30%'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Retry progress'), findsNothing);
  });

  testWidgets(
    'loading and missing progress never imply zero or empty library',
    (tester) async {
      final pending = Completer<Map<String, CourseProgress>>();
      final container = _container(_Progress(() => pending.future));
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pump();
      expect(find.text('Loading your progress…'), findsOneWidget);
      expect(find.text('Flutter Fundamentals'), findsOneWidget);
      pending.complete({});
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Progress unavailable for some courses. You can still open them.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open Course'), findsOneWidget);
      expect(find.textContaining('0%'), findsNothing);
    },
  );

  testWidgets('failed refresh in a filter falls back to all enrolled courses', (
    tester,
  ) async {
    final repo = _Progress(() async => {'course-1': _progress});
    final container = _container(repo);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pumpAndSettle();
    expect(find.text('No courses in this view.'), findsOneWidget);
    repo.load = () async => throw Exception('offline');
    container.invalidate(courseProgressProvider);
    await tester.pumpAndSettle();
    expect(find.text('Flutter Fundamentals'), findsOneWidget);
    expect(find.text('No courses in this view.'), findsNothing);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('layout $width dark=$dark text=$scale', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = _container(
            _Progress(() async => {'course-1': _progress}),
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            _app(
              container,
              theme: dark ? AppTheme.dark : AppTheme.light,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Your learning library'), findsOneWidget);
          expect(find.text('Continue Learning'), findsOneWidget);
          final repo =
              container.read(courseProgressRepositoryProvider) as _Progress;
          repo.load = () async => throw Exception('offline');
          container.invalidate(courseProgressProvider);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Retry progress'), findsOneWidget);
          expect(find.text('Flutter Fundamentals'), findsOneWidget);
        });
      }
    }
  }
}
