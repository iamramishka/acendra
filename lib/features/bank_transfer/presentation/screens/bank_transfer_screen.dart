import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// CSA-107 — Bank transfer instructions screen.
///
/// Shows step-by-step guidance for completing a bank transfer together with
/// the account details from [BankInstructions]. The "I've made the transfer"
/// CTA navigates the student to the receipt status screen.
class BankTransferScreen extends ConsumerWidget {
  const BankTransferScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final order = checkout.value;
    final instructions = order?.bankInstructions;
    if (checkout.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bank Transfer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (checkout.hasError ||
        order == null ||
        order.orderId != orderId ||
        order.paymentMethod != PaymentMethod.bankTransfer ||
        order.status != 'pending_payment' ||
        order.nextAction != 'show_bank_instructions' ||
        order.orderNumber.trim().isEmpty ||
        order.amountMinor <= 0 ||
        instructions == null ||
        instructions.bankName.trim().isEmpty ||
        instructions.accountHolder.trim().isEmpty ||
        instructions.accountNumber.trim().isEmpty ||
        instructions.branch.trim().isEmpty ||
        instructions.currency != order.currencyCode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bank Transfer')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Payment instructions are unavailable. Please contact support before making a transfer.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final orderNumber = order.orderNumber;
    final courseTitle = order.courseTitle;
    final formattedAmount = order.formattedAmount;
    final bankInstructions = instructions;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transfer'),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.dashboard),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Order badge ───────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            'Order #$orderNumber  •  $formattedAmount',
                            style: tt.bodySmall?.copyWith(
                              color: ext.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      _CopyButton(label: 'order reference', value: orderNumber),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  courseTitle,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Step list ─────────────────────────────────────────────
                _StepTile(
                  step: 1,
                  label: 'Log in to your bank',
                  detail:
                      'Use your bank\'s mobile app, internet banking, or visit a branch.',
                  ext: ext,
                  tt: tt,
                ),
                const SizedBox(height: AppSpacing.md),
                _StepTile(
                  step: 2,
                  label: 'Transfer the exact amount',
                  detail:
                      'Make sure you transfer exactly $formattedAmount. '
                      'Incorrect amounts will delay verification.',
                  ext: ext,
                  tt: tt,
                ),
                const SizedBox(height: AppSpacing.md),
                _StepTile(
                  step: 3,
                  label: 'Use Order #$orderNumber as reference',
                  detail:
                      'Enter the order number in the transfer reference / narration field.',
                  ext: ext,
                  tt: tt,
                ),
                const SizedBox(height: AppSpacing.md),
                _StepTile(
                  step: 4,
                  label: 'Save your receipt',
                  detail:
                      'Keep a screenshot or PDF of the transfer confirmation.',
                  ext: ext,
                  tt: tt,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Bank account details ──────────────────────────────────
                _BankDetailsCard(
                  instructions: bankInstructions,
                  ext: ext,
                  tt: tt,
                  cs: cs,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Use the exact amount and put your order reference '
                  '($orderNumber) in the payment description.',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Disclaimer ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: ext.warningContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: ext.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: ext.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Course access is activated only after our finance team '
                          'independently verifies the bank credit. '
                          'Contact support for review times after submitting your receipt.',
                          style: tt.bodySmall?.copyWith(
                            color: ext.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: "I've made the transfer",
                  onPressed: () => context.push(
                    RouteNames.receiptStatus.replaceFirst(':orderId', orderId),
                  ),
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.label,
    required this.detail,
    required this.ext,
    required this.tt,
  });

  final int step;
  final String label;
  final String detail;
  final AppThemeExtension ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: tt.labelMedium?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: tt.bodySmall?.copyWith(color: ext.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BankDetailsCard extends StatelessWidget {
  const _BankDetailsCard({
    required this.instructions,
    required this.ext,
    required this.tt,
    required this.cs,
  });

  final BankInstructions instructions;
  final AppThemeExtension ext;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_outlined, color: cs.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Account Details',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Bank',
            value: instructions.bankName,
            copyable: true,
            tt: tt,
            ext: ext,
          ),
          _DetailRow(
            label: 'Account Holder',
            value: instructions.accountHolder,
            copyable: true,
            tt: tt,
            ext: ext,
          ),
          _DetailRow(
            label: 'Account Number',
            value: instructions.accountNumber,
            copyable: true,
            tt: tt,
            ext: ext,
          ),
          _DetailRow(
            label: 'Branch',
            value: instructions.branch,
            copyable: false,
            tt: tt,
            ext: ext,
          ),
          _DetailRow(
            label: 'Currency',
            value: instructions.currency,
            copyable: false,
            tt: tt,
            ext: ext,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.copyable,
    required this.tt,
    required this.ext,
  });

  final String label;
  final String value;
  final bool copyable;
  final TextTheme tt;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (copyable) _CopyButton(label: label.toLowerCase(), value: value),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy $label',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: const Icon(Icons.copy_outlined, size: 18),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
