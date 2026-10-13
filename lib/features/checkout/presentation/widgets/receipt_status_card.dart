import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:flutter/material.dart';

/// Displays the review status of a bank transfer receipt submission.
///
/// Shows different UI depending on whether the status is
/// [ReceiptStatus.submitted], [ReceiptStatus.approved], or
/// [ReceiptStatus.rejected].
class ReceiptStatusCard extends StatelessWidget {
  const ReceiptStatusCard({
    super.key,
    required this.submission,
    this.onGoToCourse,
    this.onResubmit,
  });

  final ReceiptSubmission submission;

  /// Called when the student taps "Go to Course" (approved state only).
  final VoidCallback? onGoToCourse;

  /// Called when the student taps "Resubmit Receipt" (rejected state only).
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: ext?.border ?? cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusHeader(submission: submission),
            if (submission.submittedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              _SubmittedTimestamp(
                submittedAt: submission.submittedAt!.toLocal(),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _StatusBody(
              submission: submission,
              onGoToCourse: onGoToCourse,
              onResubmit: onResubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal sub-widgets
// ---------------------------------------------------------------------------

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.submission});
  final ReceiptSubmission submission;

  @override
  Widget build(BuildContext context) {
    final (BadgeVariant variant, String label) = switch (submission.status) {
      ReceiptStatus.awaitingReceipt => (
        BadgeVariant.warning,
        'Awaiting Receipt',
      ),
      ReceiptStatus.submitted => (BadgeVariant.warning, 'Pending Review'),
      ReceiptStatus.underReview => (BadgeVariant.warning, 'Under Review'),
      ReceiptStatus.approved => (BadgeVariant.success, 'Payment Verified'),
      ReceiptStatus.rejected => (BadgeVariant.error, 'Rejected'),
    };

    return Row(
      children: [StatusBadge(label: label, variant: variant)],
    );
  }
}

/// Format a [DateTime] as e.g. "12 Oct 2026 at 14:30".
String _formatSubmittedAt(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} ${dt.year} at $h:$m';
}

class _SubmittedTimestamp extends StatelessWidget {
  const _SubmittedTimestamp({required this.submittedAt});
  final DateTime submittedAt;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatSubmittedAt(submittedAt);
    return Text(
      'Submitted $formatted',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color:
            Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
            Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.submission,
    required this.onGoToCourse,
    required this.onResubmit,
  });

  final ReceiptSubmission submission;
  final VoidCallback? onGoToCourse;
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    return switch (submission.status) {
      ReceiptStatus.awaitingReceipt => const Text(
        'Please upload your bank transfer receipt.',
      ),
      ReceiptStatus.submitted ||
      ReceiptStatus.underReview => const _PendingBody(),
      ReceiptStatus.approved => _ApprovedBody(onGoToCourse: onGoToCourse),
      ReceiptStatus.rejected => _RejectedBody(
        rejectionReason:
            submission.rejectionReason ??
            'Please contact support for the rejection reason.',
        onResubmit: onResubmit,
      ),
    };
  }
}

class _PendingBody extends StatelessWidget {
  const _PendingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your receipt is being reviewed by our finance team. '
          'This usually takes 1–2 business days.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        // Greyed-out placeholder for the course access area.
        Semantics(
          label: 'Course access will appear here once your payment is verified',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Course access pending payment verification',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovedBody extends StatelessWidget {
  const _ApprovedBody({required this.onGoToCourse});
  final VoidCallback? onGoToCourse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your payment has been verified. You now have access to your course.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Go to Course',
            onPressed: onGoToCourse,
            variant: ButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}

class _RejectedBody extends StatelessWidget {
  const _RejectedBody({
    required this.rejectionReason,
    required this.onResubmit,
  });

  final String rejectionReason;
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your receipt was not accepted. Please review the reason below and '
          'resubmit a valid receipt.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Rejection reason box.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reason for rejection',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                rejectionReason,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Submit New Receipt',
            onPressed: onResubmit,
            variant: ButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}
