class AdminStudent {
  const AdminStudent({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.enrolledCourseCount,
    required this.totalAmountPaid,
    this.currency = 'LKR',
    required this.createdAt,
    required this.isActive,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final int enrolledCourseCount;
  final double? totalAmountPaid;
  final String currency;
  final DateTime createdAt;
  final bool isActive;
}
