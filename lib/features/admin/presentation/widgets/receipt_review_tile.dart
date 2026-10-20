import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/domain/entities/receipt_review_item.dart';
import 'package:flutter/material.dart';

/// A card widget that displays a bank transfer receipt for finance review.
///
/// Shows student/course details, submission time, current status badge,
/// and (for pending items) Approve/Reject action buttons.
///
/// Security note: Receipt file access must use signed URLs from the trusted
/// backend. Never expose permanent public storage links.
class ReceiptReviewTile extends StatelessWidget {
  const ReceiptReviewTile({
    super.key,
    required this.item,
    this.onApprove,
    this.onReject,
    this.onViewReceipt,
    this.isProcessing = false,
  });

  final ReceiptReviewItem item;
  final VoidCallback? onApprove;

  /// Returns true only when the rejection was recorded successfully.
  final bool Function(String reason)? onReject;
  final VoidCallback? onViewReceipt;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final dateStr = _formatDate(item.submittedAt.toLocal());
    final amountStr = '${item.currency} ${item.amount.toStringAsFixed(2)}';

    final statusBadge = switch (item.status) {
      ReceiptStatus.pending => const StatusBadge(
        label: 'Pending',
        variant: BadgeVariant.warning,
      ),
      ReceiptStatus.approved => const StatusBadge(
        label: 'Approved',
        variant: BadgeVariant.success,
      ),
      ReceiptStatus.rejected => const StatusBadge(
        label: 'Rejected',
        variant: BadgeVariant.error,
      ),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: ext?.border ?? cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: email + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.studentEmail,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                statusBadge,
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Course title
            Text(
              item.courseTitle,
              style: tt.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Amount row
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    amountStr,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ext?.success ?? cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Submitted at
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Submitted: $dateStr',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            // Rejection reason (if rejected)
            if (item.status == ReceiptStatus.rejected &&
                item.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(128),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: cs.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        item.rejectionReason!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Action row
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                // View receipt button always present
                AppButton(
                  label: 'View Receipt',
                  onPressed: onViewReceipt,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.medium,
                ),
                // Approve / Reject only for pending items
                if (item.status == ReceiptStatus.pending) ...[
                  Semantics(
                    label: 'Approve receipt for ${item.studentEmail}',
                    child: AppButton(
                      label: 'Approve',
                      onPressed: isProcessing ? null : onApprove,
                      variant: ButtonVariant.primary,
                      size: ButtonSize.medium,
                      isLoading: isProcessing,
                    ),
                  ),
                  Semantics(
                    label: 'Reject receipt for ${item.studentEmail}',
                    child: AppButton(
                      label: 'Reject',
                      onPressed: isProcessing || onReject == null
                          ? null
                          : () => _showRejectDialog(context),
                      variant: ButtonVariant.destructive,
                      size: ButtonSize.medium,
                      isLoading: isProcessing,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _RejectDialog(onConfirm: onReject),
    );
  }
}

// ---------------------------------------------------------------------------
// Reject dialog widget
// ---------------------------------------------------------------------------

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({this.onConfirm});

  final bool Function(String reason)? onConfirm;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final reason = _controller.text.trim();
    if (reason.length < 10) {
      setState(() => _errorText = 'Please enter at least 10 characters.');
      return;
    }
    final recorded = widget.onConfirm?.call(reason) ?? false;
    if (!mounted) return;
    if (recorded) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorText = 'Rejection was not recorded. Your reason has been kept.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Receipt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for rejection (required).'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Rejection reason',
            hint: 'Minimum 10 characters',
            controller: _controller,
            maxLines: 3,
            errorText: _errorText,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          variant: ButtonVariant.outlined,
          size: ButtonSize.medium,
        ),
        AppButton(
          label: 'Confirm Rejection',
          onPressed: _onConfirm,
          variant: ButtonVariant.destructive,
          size: ButtonSize.medium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/${dt.year}, $h:$min';
}
