import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _sections = [
  CurriculumSection(
    id: 'section',
    title: 'Synthetic section',
    position: 0,
    lessons: [
      LessonItem(
        id: 'first',
        title: 'First',
        lessonType: 'text',
        position: 0,
        isPreview: false,
      ),
      LessonItem(
        id: 'second',
        title: 'Second',
        lessonType: 'text',
        position: 1,
        isPreview: false,
      ),
      LessonItem(
        id: 'third',
        title: 'Third',
        lessonType: 'text',
        position: 2,
        isPreview: false,
      ),
    ],
  ),
];

class _Lessons implements LearningRepository {
  final curriculum = Completer<List<CurriculumSection>>();
  final opened = <String>[];
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(String courseId) =>
      curriculum.future;
  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) async =>
      true;
  @override
  Future<LessonContent> getLessonContent(String lessonId) async {
    opened.add(lessonId);
    return LessonContent(
      id: lessonId,
      title: lessonId,
      lessonType: 'text',
      position: 0,
      sectionId: 'section',
      contentText: lessonId,
    );
  }
}

class _Progress implements LearningProgressRepository {
  final readStarted = Completer<void>();
  final result = Completer<List<SavedLessonProgress>>();
  SavedLessonProgress? previous;
  @override
  Future<List<SavedLessonProgress>> read(String courseId) {
    readStarted.complete();
    return result.future;
  }

  @override
  Future<SavedLessonProgress> saveCompletion(
    String lessonId,
    bool completed,
    SavedLessonProgress? snapshot,
  ) async {
    previous = snapshot;
    return SavedLessonProgress(
      lessonId: lessonId,
      completed: completed,
      videoSeconds: snapshot?.videoSeconds,
    );
  }

  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String lessonId,
    int videoSeconds,
    SavedLessonProgress? previous,
  ) => throw UnimplementedError();
}

void main() {
  for (final lateRequest in [false, true]) {
    test(
      'URL request ${lateRequest ? 'during progress read' : 'before curriculum'} preserves loaded progress and requested lesson',
      () async {
        final lessons = _Lessons();
        final progress = _Progress();
        final container = ProviderContainer(
          overrides: [
            currentSessionProvider.overrideWithValue(null),
            learningRepositoryProvider.overrideWithValue(lessons),
            learningProgressRepositoryProvider.overrideWithValue(progress),
          ],
        );
        addTearDown(container.dispose);
        final provider = learningWorkspaceProvider('course');
        container.listen(provider, (_, _) {});
        final notifier = container.read(provider.notifier);
        if (!lateRequest) await notifier.requestLesson('second');
        lessons.curriculum.complete(_sections);
        await progress.readStarted.future;
        if (lateRequest) await notifier.requestLesson('second');
        progress.result.complete([
          SavedLessonProgress(
            lessonId: 'first',
            completed: true,
            lastOpenedAt: DateTime(2026),
          ),
          const SavedLessonProgress(
            lessonId: 'second',
            completed: false,
            videoSeconds: 42,
          ),
        ]);
        await Future<void>.delayed(Duration.zero);
        final state = container.read(provider);
        expect(state.progressReady, isTrue);
        expect(state.progressError, isNull);
        expect(state.currentLessonId, 'second');
        expect(state.currentContent?.id, 'second');
        expect(state.progress['first']?.completed, isTrue);
        await notifier.setCompleted(true);
        expect(progress.previous?.videoSeconds, 42);
        expect(container.read(provider).progress['second']?.completed, isTrue);
      },
    );
  }

  test(
    'latest URL request during progress read wins over earlier URL and saved resume',
    () async {
      final lessons = _Lessons();
      final progress = _Progress();
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWithValue(null),
          learningRepositoryProvider.overrideWithValue(lessons),
          learningProgressRepositoryProvider.overrideWithValue(progress),
        ],
      );
      addTearDown(container.dispose);
      final provider = learningWorkspaceProvider('course');
      container.listen(provider, (_, _) {});
      final notifier = container.read(provider.notifier);
      await notifier.requestLesson('first');
      lessons.curriculum.complete(_sections);
      await progress.readStarted.future;
      await notifier.requestLesson('second');
      await notifier.requestLesson('third');
      progress.result.complete([
        SavedLessonProgress(
          lessonId: 'first',
          completed: false,
          lastOpenedAt: DateTime(2026),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider).progressReady, isTrue);
      expect(container.read(provider).currentLessonId, 'third');
      expect(container.read(provider).currentContent?.id, 'third');
      expect(lessons.opened, ['third']);
    },
  );
}
