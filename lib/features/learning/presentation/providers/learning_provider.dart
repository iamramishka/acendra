import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

@immutable
class LearningState {
  const LearningState({
    required this.courseId,
    this.sections = const [],
    this.currentLessonId,
    this.currentContent,
    this.isLoading = false,
    this.error,
    this.progress = const {},
    this.progressError,
    this.isSavingProgress = false,
    this.progressReady = false,
  });

  final String courseId;
  final List<CurriculumSection> sections;
  final String? currentLessonId;
  final LessonContent? currentContent;
  final bool isLoading;
  final String? error;
  final Map<String, SavedLessonProgress> progress;
  final String? progressError;
  final bool isSavingProgress;
  final bool progressReady;

  LearningState copyWith({
    List<CurriculumSection>? sections,
    String? currentLessonId,
    LessonContent? currentContent,
    bool? isLoading,
    String? error,
    bool clearContent = false,
    bool clearError = false,
    Map<String, SavedLessonProgress>? progress,
    String? progressError,
    bool clearProgressError = false,
    bool? isSavingProgress,
    bool? progressReady,
  }) {
    return LearningState(
      courseId: courseId,
      sections: sections ?? this.sections,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      currentContent: clearContent
          ? null
          : (currentContent ?? this.currentContent),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      progress: progress ?? this.progress,
      progressError: clearProgressError
          ? null
          : (progressError ?? this.progressError),
      isSavingProgress: isSavingProgress ?? this.isSavingProgress,
      progressReady: progressReady ?? this.progressReady,
    );
  }

  /// Flat ordered list of all lessons across sections.
  List<LessonItem> get flatLessons {
    final result = <LessonItem>[];
    for (final section in sections) {
      result.addAll(section.lessons);
    }
    return result;
  }
}

class LearningNotifier extends StateNotifier<LearningState> {
  LearningNotifier(String courseId, this._ref)
    : super(LearningState(courseId: courseId, isLoading: true)) {
    Future.microtask(() => loadCourse(courseId));
  }

  final Ref _ref;
  int _requestId = 0;

  Future<void> loadCourse(String courseId) async {
    if (!mounted || state.isSavingProgress) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      progressReady: false,
    );
    try {
      final repo = _ref.read(learningRepositoryProvider);
      final sections = await repo.getCurriculumWithLessons(courseId);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(sections: sections, isLoading: false);

      final flat = state.flatLessons;
      if (flat.isNotEmpty) {
        String selected = flat.first.id;
        try {
          final saved = await _ref
              .read(learningProgressRepositoryProvider)
              .read(courseId);
          if (!mounted || requestId != _requestId) return;
          final valid =
              saved
                  .where(
                    (entry) =>
                        flat.any((lesson) => lesson.id == entry.lessonId),
                  )
                  .toList()
                ..sort(
                  (a, b) => (b.lastOpenedAt ?? DateTime(1970)).compareTo(
                    a.lastOpenedAt ?? DateTime(1970),
                  ),
                );
          state = state.copyWith(
            progress: {for (final entry in valid) entry.lessonId: entry},
            clearProgressError: true,
            progressReady: true,
          );
          if (valid.isNotEmpty) selected = valid.first.lessonId;
        } catch (_) {
          if (!mounted || requestId != _requestId) return;
          state = state.copyWith(
            progressError: 'Saved progress is unavailable. Retry to load it.',
          );
        }
        await selectLesson(selected);
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setCompleted(bool completed) async {
    if (!mounted) return;
    final lessonId = state.currentLessonId;
    if (lessonId == null || state.isSavingProgress) return;
    // Do not overwrite unknown resume data after a failed progress read.
    if (!state.progressReady || state.progressError != null) return;
    state = state.copyWith(isSavingProgress: true);
    try {
      final saved = await _ref
          .read(learningProgressRepositoryProvider)
          .saveCompletion(lessonId, completed, state.progress[lessonId]);
      if (!mounted) return;
      if (saved.lessonId != lessonId) throw StateError('Progress mismatch');
      state = state.copyWith(
        progress: {...state.progress, lessonId: saved},
        isSavingProgress: false,
        clearProgressError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSavingProgress: false,
        progressError: 'Could not save progress. Retry to reload it.',
      );
    }
  }

  Future<void> selectLesson(String lessonId) async {
    if (!mounted) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      currentLessonId: lessonId,
      isLoading: true,
      clearContent: true,
      clearError: true,
    );
    try {
      final repo = _ref.read(learningRepositoryProvider);
      final content = await repo.getLessonContent(lessonId);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(currentContent: content, isLoading: false);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final learningWorkspaceProvider = StateNotifierProvider.autoDispose
    .family<LearningNotifier, LearningState, String>((ref, courseId) {
      // A surviving workspace must never carry one subject's snapshots into
      // another subject's save. Session refresh does not change ownership.
      ref.watch(currentSessionProvider.select((session) => session?.user.id));
      return LearningNotifier(courseId, ref);
    });
