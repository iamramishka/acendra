import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/foundation.dart';

enum SectionStatus { todo, current, completed }

/// Course-level progress derived from the curriculum and saved lesson
/// progress. Display only: access decisions stay on the backend.
@immutable
class CourseProgressSummary {
  const CourseProgressSummary._({
    required this.sections,
    required this.totalLessons,
    required this.completedIds,
    required this.nextLesson,
    required this.startedIds,
  });

  factory CourseProgressSummary.from(
    List<CurriculumSection> sections,
    Map<String, SavedLessonProgress> progress,
  ) {
    final flat = [for (final s in sections) ...s.lessons];
    final completed = {
      for (final lesson in flat)
        if (progress[lesson.id]?.completed ?? false) lesson.id,
    };
    final saved = [
      for (final lesson in flat)
        if (progress[lesson.id] case final SavedLessonProgress entry) entry,
    ];
    final unfinished =
        saved
            .where((entry) => !entry.completed && entry.lastOpenedAt != null)
            .toList()
          ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    final started = {
      for (final entry in saved)
        if (entry.completed ||
            entry.lastOpenedAt != null ||
            (entry.videoSeconds ?? 0) > 0 ||
            (entry.pdfPage ?? 0) > 0 ||
            (entry.pdfPosition ?? 0) > 0)
          entry.lessonId,
    };
    final lastDone = flat.lastIndexWhere((l) => completed.contains(l.id));
    LessonItem? next = unfinished.isEmpty
        ? null
        : flat.firstWhere((lesson) => lesson.id == unfinished.first.lessonId);
    for (var i = lastDone + 1; i < flat.length && next == null; i++) {
      if (!completed.contains(flat[i].id)) next = flat[i];
    }
    next ??= flat.where((l) => !completed.contains(l.id)).firstOrNull;
    return CourseProgressSummary._(
      sections: sections,
      totalLessons: flat.length,
      completedIds: completed,
      nextLesson: next,
      startedIds: started,
    );
  }

  final List<CurriculumSection> sections;
  final int totalLessons;
  final Set<String> completedIds;

  /// The lesson to resume or start; null when the course is finished.
  final LessonItem? nextLesson;

  int get completedLessons => completedIds.length;
  final Set<String> startedIds;
  bool get hasStarted => startedIds.isNotEmpty;
  bool isStarted(String lessonId) => startedIds.contains(lessonId);
  int get percent =>
      totalLessons == 0 ? 0 : (completedLessons * 100 / totalLessons).round();

  bool isCompleted(String lessonId) => completedIds.contains(lessonId);

  SectionStatus sectionStatus(String sectionId) {
    final section = sections.firstWhere((s) => s.id == sectionId);
    final done = section.lessons.where((l) => completedIds.contains(l.id));
    if (section.lessons.isNotEmpty && done.length == section.lessons.length) {
      return SectionStatus.completed;
    }
    final containsNext = section.lessons.any((l) => l.id == nextLesson?.id);
    return done.isNotEmpty || containsNext && hasStarted
        ? SectionStatus.current
        : SectionStatus.todo;
  }

  bool isLastInSection(String lessonId) => sections.any(
    (s) => s.lessons.isNotEmpty && s.lessons.last.id == lessonId,
  );
}
