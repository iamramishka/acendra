import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
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

  final int? totalStudents;
  final int? totalCourses;

  /// Null means payment reporting is unavailable, rather than an empty queue.
  final int? pendingPayments;

  /// Null until trusted settlement reporting is activated. Payment list rows
  /// (including administrative grants) do not establish recognized revenue.
  final double? totalRevenue;
  final String currency;
  final List<PaymentQueueItem> recentPendingPayments;
}

class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardStats> {
  @override
  Future<AdminDashboardStats> build() async {
    final studentRepo = ref.watch(adminStudentRepositoryProvider);
    final courseRepo = ref.watch(adminCourseRepositoryProvider);
    final paymentRepo = ref.watch(adminPaymentRepositoryProvider);
    final counts = ref.watch(adminPaymentCountsProvider.future);

    final results = await Future.wait([
      _whenMetricAvailable(studentRepo.listStudents()),
      _whenMetricAvailable(courseRepo.listCourses()),
      _whenMetricAvailable(
        paymentRepo.listPayments(status: PaymentStatus.pending, pageSize: 5),
      ),
      _whenMetricAvailable(counts),
    ]);

    final students = results[0] as List?;
    final courses = results[1] as List?;
    final pendingRecords = results[2] as List<PaymentRecord>?;
    final statusCounts = results[3] as Map<PaymentStatus, int>?;

    final recentPending = (pendingRecords ?? const <PaymentRecord>[])
        .map(
          (r) => PaymentQueueItem(
            id: r.id,
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
      totalStudents: students?.length,
      totalCourses: courses?.length,
      pendingPayments: statusCounts?[PaymentStatus.pending],
      totalRevenue: null,
      currency: 'LKR',
      recentPendingPayments: recentPending,
    );
  }
}

Future<T?> _whenMetricAvailable<T>(Future<T> result) async {
  try {
    return await result;
  } on PaymentReportingUnavailable {
    return null;
  } on AdminDataException {
    // A restricted/unavailable metric must not hide other authorized metrics.
    return null;
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardStats>(
      AdminDashboardNotifier.new,
      retry: (retryCount, error) => null,
    );
