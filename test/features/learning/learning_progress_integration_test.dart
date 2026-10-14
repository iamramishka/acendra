import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Lessons implements LearningRepository {
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(String id) async => [
    const CurriculumSection(
      id: 'section',
      title: 'Section',
      position: 0,
      lessons: [
        LessonItem(
          id: 'first',
          title: 'First',
          lessonType: 'pdf',
          position: 0,
          isPreview: false,
        ),
        LessonItem(
          id: 'second',
          title: 'Second',
          lessonType: 'pdf',
          position: 1,
          isPreview: false,
        ),
      ],
    ),
  ];
  @override
  Future<LessonContent> getLessonContent(String id) async => LessonContent(
    id: id,
    title: id,
    lessonType: 'pdf',
    position: 0,
    sectionId: 'section',
  );
  @override
  Future<bool> isEnrolledOrPreview(String course, String lesson) async => false;
}

class _Progress implements LearningProgressRepository {
  bool failRead = false;
  bool failSave = false;
  int writes = 0;
  SavedLessonProgress? previous;
  @override
  Future<List<SavedLessonProgress>> read(String course) async {
    if (failRead) throw StateError('private database detail');
    return [
      SavedLessonProgress(
        lessonId: 'second',
        completed: false,
        pdfPage: 8,
        pdfPosition: 0.5,
        lastOpenedAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<SavedLessonProgress> saveCompletion(
    String lesson,
    bool completed,
    SavedLessonProgress? snapshot,
  ) async {
    writes++;
    previous = snapshot;
    if (failSave) throw StateError('private database detail');
    return SavedLessonProgress(
      lessonId: lesson,
      completed: completed,
      pdfPage: snapshot?.pdfPage,
      pdfPosition: snapshot?.pdfPosition,
    );
  }
}

void main() {
  Future<ProviderContainer> setup(_Progress progress) async {
    final container = ProviderContainer(
      overrides: [
        learningRepositoryProvider.overrideWithValue(_Lessons()),
        learningProgressRepositoryProvider.overrideWithValue(progress),
      ],
    );
    addTearDown(container.dispose);
    container.listen(learningWorkspaceProvider('course'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test(
    'restores lesson and completion preserves saved PDF resume snapshot',
    () async {
      final progress = _Progress();
      final container = await setup(progress);
      final provider = learningWorkspaceProvider('course');
      expect(container.read(provider).currentLessonId, 'second');
      await container.read(provider.notifier).setCompleted(true);
      expect(progress.previous?.pdfPage, 8);
      expect(progress.previous?.pdfPosition, 0.5);
      expect(container.read(provider).progress['second']?.completed, isTrue);
    },
  );

  test('failed read blocks writes and hides backend details', () async {
    final progress = _Progress()..failRead = true;
    final container = await setup(progress);
    final provider = learningWorkspaceProvider('course');
    await container.read(provider.notifier).setCompleted(true);
    expect(progress.writes, 0);
    expect(container.read(provider).progressError, isNot(contains('private')));
  });

  test(
    'failed save retains prior completion and supports explicit reload',
    () async {
      final progress = _Progress()..failSave = true;
      final container = await setup(progress);
      final provider = learningWorkspaceProvider('course');
      await container.read(provider.notifier).setCompleted(true);
      expect(container.read(provider).progress['second']?.completed, isFalse);
      expect(container.read(provider).isSavingProgress, isFalse);
      expect(
        container.read(provider).progressError,
        isNot(contains('private')),
      );
      progress.failSave = false;
      await container.read(provider.notifier).loadCourse('course');
      await container.read(provider.notifier).setCompleted(true);
      expect(container.read(provider).progress['second']?.completed, isTrue);
    },
  );
}
