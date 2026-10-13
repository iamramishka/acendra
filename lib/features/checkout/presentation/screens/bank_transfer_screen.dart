import 'package:acendra/features/bank_transfer/presentation/screens/bank_transfer_screen.dart'
    as bank;
import 'package:flutter/material.dart';

/// Compatibility entry point for CSA-107. Uses the same trusted checkout
/// response and unavailable state as the registered bank-transfer route.
class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({
    super.key,
    required this.courseId,
    required this.orderId,
  });
  final String courseId;
  final String orderId;
  @override
  Widget build(BuildContext context) =>
      bank.BankTransferScreen(orderId: orderId);
}
