import 'package:acendra/features/admin/domain/entities/payment_record.dart';

abstract interface class AdminPaymentRepository {
  Future<List<PaymentRecord>> listPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  });

  Future<PaymentRecord> getPayment(String paymentId);

  Future<int> countPayments({PaymentStatus? status, PaymentMethod? method});

  /// Returns a count for every PaymentStatus in a single atomic operation.
  /// Prefer this over calling countPayments once per status to avoid
  /// count skew when records change between queries.
  Future<Map<PaymentStatus, int>> countAllStatuses();
}

class PaymentReportingUnavailable implements Exception {
  const PaymentReportingUnavailable();
}

/// No approved live payment-list adapter is active. Never substitute fixtures
/// for financial records or infer zero balances from unavailable reporting.
class UnavailableAdminPaymentRepository implements AdminPaymentRepository {
  const UnavailableAdminPaymentRepository();

  @override
  Future<List<PaymentRecord>> listPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async => throw const PaymentReportingUnavailable();

  @override
  Future<PaymentRecord> getPayment(String paymentId) async =>
      throw const PaymentReportingUnavailable();

  @override
  Future<int> countPayments({
    PaymentStatus? status,
    PaymentMethod? method,
  }) async => throw const PaymentReportingUnavailable();

  @override
  Future<Map<PaymentStatus, int>> countAllStatuses() async =>
      throw const PaymentReportingUnavailable();
}

/// Synthetic fixture repository; tests must opt in explicitly.
class StubAdminPaymentRepository implements AdminPaymentRepository {
  static final _records = [
    PaymentRecord(
      id: 'pay_001',
      orderId: 'ORD-2026-0001',
      studentId: 'stu_001',
      studentEmail: 'alice@example.com',
      courseId: 'crs_001',
      courseTitle: 'Flutter & Dart Masterclass',
      amount: 4999.00,
      currency: 'LKR',
      paymentMethod: PaymentMethod.bankTransfer,
      status: PaymentStatus.pending,
      createdAt: DateTime(2026, 10, 14, 9, 30),
      receiptStoragePath: 'receipts/ORD-2026-0001/receipt.jpg',
    ),
    PaymentRecord(
      id: 'pay_002',
      orderId: 'ORD-2026-0002',
      studentId: 'stu_002',
      studentEmail: 'bob@example.com',
      courseId: 'crs_002',
      courseTitle: 'Advanced Supabase Development',
      amount: 2999.00,
      currency: 'LKR',
      paymentMethod: PaymentMethod.stripe,
      status: PaymentStatus.approved,
      createdAt: DateTime(2026, 10, 13, 14, 0),
      processedAt: DateTime(2026, 10, 13, 14, 5),
      processorNote: 'Stripe webhook verified.',
    ),
    PaymentRecord(
      id: 'pay_003',
      orderId: 'ORD-2026-0003',
      studentId: 'stu_003',
      studentEmail: 'carol@example.com',
      courseId: 'crs_001',
      courseTitle: 'Flutter & Dart Masterclass',
      amount: 4999.00,
      currency: 'LKR',
      paymentMethod: PaymentMethod.bankTransfer,
      status: PaymentStatus.rejected,
      createdAt: DateTime(2026, 10, 12, 10, 0),
      processedAt: DateTime(2026, 10, 12, 11, 0),
      processorNote: 'Amount does not match order total.',
      receiptStoragePath: 'receipts/ORD-2026-0003/receipt.pdf',
    ),
    PaymentRecord(
      id: 'pay_004',
      orderId: 'ORD-2026-0004',
      studentId: 'stu_004',
      studentEmail: 'david@example.com',
      courseId: 'crs_003',
      courseTitle: 'UI/UX Design Fundamentals',
      amount: 1500.00,
      currency: 'LKR',
      paymentMethod: PaymentMethod.adminGrant,
      status: PaymentStatus.approved,
      createdAt: DateTime(2026, 10, 11, 8, 0),
      processedAt: DateTime(2026, 10, 11, 8, 1),
      processorNote: 'Scholarship grant applied.',
    ),
    PaymentRecord(
      id: 'pay_005',
      orderId: 'ORD-2026-0005',
      studentId: 'stu_005',
      studentEmail: 'eve@example.com',
      courseId: 'crs_002',
      courseTitle: 'Advanced Supabase Development',
      amount: 2999.00,
      currency: 'LKR',
      paymentMethod: PaymentMethod.bankTransfer,
      status: PaymentStatus.processing,
      createdAt: DateTime(2026, 10, 15, 7, 45),
      receiptStoragePath: 'receipts/ORD-2026-0005/receipt.png',
    ),
    PaymentRecord(
      id: 'pay_006',
      orderId: 'ORD-2026-0006',
      studentId: 'stu_006',
      studentEmail: 'frank@example.com',
      courseId: 'crs_003',
      courseTitle: 'UI/UX Design Fundamentals',
      amount: 1500.00,
      currency: 'LKR',
      paymentMethod: PaymentMethod.stripe,
      status: PaymentStatus.pending,
      createdAt: DateTime(2026, 10, 15, 11, 0),
    ),
  ];

  @override
  Future<List<PaymentRecord>> listPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async {
    // TODO: Replace with Supabase query using filters, pagination and RLS.
    await Future.delayed(const Duration(milliseconds: 400));
    var results = _records.toList();
    if (status != null) {
      results = results.where((r) => r.status == status).toList();
    }
    if (method != null) {
      results = results.where((r) => r.paymentMethod == method).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results
          .where(
            (r) =>
                r.studentEmail.toLowerCase().contains(q) ||
                r.orderId.toLowerCase().contains(q),
          )
          .toList();
    }
    if (fromDate != null) {
      results = results.where((r) => r.createdAt.isAfter(fromDate)).toList();
    }
    if (toDate != null) {
      results = results.where((r) => r.createdAt.isBefore(toDate)).toList();
    }
    final start = page * pageSize;
    if (start >= results.length) return [];
    return results.sublist(start, (start + pageSize).clamp(0, results.length));
  }

  @override
  Future<PaymentRecord> getPayment(String paymentId) async {
    // TODO: Replace with Supabase single-row fetch using RLS.
    await Future.delayed(const Duration(milliseconds: 200));
    return _records.firstWhere((r) => r.id == paymentId);
  }

  @override
  Future<int> countPayments({
    PaymentStatus? status,
    PaymentMethod? method,
  }) async {
    // TODO: Replace with Supabase count query.
    await Future.delayed(const Duration(milliseconds: 200));
    var results = _records.toList();
    if (status != null) {
      results = results.where((r) => r.status == status).toList();
    }
    if (method != null) {
      results = results.where((r) => r.paymentMethod == method).toList();
    }
    return results.length;
  }

  @override
  Future<Map<PaymentStatus, int>> countAllStatuses() async {
    // TODO: Replace with SELECT status, COUNT(*) FROM payments GROUP BY status.
    await Future.delayed(const Duration(milliseconds: 200));
    final counts = <PaymentStatus, int>{
      for (final s in PaymentStatus.values) s: 0,
    };
    for (final r in _records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }
}
