import 'dart:async';

import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedRepository implements LearningRepository {
  final enrollmentRequests = <String, Completer<bool>>{};
  final contentRequests = <String, Completer<LessonContent>>{};

  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async => [];

  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) =>
      (enrollmentRequests[lessonId] = Completer<bool>()).future;

  @override
  Future<LessonContent> getLessonContent(String lessonId) =>
      (contentRequests[lessonId] = Completer<LessonContent>()).future;
}

LessonContent _content(String id) => LessonContent(
  id: id,
  title: id,
  lessonType: 'text',
  position: 0,
  sectionId: 'section',
  contentText: id,
);

ProviderContainer _makeContainer(_DelayedRepository repo) {
  final container = ProviderContainer(
    overrides: [learningRepositoryProvider.overrideWithValue(repo)],
  );
  container.listen(learningWorkspaceProvider('course'), (_, _) {});
  return container;
}

void main() {
  // Stale check at the isEnrolledOrPreview phase:
  // A starts, B starts before A's enrollment resolves → A is cancelled
  // before getLessonContent is ever called for A.
  test('ignores stale request cancelled at enrollment check', () async {
    final repo = _DelayedRepository();
    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(
      learningWorkspaceProvider('course').notifier,
    );
    final aFuture = notifier.selectLesson('A');
    final bFuture = notifier.selectLesson('B');

    // Complete both enrollment checks. B's requestId is higher than A's so A
    // will be abandoned before calling getLessonContent.
    repo.enrollmentRequests['A']!.complete(true);
    repo.enrollmentRequests['B']!.complete(true);
    await Future<void>.delayed(Duration.zero);

    // Only B should have proceeded to getLessonContent.
    expect(repo.contentRequests.containsKey('A'), isFalse);
    repo.contentRequests['B']!.complete(_content('B'));
    await bFuture;
    await aFuture;

    final state = container.read(learningWorkspaceProvider('course'));
    expect(state.currentLessonId, 'B');
    expect(state.currentContent?.id, 'B');
    expect(state.error, isNull);
  });

  // Stale check at the getLessonContent phase:
  // A passes enrollment, B is selected while A is awaiting getLessonContent.
  // A's content arriving late must not overwrite B's state.
  for (final staleFailure in [false, true]) {
    test(
      'ignores stale ${staleFailure ? 'failure' : 'content'} at getLessonContent phase',
      () async {
        final repo = _DelayedRepository();
        final container = _makeContainer(repo);
        addTearDown(container.dispose);
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(
          learningWorkspaceProvider('course').notifier,
        );

        // A starts and passes its enrollment check.
        final aFuture = notifier.selectLesson('A');
        repo.enrollmentRequests['A']!.complete(true);
        await Future<void>.delayed(Duration.zero);
        // A is now awaiting getLessonContent — contentRequests['A'] is populated.
        expect(repo.contentRequests.containsKey('A'), isTrue);

        // B is selected while A is still loading content.
        final bFuture = notifier.selectLesson('B');
        repo.enrollmentRequests['B']!.complete(true);
        await Future<void>.delayed(Duration.zero);
        // B also reached getLessonContent.
        expect(repo.contentRequests.containsKey('B'), isTrue);

        // B completes first.
        repo.contentRequests['B']!.complete(_content('B'));
        await bFuture;

        // A resolves stale — as content or as a failure.
        if (staleFailure) {
          repo.contentRequests['A']!.completeError(StateError('stale failure'));
        } else {
          repo.contentRequests['A']!.complete(_content('A'));
        }
        await aFuture;

        final state = container.read(learningWorkspaceProvider('course'));
        expect(state.currentLessonId, 'B');
        expect(state.currentContent?.id, 'B');
        expect(state.error, isNull);
      },
    );
  }
}
