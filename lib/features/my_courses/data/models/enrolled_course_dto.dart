import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';

/// DTO that parses the Supabase enrollment+courses join response.
///
/// Expected JSON shape (after joining enrollments with courses):
/// ```json
/// {
///   "id": "enrollment-uuid",
///   "course_id": "course-uuid",
///   "status": "active",
///   "created_at": "2024-01-01T00:00:00.000Z",
///   "courses": {
///     "id": "course-uuid",
///     "title": "Course Title",
///     "short_description": "..."
///   }
/// }
/// ```
class EnrolledCourseDto {
  const EnrolledCourseDto._({
    required this.id,
    required this.courseId,
    required this.title,
    required this.shortDescription,
    required this.status,
    required this.enrolledAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String shortDescription;
  final String status;
  final String enrolledAt;

  factory EnrolledCourseDto.fromJson(Map<String, dynamic> json) {
    final courseMap = json['courses'] as Map<String, dynamic>? ?? {};
    return EnrolledCourseDto._(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: courseMap['title'] as String? ?? '',
      shortDescription: courseMap['short_description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      enrolledAt: json['created_at'] as String? ?? '',
    );
  }

  EnrolledCourse toEntity() => EnrolledCourse(
    id: id,
    courseId: courseId,
    title: title,
    shortDescription: shortDescription,
    status: status,
    enrolledAt: enrolledAt,
  );
}
