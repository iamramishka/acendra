import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentQueueItem {
  const PaymentQueueItem({
    required this.id,
    required this.studentEmail,
    required this.courseTitle,
    required this.amount,
    required this.currency,
    required this.submittedAt,
    required this.status,
  });

  final String id;
  final String studentEmail;
  final String courseTitle;
  final double amount;
  final String currency;
  final DateTime submittedAt;
  final String status;
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalStudents,
    required this.totalCourses,
    required this.pendingPayments,
    required this.totalRevenue,
    this.currency = 'LKR',
    required this.recentPendingPayments,
  });

  final int totalStudents;
  final int totalCourses;
  final int pendingPayments;
  final double totalRevenue;
  final String currency;
  final List<PaymentQueueItem> recentPendingPayments;
}

class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardStats> {
  @override
  Future<AdminDashboardStats> build() async {
    final studentRepo = ref.read(adminStudentRepositoryProvider);
    final courseRepo = ref.read(adminCourseRepositoryProvider);
    final paymentRepo = ref.read(adminPaymentRepositoryProvider);

    final results = await Future.wait([
      studentRepo.listStudents(),
      courseRepo.listCourses(),
      paymentRepo.listPayments(status: PaymentStatus.pending, pageSize: 5),
      paymentRepo.listPayments(status: PaymentStatus.approved, pageSize: 100),
      paymentRepo.countPayments(status: PaymentStatus.pending),
    ]);

    final students = results[0] as List;
    final courses = results[1] as List;
    final pendingRecords = results[2] as List<PaymentRecord>;
    final approvedRecords = results[3] as List<PaymentRecord>;
    final pendingCount = results[4] as int;

    final totalRevenue = approvedRecords.fold<double>(
      0,
      (sum, r) => sum + r.amount,
    );

    final recentPending = pendingRecords
        .map(
          (r) => PaymentQueueItem(
            id: r.orderId,
            studentEmail: r.studentEmail,
            courseTitle: r.courseTitle,
            amount: r.amount,
            currency: r.currency,
            submittedAt: r.createdAt,
            status: r.status.name,
          ),
        )
        .toList();

    return AdminDashboardStats(
      totalStudents: students.length,
      totalCourses: courses.length,
      pendingPayments: pendingCount,
      totalRevenue: totalRevenue,
      currency: 'LKR',
      recentPendingPayments: recentPending,
    );
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardStats>(
      AdminDashboardNotifier.new,
    );
