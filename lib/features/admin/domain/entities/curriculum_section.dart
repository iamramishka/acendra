import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';

class AdminCurriculumSection {
  const AdminCurriculumSection({
    required this.id,
    required this.courseId,
    required this.title,
    required this.sortOrder,
    required this.lessons,
    this.isPublished = false,
    this.rawCourseUpdatedAt,
  });

  final String? rawCourseUpdatedAt;
  final bool isPublished;
  final String id;
  final String courseId;
  final String title;
  final int sortOrder;
  final List<AdminLesson> lessons;

  AdminCurriculumSection copyWith({
    bool? isPublished,
    String? rawCourseUpdatedAt,
    String? id,
    String? courseId,
    String? title,
    int? sortOrder,
    List<AdminLesson>? lessons,
  }) {
    return AdminCurriculumSection(
      isPublished: isPublished ?? this.isPublished,
      rawCourseUpdatedAt: rawCourseUpdatedAt ?? this.rawCourseUpdatedAt,
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      lessons: lessons ?? this.lessons,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCurriculumSection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
