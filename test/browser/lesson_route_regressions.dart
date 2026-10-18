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
  ) => throw UnimplementedError();

  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String lessonId,
    int videoSeconds,
    SavedLessonProgress? previous,
  ) => throw UnimplementedError();
}

void registerLessonRouteRegressionTests() {
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
    },
  );
}
