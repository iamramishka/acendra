import 'package:acendra/features/checkout/presentation/widgets/receipt_resubmission_form.dart';
import 'package:flutter/material.dart';

// TODO: Replace with a real Riverpod provider that fetches rejection details
// for the given orderId from the backend (CSA-109 validates ownership).

/// Screen that allows a student to upload a new bank transfer receipt after
/// their previous one was rejected by the finance team.
///
/// Navigation (go_router): register this screen in the app router and pass
/// [orderId] as a path parameter.  For example:
///
/// ```dart
/// GoRoute(
///   path: '/checkout/:orderId/resubmit-receipt',
///   builder: (context, state) => ReceiptResubmissionScreen(
///     orderId: state.pathParameters['orderId']!,
///   ),
/// ),
/// ```
class ReceiptResubmissionScreen extends StatelessWidget {
  const ReceiptResubmissionScreen({
    super.key,
    required this.orderId,
  });

  /// The order ID for which a new receipt needs to be submitted.
  final String orderId;

  @override
  Widget build(BuildContext context) {
    // TODO: Load rejectionReason from provider once CSA-109 backend is wired up.
    const String? rejectionReason = null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resubmit Receipt'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ReceiptResubmissionForm(
            orderId: orderId,
            rejectionReason: rejectionReason,
            onSubmitted: () {
              // TODO: Navigate to a confirmation screen or back to the order detail.
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ),
      ),
    );
  }
}
