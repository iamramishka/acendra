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
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AdminDashboardStats(
      totalStudents: 128,
      totalCourses: 14,
      pendingPayments: 5,
      totalRevenue: 245800.00,
      currency: 'LKR',
      recentPendingPayments: [
        PaymentQueueItem(
          id: 'order-001',
          studentEmail: 'student1@example.com',
          courseTitle: 'Flutter Masterclass',
          amount: 4500.00,
          currency: 'LKR',
          submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'pending',
        ),
        PaymentQueueItem(
          id: 'order-002',
          studentEmail: 'student2@example.com',
          courseTitle: 'Advanced Dart',
          amount: 3200.00,
          currency: 'LKR',
          submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: 'pending',
        ),
        PaymentQueueItem(
          id: 'order-003',
          studentEmail: 'student3@example.com',
          courseTitle: 'UI/UX Fundamentals',
          amount: 5800.00,
          currency: 'LKR',
          submittedAt: DateTime.now().subtract(const Duration(hours: 9)),
          status: 'pending',
        ),
      ],
    );
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardStats>(
      AdminDashboardNotifier.new,
    );
