import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
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
  });

  final String courseId;
  final List<CurriculumSection> sections;
  final String? currentLessonId;
  final LessonContent? currentContent;
  final bool isLoading;
  final String? error;

  LearningState copyWith({
    List<CurriculumSection>? sections,
    String? currentLessonId,
    LessonContent? currentContent,
    bool? isLoading,
    String? error,
    bool clearContent = false,
    bool clearError = false,
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
    if (!mounted) return;
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(learningRepositoryProvider);
      final sections = await repo.getCurriculumWithLessons(courseId);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(sections: sections, isLoading: false);

      final flat = state.flatLessons;
      if (flat.isNotEmpty) {
        await selectLesson(flat.first.id);
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
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
    .family<LearningNotifier, LearningState, String>(
      (ref, courseId) => LearningNotifier(courseId, ref),
    );
