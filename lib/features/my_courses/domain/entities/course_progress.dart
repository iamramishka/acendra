enum ProgressFilter { all, inProgress, notStarted, completed }

/// Lesson-completion summary for one enrolled course (COM-015/016).
class CourseProgress {
  const CourseProgress({
    required this.courseId,
    required this.totalLessons,
    required this.completedLessons,
    this.nextLessonId,
    this.lastOpenedAt,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) => CourseProgress(
    courseId: json['course_id'] as String,
    totalLessons: (json['total_lessons'] as num).toInt(),
    completedLessons: (json['completed_lessons'] as num).toInt(),
    nextLessonId: json['next_lesson_id'] as String?,
    lastOpenedAt: json['last_opened_at'] == null
        ? null
        : DateTime.parse(json['last_opened_at'] as String),
  );

  final String courseId;
  final int totalLessons;
  final int completedLessons;
  final String? nextLessonId;
  final DateTime? lastOpenedAt;

  /// Fraction in [0, 1].
  double get fraction =>
      totalLessons == 0 ? 0 : (completedLessons / totalLessons).clamp(0.0, 1.0);

  int get percent => (fraction * 100).round();

  bool get isCompleted => totalLessons > 0 && completedLessons >= totalLessons;

  bool get isStarted => completedLessons > 0 || lastOpenedAt != null;

  bool matches(ProgressFilter filter) => switch (filter) {
    ProgressFilter.all => true,
    ProgressFilter.completed => isCompleted,
    ProgressFilter.notStarted => !isStarted && !isCompleted,
    ProgressFilter.inProgress => isStarted && !isCompleted,
  };

  /// Where "Continue" should go: the next unfinished lesson, else the overview.
  String get resumePath => nextLessonId == null || isCompleted
      ? '/learn/$courseId'
      : '/learn/$courseId/$nextLessonId';
}
