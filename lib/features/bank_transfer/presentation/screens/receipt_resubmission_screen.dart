import 'package:acendra/features/checkout/presentation/widgets/receipt_resubmission_form.dart';
import 'package:flutter/material.dart';

/// Canonical routed receipt resubmission screen. Upload remains unavailable
/// until the approved backend inspection and release gates are satisfied.
class ReceiptResubmissionScreen extends StatelessWidget {
  const ReceiptResubmissionScreen({
    super.key,
    required this.orderId,
    this.rejectionReason,
  });
  final String orderId;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Resubmit Receipt')),
    body: SafeArea(
      child: Center(
        child: ReceiptResubmissionForm(
          orderId: orderId,
          rejectionReason: rejectionReason,
        ),
      ),
    ),
  );
}
