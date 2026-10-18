import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

/// Result of [LearningNotifier.completeAndContinue].
enum ContinueOutcome { advanced, moduleFinished, courseFinished, failed }

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
  String? _requestedLessonId;

  /// Opens [lessonId] instead of the saved resume lesson. Safe to call before
  /// the course has loaded.
  Future<void> requestLesson(String lessonId) async {
    if (state.sections.isEmpty) {
      _requestedLessonId = lessonId;
      return;
    }
    await selectLesson(lessonId);
  }

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
        String selected = flat.any((l) => l.id == _requestedLessonId)
            ? _requestedLessonId!
            : flat.first.id;
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
          if (valid.isNotEmpty &&
              !flat.any((l) => l.id == _requestedLessonId)) {
            selected = valid.first.lessonId;
          }
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
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load this lesson. Please try again.',
      );
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

  /// Marks the current lesson complete (if it is not already) and opens the
  /// next one. Reports where the learner ended up so the screen can show the
  /// right message; a failed save never advances.
  Future<ContinueOutcome> completeAndContinue() async {
    final lessonId = state.currentLessonId;
    if (lessonId == null) return ContinueOutcome.failed;
    if (!(state.progress[lessonId]?.completed ?? false)) {
      await setCompleted(true);
      if (!mounted || !(state.progress[lessonId]?.completed ?? false)) {
        return ContinueOutcome.failed;
      }
    }
    final flat = state.flatLessons;
    final index = flat.indexWhere((l) => l.id == lessonId);
    if (index < 0 || index == flat.length - 1) {
      return ContinueOutcome.courseFinished;
    }
    if (CourseProgressSummary.from(
      state.sections,
      state.progress,
    ).isLastInSection(lessonId)) {
      return ContinueOutcome.moduleFinished;
    }
    await selectLesson(flat[index + 1].id);
    return ContinueOutcome.advanced;
  }

  Future<void> saveVideoPosition(String lessonId, int seconds) async {
    if (!mounted) return;
    if (!state.progressReady || state.progressError != null) return;
    try {
      final saved = await _ref
          .read(learningProgressRepositoryProvider)
          .saveVideoPosition(lessonId, seconds, state.progress[lessonId]);
      if (!mounted) return;
      if (saved.lessonId == lessonId) {
        state = state.copyWith(progress: {...state.progress, lessonId: saved});
      }
    } catch (_) {
      // Best-effort: a missed periodic position save is non-fatal.
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
      final allowed = await repo.isEnrolledOrPreview(state.courseId, lessonId);
      if (!mounted || requestId != _requestId) return;
      if (!allowed) {
        state = state.copyWith(
          isLoading: false,
          error: 'You are not enrolled in this course.',
        );
        return;
      }
      final content = await repo.getLessonContent(lessonId);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(currentContent: content, isLoading: false);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load this lesson. Please try again.',
      );
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
