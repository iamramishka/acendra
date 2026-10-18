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
    final lastDone = flat.lastIndexWhere((l) => completed.contains(l.id));
    LessonItem? next;
    for (var i = lastDone + 1; i < flat.length && next == null; i++) {
      if (!completed.contains(flat[i].id)) next = flat[i];
    }
    next ??= flat.where((l) => !completed.contains(l.id)).firstOrNull;
    return CourseProgressSummary._(
      sections: sections,
      totalLessons: flat.length,
      completedIds: completed,
      nextLesson: next,
    );
  }

  final List<CurriculumSection> sections;
  final int totalLessons;
  final Set<String> completedIds;

  /// The lesson to resume or start; null when the course is finished.
  final LessonItem? nextLesson;

  int get completedLessons => completedIds.length;
  bool get hasStarted => completedIds.isNotEmpty;
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
