enum LessonType { video, pdf, text, quiz }

class AdminLesson {
  const AdminLesson({
    required this.id,
    required this.sectionId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.lessonType,
    required this.sortOrder,
    required this.isPreviewed,
    this.durationSeconds,
  });

  final String id;
  final String sectionId;
  final String courseId;
  final String title;
  final String description;
  final LessonType lessonType;
  final int sortOrder;
  final bool isPreviewed;
  final int? durationSeconds;

  AdminLesson copyWith({
    String? id,
    String? sectionId,
    String? courseId,
    String? title,
    String? description,
    LessonType? lessonType,
    int? sortOrder,
    bool? isPreviewed,
    int? durationSeconds,
  }) {
    return AdminLesson(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonType: lessonType ?? this.lessonType,
      sortOrder: sortOrder ?? this.sortOrder,
      isPreviewed: isPreviewed ?? this.isPreviewed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminLesson &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
