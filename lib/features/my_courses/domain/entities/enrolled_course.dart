/// Immutable entity representing a course a student is enrolled in.
class EnrolledCourse {
  const EnrolledCourse({
    required this.id,
    required this.courseId,
    required this.title,
    required this.shortDescription,
    this.thumbnailUrl,
    required this.status,
    required this.enrolledAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String shortDescription;
  final String? thumbnailUrl;
  final String status;
  final String enrolledAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrolledCourse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
