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
    // TODO: Replace with real Supabase queries using service-role or admin RPC.
    final repo = ref.read(adminPaymentRepositoryProvider);
    final pendingCount = await repo.countPayments(
      status: PaymentStatus.pending,
    );
    final recentPending = await repo.listPayments(
      status: PaymentStatus.pending,
      pageSize: 5,
    );
    return AdminDashboardStats(
      totalStudents: 128,
      totalCourses: 14,
      pendingPayments: pendingCount,
      totalRevenue: 245800.00,
      currency: 'LKR',
      recentPendingPayments: recentPending
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
          .toList(),
    );
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardStats>(
      AdminDashboardNotifier.new,
    );
