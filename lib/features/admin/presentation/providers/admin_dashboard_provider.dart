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
    final counts = await ref.watch(adminPaymentCountsProvider.future);
    final pending = await ref
        .watch(adminPaymentRepositoryProvider)
        .listPayments(status: PaymentStatus.pending, pageSize: 5);
    return AdminDashboardStats(
      totalStudents: 128,
      totalCourses: 14,
      pendingPayments: counts[PaymentStatus.pending]!,
      totalRevenue: 245800.00,
      currency: 'LKR',
      recentPendingPayments: pending
          .map(
            (record) => PaymentQueueItem(
              id: record.id,
              studentEmail: record.studentEmail,
              courseTitle: record.courseTitle,
              amount: record.amount,
              currency: record.currency,
              submittedAt: record.createdAt,
              status: record.status.name,
            ),
          )
          .toList(),
    );
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardStats>(
      AdminDashboardNotifier.new,
    );
