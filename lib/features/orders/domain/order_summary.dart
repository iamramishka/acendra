import 'package:flutter/foundation.dart';

enum OrderFilter { all, paid, awaiting }

@immutable
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.courseId,
    required this.courseTitle,
    required this.amountMinor,
    required this.currencyCode,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: json['id'] as String,
    orderNumber: json['order_number'] as String,
    courseId: json['course_id'] as String,
    courseTitle: json['course_title_snapshot'] as String,
    amountMinor: (json['amount_minor'] as num).toInt(),
    currencyCode: json['currency_code'] as String,
    paymentMethod: json['payment_method'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String orderNumber;
  final String courseId;
  final String courseTitle;
  final int amountMinor;
  final String currencyCode;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  bool get isPaid => status == 'paid';

  bool get isAwaiting =>
      status == 'created' ||
      status == 'pending_payment' ||
      status == 'pending_verification';

  bool get isBankTransfer => paymentMethod == 'bank_transfer';

  bool matches(OrderFilter filter) => switch (filter) {
    OrderFilter.all => true,
    OrderFilter.paid => isPaid,
    OrderFilter.awaiting => isAwaiting,
  };

  /// Student-facing label; never show the raw backend code.
  String get statusLabel => switch (status) {
    'paid' => 'Paid',
    'pending_verification' => 'Awaiting Verification',
    'created' || 'pending_payment' => 'Awaiting Payment',
    'failed' => 'Failed',
    'cancelled' => 'Cancelled',
    'refunded' => 'Refunded',
    _ => 'Processing',
  };

  String get formattedAmount {
    final major = (amountMinor ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currencyCode $major.${(amountMinor % 100).toString().padLeft(2, '0')}';
  }
}
