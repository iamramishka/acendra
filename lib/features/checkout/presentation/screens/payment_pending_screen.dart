import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentPendingScreen extends StatelessWidget {
  const PaymentPendingScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.orderNumber,
    this.bankName,
    this.accountNumber,
  });

  final String courseId;
  final String courseTitle;
  final String orderNumber;
  final String? bankName;
  final String? accountNumber;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verification'),
        leading: const SizedBox.shrink(),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: ext.warningContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule, size: 80, color: ext.warning),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Awaiting Verification',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Payment has not been confirmed here. Check your account for the current order and receipt status. Access requires independently verified payment.',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
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
                    'Order #$orderNumber',
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What happens next?',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _NextStep(
                  icon: Icons.receipt_outlined,
                  label: 'We receive your receipt',
                  ext: ext,
                  tt: tt,
                ),
                const SizedBox(height: AppSpacing.sm),
                _NextStep(
                  icon: Icons.verified_user_outlined,
                  label: 'Our team verifies the transfer',
                  ext: ext,
                  tt: tt,
                ),
                const SizedBox(height: AppSpacing.sm),
                _NextStep(
                  icon: Icons.school_outlined,
                  label: 'Access follows independent payment verification',
                  ext: ext,
                  tt: tt,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Go to Dashboard',
                    onPressed: () => context.go(RouteNames.dashboard),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go(RouteNames.marketplace),
                  child: const Text('Browse Courses'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.label,
    required this.ext,
    required this.tt,
  });

  final IconData icon;
  final String label;
  final AppThemeExtension ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ext.warningContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: ext.warning),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: tt.bodyMedium)),
      ],
    );
  }
}
