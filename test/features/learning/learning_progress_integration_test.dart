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
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Completer<List<SavedLessonProgress>>? pendingRead;
  bool failRead = false;
  bool failSave = false;
  int writes = 0;
  SavedLessonProgress? previous;
  @override
  Future<List<SavedLessonProgress>> read(String course) async {
    if (pendingRead != null) return pendingRead!.future;
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
  test('does not save while progress read is pending', () async {
    final progress = _Progress()
      ..pendingRead = Completer<List<SavedLessonProgress>>();
    final container = ProviderContainer(
      overrides: [
        learningRepositoryProvider.overrideWithValue(_Lessons()),
        learningProgressRepositoryProvider.overrideWithValue(progress),
        currentSessionProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    final provider = learningWorkspaceProvider('course');
    container.listen(provider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await container.read(provider.notifier).selectLesson('first');
    await container.read(provider.notifier).setCompleted(true);
    expect(progress.writes, 0);
    expect(container.read(provider).progressReady, isFalse);
    progress.pendingRead!.complete([]);
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'account change recreates workspace without prior saved snapshots',
    () async {
      final events = StreamController<AuthState>.broadcast();
      final progress = _Progress();
      final container = ProviderContainer(
        overrides: [
          learningRepositoryProvider.overrideWithValue(_Lessons()),
          learningProgressRepositoryProvider.overrideWithValue(progress),
          authStreamProvider.overrideWith((ref) => events.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await events.close();
      });
      final provider = learningWorkspaceProvider('course');
      container.listen(provider, (_, _) {});
      Session session(String id) => Session(
        accessToken: 'synthetic-$id',
        tokenType: 'bearer',
        user: User(
          id: id,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-14T00:00:00Z',
        ),
      );
      events.add(AuthState(AuthChangeEvent.signedIn, session('A')));
      await Future<void>.delayed(Duration.zero);
      final previousNotifier = container.read(provider.notifier);
      expect(container.read(provider).progress['second'], isNotNull);
      progress.pendingRead = Completer<List<SavedLessonProgress>>();
      events.add(AuthState(AuthChangeEvent.signedIn, session('B')));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider.notifier), isNot(same(previousNotifier)));
      expect(container.read(provider).progress, isEmpty);
      await previousNotifier.setCompleted(true);
      expect(progress.writes, 0);
      progress.pendingRead!.complete([]);
      await Future<void>.delayed(Duration.zero);
    },
  );

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
