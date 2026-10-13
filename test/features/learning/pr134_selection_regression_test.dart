import 'dart:async';

import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedRepository implements LearningRepository {
  final requests = <String, Completer<LessonContent>>{};
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async => [];
  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) async =>
      false;
  @override
  Future<LessonContent> getLessonContent(String lessonId) =>
      (requests[lessonId] = Completer<LessonContent>()).future;
}

LessonContent _content(String id) => LessonContent(
  id: id,
  title: id,
  lessonType: 'text',
  position: 0,
  sectionId: 'section',
  contentText: id,
);

void main() {
  for (final staleFailure in [false, true]) {
    test(
      'ignores stale ${staleFailure ? 'failure' : 'content'} after newer selection',
      () async {
        final repo = _DelayedRepository();
        final container = ProviderContainer(
          overrides: [learningRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        final provider = learningWorkspaceProvider('course');
        container.listen(provider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        final notifier = container.read(provider.notifier);
        final older = notifier.selectLesson('A');
        final newer = notifier.selectLesson('B');
        repo.requests['B']!.complete(_content('B'));
        await newer;
        if (staleFailure) {
          repo.requests['A']!.completeError(StateError('older failure'));
        } else {
          repo.requests['A']!.complete(_content('A'));
        }
        await older;
        expect(container.read(provider).currentLessonId, 'B');
        expect(container.read(provider).currentContent?.id, 'B');
        expect(container.read(provider).error, isNull);
      },
    );
  }
}
