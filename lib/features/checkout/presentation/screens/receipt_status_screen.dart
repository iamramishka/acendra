import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/checkout/domain/entities/receipt_submission.dart';
import 'package:acendra/features/checkout/presentation/widgets/receipt_status_card.dart';
import 'package:flutter/material.dart';

/// Screen that shows the review status of a bank transfer receipt.
///
/// The [orderId] identifies the order for which the receipt was submitted.
///
/// TODO(CSA-110): Replace the mock [ReceiptSubmission] below with a Riverpod
/// provider that loads real data from the backend:
///
/// ```dart
/// final submission = ref.watch(receiptSubmissionProvider(orderId));
/// return submission.when(
///   loading: () => const AppLoadingState(),
///   error: (e, _) => AppErrorState(message: e.toString()),
///   data: (s) => ReceiptStatusCard(submission: s, ...),
/// );
/// ```
class ReceiptStatusScreen extends StatelessWidget {
  const ReceiptStatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    // TODO(CSA-110): Replace mock data with real Riverpod provider.
    final mockSubmission = ReceiptSubmission(
      id: 'mock-receipt-001',
      orderId: orderId,
      status: ReceiptReviewStatus.pending,
      submittedAt: DateTime(2026, 10, 12, 14, 30),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            // Cap card width on wide screens.
            constraints: const BoxConstraints(maxWidth: 600),
            child: ReceiptStatusCard(
              submission: mockSubmission,
              // TODO(CSA-110): Wire up real navigation via go_router.
              onGoToCourse: null,
              onResubmit: null,
            ),
          ),
        ),
      ),
    );
  }
}
