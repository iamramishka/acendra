import 'package:acendra/features/checkout/presentation/screens/order_status_screen.dart';
import 'package:flutter/material.dart';

/// Provider return hints do not override the owner-scoped backend order status.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.orderId, this.courseId});
  final String? orderId;
  final String? courseId;
  @override
  Widget build(BuildContext context) => OrderStatusScreen(
    orderId: orderId,
    expectedCourseId: courseId,
    onlineOnly: true,
    cancelledReturn: false,
  );
}
