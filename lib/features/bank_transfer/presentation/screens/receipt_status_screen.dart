import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/widgets/payment_progress_widgets.dart';
import 'package:acendra/features/checkout/presentation/widgets/receipt_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// CSA-110 — Receipt submission status screen.
///
/// Shows the current status of a bank-transfer order:
/// awaiting_receipt → submitted → under_review → approved / rejected.
/// Submitting a receipt is hard-disabled on the backend (503); this screen
/// handles that gracefully and never implies submission = payment approved.
class ReceiptStatusScreen extends ConsumerWidget {
  const ReceiptStatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionAsync = ref.watch(receiptSubmissionProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        actions: [
          IconButton(
            tooltip: 'Refresh Payment Status',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final identity = ref.read(bankSessionIdentityProvider);
              if (identity != null) {
                ref.invalidate(
                  receiptSubmissionRequestProvider((identity, orderId)),
                );
              }
            },
          ),
        ],
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.dashboard),
        ),
      ),
      body: submissionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Only failures we wrote ourselves are safe to show verbatim.
        error: (err, _) => _ErrorBody(
          message: err is BankTransferFailure
              ? err.message
              : 'Something went wrong. Please try again.',
        ),
        data: (submission) => _StatusBody(
          submission: submission,
          onUploadTap: () => context.push(
            (submission.status == ReceiptStatus.awaitingReceipt
                    ? RouteNames.bankTransfer
                    : RouteNames.receiptResubmit)
                .replaceFirst(':orderId', orderId),
          ),
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.submission, required this.onUploadTap});

  final ReceiptSubmission submission;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (submission.status != ReceiptStatus.awaitingReceipt) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                ReceiptStatusCard(
                  submission: submission,
                  onResubmit: onUploadTap,
                  onGoToCourse: () => context.go(RouteNames.myCourses),
                ),
                const SizedBox(height: AppSpacing.md),
                BankOrderDetailsCard(submission: submission),
                const SizedBox(height: AppSpacing.md),
                PaymentProgressCard(status: submission.status),
                const SizedBox(height: AppSpacing.sm),
                const _Exits(),
              ],
            ),
          ),
        ),
      );
    }

    final config = _statusConfig(submission.status, ext, cs);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Status icon ───────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: config.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, size: 52, color: config.iconColor),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                config.title,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                config.body,
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                textAlign: TextAlign.center,
              ),

              // ── Rejection reason ──────────────────────────────────────
              if (submission.status == ReceiptStatus.rejected &&
                  submission.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        submission.rejectionReason!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // ── Order badge ───────────────────────────────────────────
              if (submission.orderNumber != '---')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    'Order #${submission.orderNumber}',
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: BankOrderDetailsCard(submission: submission),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: PaymentProgressCard(status: submission.status),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Actions ───────────────────────────────────────────────
              if (submission.status == ReceiptStatus.awaitingReceipt ||
                  submission.status == ReceiptStatus.rejected) ...[
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: submission.status == ReceiptStatus.rejected
                        ? 'Submit New Receipt'
                        : 'Upload Receipt',
                    onPressed: onUploadTap,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              const _Exits(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Exits extends StatelessWidget {
  const _Exits();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        TextButton(
          onPressed: () => context.go(RouteNames.dashboard),
          child: const Text('Go to Dashboard'),
        ),
        TextButton(
          onPressed: () => context.go(RouteNames.orders),
          child: const Text('View Orders'),
        ),
        TextButton(
          onPressed: () => context.go(RouteNames.marketplace),
          child: const Text('Explore Courses'),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to load status', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: tt.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Config helpers ────────────────────────────────────────────────────────────

class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;
}

_StatusConfig _statusConfig(
  ReceiptStatus status,
  AppThemeExtension ext,
  ColorScheme cs,
) {
  switch (status) {
    case ReceiptStatus.awaitingReceipt:
      return _StatusConfig(
        icon: Icons.upload_file_outlined,
        iconColor: cs.primary,
        iconBackground: cs.primaryContainer,
        title: 'Upload Your Receipt',
        body:
            'Please upload your bank transfer receipt so our team can verify your payment.',
      );
    case ReceiptStatus.submitted:
      return _StatusConfig(
        icon: Icons.schedule,
        iconColor: ext.warning,
        iconBackground: ext.warningContainer,
        title: 'Receipt Submitted',
        body:
            'Your receipt has been received. Our team will review it within 1–2 business days.',
      );
    case ReceiptStatus.underReview:
      return _StatusConfig(
        icon: Icons.manage_search_outlined,
        iconColor: ext.warning,
        iconBackground: ext.warningContainer,
        title: 'Under Review',
        body:
            'Our finance team is verifying your transfer. You\'ll be notified once approved.',
      );
    case ReceiptStatus.approved:
      return _StatusConfig(
        icon: Icons.check_circle_outline,
        iconColor: ext.success,
        iconBackground: ext.successContainer,
        title: 'Payment Verified',
        body:
            'Your bank transfer has been verified and your course access is now active.',
      );
    case ReceiptStatus.rejected:
      return _StatusConfig(
        icon: Icons.cancel_outlined,
        iconColor: cs.error,
        iconBackground: cs.errorContainer,
        title: 'Receipt Rejected',
        body:
            'There was an issue with your submitted receipt. Please review the reason below and resubmit.',
      );
  }
}
