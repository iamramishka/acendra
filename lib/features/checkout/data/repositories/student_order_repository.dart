import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentOrder {
  const StudentOrder({
    required this.id,
    required this.courseId,
    required this.title,
    required this.number,
    required this.amountMinor,
    required this.currency,
    required this.method,
    required this.status,
  });
  final String id, courseId, title, number, currency, method, status;
  final int amountMinor;
  bool get isOpen => const {
    'created',
    'pending_payment',
    'pending_verification',
  }.contains(status);
  bool get isBank => method == 'bank_transfer';
  String get statusLabel => switch (status) {
    'created' || 'pending_payment' => 'Awaiting Payment',
    'pending_verification' => 'Awaiting Verification',
    'paid' => 'Payment Verified',
    'failed' => 'Payment Failed',
    'cancelled' => 'Cancelled',
    'refunded' => 'Refunded',
    _ => 'Status unavailable',
  };
  String get formattedAmount =>
      '$currency ${amountMinor ~/ 100}.${(amountMinor % 100).toString().padLeft(2, '0')}';
  factory StudentOrder.fromJson(Map<String, dynamic> row) {
    final amount = row['amount_minor'];
    if (amount is! int || amount < 0) {
      throw const FormatException('Invalid order amount');
    }
    return StudentOrder(
      id: row['id'] as String,
      courseId: row['course_id'] as String,
      title: row['course_title_snapshot'] as String,
      number: row['order_number'] as String,
      amountMinor: amount,
      currency: row['currency_code'] as String,
      method: row['payment_method'] as String,
      status: row['status'] as String,
    );
  }
}

abstract class StudentOrderRepository {
  Future<StudentOrder?> findOpen(String actor, String courseId);
  Future<StudentOrder> read(String actor, String orderId);
}

class SupabaseStudentOrderRepository implements StudentOrderRepository {
  const SupabaseStudentOrderRepository(this.client);
  final SupabaseClient client;
  static const fields =
      'id,course_id,course_title_snapshot,order_number,amount_minor,currency_code,payment_method,status';
  @override
  Future<StudentOrder?> findOpen(String actor, String courseId) async {
    // Explicit owner filter complements, and never replaces, existing orders RLS.
    final rows = await client
        .from('orders')
        .select(fields)
        .eq('buyer_id', actor)
        .eq('course_id', courseId)
        .inFilter('status', [
          'created',
          'pending_payment',
          'pending_verification',
        ])
        .order('created_at', ascending: false)
        .order('id')
        .limit(1);
    return rows.isEmpty ? null : StudentOrder.fromJson(rows.single);
  }

  @override
  Future<StudentOrder> read(String actor, String orderId) async {
    final row = await client
        .from('orders')
        .select(fields)
        .eq('buyer_id', actor)
        .eq('id', orderId)
        .single();
    return StudentOrder.fromJson(row);
  }
}

final studentOrderRepositoryProvider = Provider<StudentOrderRepository>(
  (ref) => SupabaseStudentOrderRepository(Supabase.instance.client),
);
final openCourseOrderProvider = FutureProvider.autoDispose
    .family<StudentOrder?, String>((ref, courseId) {
      final actor = ref.watch(checkoutActorProvider);
      if (actor == null) return null;
      return ref
          .watch(studentOrderRepositoryProvider)
          .findOpen(actor, courseId);
    });
final studentOrderProvider = FutureProvider.autoDispose
    .family<StudentOrder, String>((ref, orderId) {
      final actor = ref.watch(checkoutActorProvider);
      if (actor == null) throw StateError('Sign in required');
      return ref.watch(studentOrderRepositoryProvider).read(actor, orderId);
    });
