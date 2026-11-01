import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/domain/payment_progress.dart';
import 'package:flutter/material.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: tt.bodySmall?.copyWith(color: ext.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Trusted order details; order creation and receipt submission are distinct.
class BankOrderDetailsCard extends StatelessWidget {
  const BankOrderDetailsCard({super.key, required this.submission});

  final ReceiptSubmission submission;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final submitted = submission.submittedAt?.toLocal();
    final ordered = submission.orderCreatedAt?.toLocal();

    Widget cell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tt.bodySmall?.copyWith(color: ext.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return _SectionCard(
      title: 'Order Details',
      subtitle: 'Here are your order and payment details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            submission.courseTitle,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(
                'Order Reference',
                submission.orderNumber == '---' ? '—' : submission.orderNumber,
              ),
              cell('Amount', submission.formattedAmount ?? 'Unavailable'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell('Payment Method', 'Bank Transfer'),
              cell(
                'Ordered',
                ordered == null
                    ? 'Unavailable'
                    : '${ordered.day}/${ordered.month}/${ordered.year}',
              ),
            ],
          ),
          if (submitted != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                cell(
                  'Submitted On',
                  '${submitted.day}/${submitted.month}/${submitted.year}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Four-step vertical timeline driven by [paymentProgressSteps].
class PaymentProgressCard extends StatelessWidget {
  const PaymentProgressCard({super.key, required this.status});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = paymentProgressSteps(status);
    return _SectionCard(
      title: 'Payment Progress',
      subtitle: 'Track the status of your payment and enrollment.',
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final ProgressStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    final (Color color, IconData? icon, String label) = switch (step.state) {
      ProgressState.done => (ext.success, Icons.check, 'Completed'),
      ProgressState.current => (ext.warning, Icons.schedule, 'In Progress'),
      ProgressState.failed => (cs.error, Icons.close, 'Needs Attention'),
      ProgressState.todo => (ext.border, null, 'Not Yet Started'),
    };
    final filled = step.state == ProgressState.done;

    return Semantics(
      label: '${step.title}: $label',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? color : Colors.transparent,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: icon == null
                        ? null
                        : Icon(
                            icon,
                            size: 16,
                            color: filled ? cs.surface : color,
                          ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: step.state == ProgressState.done
                            ? ext.success
                            : ext.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      step.description,
                      style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: tt.labelSmall?.copyWith(
                        color: step.state == ProgressState.todo
                            ? ext.textSecondary
                            : color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
