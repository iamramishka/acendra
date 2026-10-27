@TestOn('browser')
library;

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/learning/presentation/screens/learning_workspace_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/protected_pdf_lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _sections = [
  CurriculumSection(
    id: 'module',
    title: 'Synthetic module',
    position: 0,
    lessons: [
      LessonItem(
        id: 'video',
        title: 'Synthetic video',
        lessonType: 'video',
        position: 0,
        isPreview: false,
      ),
      LessonItem(
        id: 'pdf',
        title: 'Synthetic PDF',
        lessonType: 'pdf',
        position: 1,
        isPreview: false,
      ),
    ],
  ),
];

class _Lessons implements LearningRepository {
  final allowed = <String>[];
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(String id) async =>
      _sections;
  @override
  Future<bool> isEnrolledOrPreview(String course, String lesson) async {
    allowed.add(lesson);
    return true;
  }

  @override
  Future<LessonContent> getLessonContent(String id) async => LessonContent(
    id: id,
    title: id,
    lessonType: id == 'video' ? 'video' : 'pdf',
    position: 0,
    sectionId: 'module',
  );
}

class _Progress implements LearningProgressRepository {
  bool failSave = false;
  int writes = 0;
  @override
  Future<List<SavedLessonProgress>> read(String id) async => [];
  @override
  Future<SavedLessonProgress> saveCompletion(
    String id,
    bool complete,
    SavedLessonProgress? prior,
  ) async {
    writes++;
    if (failSave) throw StateError('private backend detail');
    return SavedLessonProgress(lessonId: id, completed: complete);
  }

  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String id,
    int seconds,
    SavedLessonProgress? prior,
  ) async => SavedLessonProgress(
    lessonId: id,
    completed: prior?.completed ?? false,
    videoSeconds: seconds,
  );
}

void main() {
  Future<(GoRouter, ProviderContainer, _Lessons)> mount(
    WidgetTester tester,
    _Progress progress,
  ) async {
    final lessons = _Lessons();
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWithValue(null),
        learningRepositoryProvider.overrideWithValue(lessons),
        learningProgressRepositoryProvider.overrideWithValue(progress),
      ],
    );
    final router = GoRouter(
      initialLocation: '/learn/course/video',
      routes: [
        GoRoute(
          path: '/learn/:course/:lesson',
          builder: (_, state) => Scaffold(
            body: LearningWorkspaceScreen(
              courseId: state.pathParameters['course']!,
              initialLessonId: state.pathParameters['lesson'],
            ),
          ),
        ),
        GoRoute(
          path: '/learn/:course',
          builder: (_, _) => const Scaffold(body: Text('Course overview')),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (router, container, lessons);
  }

  testWidgets(
    'same-module PDF opens its protected reader route and rechecks lesson access',
    (tester) async {
      final (router, _, lessons) = await mount(tester, _Progress());
      await tester.tap(find.text('Resources'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Synthetic PDF').last);
      await tester.tap(find.text('Synthetic PDF').last);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/course/pdf',
      );
      expect(lessons.allowed, contains('pdf'));
      expect(find.byType(ProtectedPdfLesson), findsOneWidget);
    },
  );
  testWidgets(
    'mobile curriculum button leaves completion action unobstructed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, _Progress());
      final curriculum = tester.getRect(find.byType(FloatingActionButton));
      final complete = tester.getRect(
        find.widgetWithText(FilledButton, 'Mark Complete & Continue'),
      );
      expect(curriculum.overlaps(complete), isFalse);
    },
  );
  for (final fail in [false, true]) {
    testWidgets(
      'video complete-and-continue saves before navigation, failure=$fail',
      (tester) async {
        final progress = _Progress()..failSave = fail;
        final (router, container, _) = await mount(tester, progress);
        await tester.tap(find.text('Mark Complete & Continue'));
        await tester.pumpAndSettle();
        expect(progress.writes, 1);
        expect(
          router.routeInformationProvider.value.uri.path,
          fail ? '/learn/course/video' : '/learn/course/pdf',
        );
        final state = container.read(learningWorkspaceProvider('course'));
        expect(state.progress['video']?.completed ?? false, !fail);
        if (fail) {
          expect(
            find.text('Could not save progress. Retry to reload it.'),
            findsOneWidget,
          );
          expect(find.textContaining('private backend'), findsNothing);
        }
      },
    );
  }
}
