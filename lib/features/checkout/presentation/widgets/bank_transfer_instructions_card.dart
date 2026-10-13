import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/bank_transfer_details.dart';

/// Displays bank transfer instructions to the student during checkout.
///
/// Shows the bank account details, a copyable reference ID, a warning note,
/// and a confirmation button once the student has completed the transfer.
class BankTransferInstructionsCard extends StatelessWidget {
  const BankTransferInstructionsCard({
    super.key,
    required this.details,
    this.onConfirmTransfer,
  });

  final BankTransferDetails details;

  /// Called when the student taps "I've Completed the Transfer".
  /// Pass [null] to show the button in a disabled/inactive state.
  final VoidCallback? onConfirmTransfer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final surfaceSecondary =
        ext?.surfaceSecondary ?? cs.surfaceContainerHighest;
    final border = ext?.border ?? cs.outlineVariant;
    final warningBg = ext?.warningContainer ?? cs.secondaryContainer;
    final warningFg = ext?.warning ?? cs.secondary;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Heading ──────────────────────────────────────────────────────
            Text(
              'Bank Transfer Instructions',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Ordered steps ────────────────────────────────────────────────
            _StepList(
              steps: const [
                'Note the bank account details below.',
                'Log in to your internet or mobile banking.',
                'Transfer the exact amount shown.',
                'Include the Reference ID in the transfer description.',
                'Tap the confirmation button once done.',
              ],
              textStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Details table ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Bank Name',
                    value: details.bankName,
                    isFirst: true,
                  ),
                  _DetailRow(
                    label: 'Account Name',
                    value: details.accountName,
                  ),
                  _DetailRow(
                    label: 'Account Number',
                    value: details.accountNumber,
                  ),
                  _DetailRow(
                    label: 'Branch',
                    value: details.branch,
                  ),
                  _DetailRow(
                    label: 'Amount',
                    value: _formatAmount(details.currency, details.amount),
                    valueBold: true,
                  ),
                  _ReferenceIdRow(
                    referenceId: details.referenceId,
                    border: border,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Warning note ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: warningBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: warningFg,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Your receipt will be reviewed. '
                      'Access is granted only after finance approval.',
                      style: tt.bodySmall?.copyWith(color: warningFg),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Confirm button ────────────────────────────────────────────────
            AppButton(
              label: "I've Completed the Transfer",
              onPressed: onConfirmTransfer,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatAmount(String currency, double amount) {
    // Format with two decimal places, e.g. "LKR 12,500.00"
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );
    return '$currency $formatted';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Renders an ordered (numbered) list of instruction steps.
class _StepList extends StatelessWidget {
  const _StepList({required this.steps, this.textStyle});

  final List<String> steps;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}.', style: textStyle),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(steps[i], style: textStyle)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A single label + value row inside the details table.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isFirst = false,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final bool isFirst;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final border = ext?.border ?? cs.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: ext?.textSecondary ?? cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight:
                    valueBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Special row for the Reference ID with a monospace highlight and copy button.
class _ReferenceIdRow extends StatelessWidget {
  const _ReferenceIdRow({
    required this.referenceId,
    required this.border,
  });

  final String referenceId;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              'Reference ID',
              style: tt.bodySmall?.copyWith(
                color: ext?.textSecondary ?? cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                referenceId,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'Copy reference ID $referenceId',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy Reference ID',
              color: cs.primary,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: referenceId));
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('Reference ID copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
