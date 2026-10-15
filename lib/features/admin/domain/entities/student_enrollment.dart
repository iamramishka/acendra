enum EnrollmentStatus { active, expired, revoked }

class StudentEnrollment {
  const StudentEnrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnailUrl,
    required this.enrolledAt,
    required this.status,
    required this.paymentMethod,
    required this.amountPaid,
    this.currency = 'LKR',
    required this.progressPercent,
    this.lastAccessedAt,
  });

  final String id;
  final String studentId;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final DateTime enrolledAt;
  final EnrollmentStatus status;
  final String paymentMethod;
  final double amountPaid;
  final String currency;
  final int progressPercent;
  final DateTime? lastAccessedAt;
}
