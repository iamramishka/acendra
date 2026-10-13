import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({
    super.key,
    required this.courseId,
    this.courseTitle,
    this.reason,
  });

  final String courseId;
  final String? courseTitle;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final description = reason != null && reason!.isNotEmpty
        ? reason!
        : 'Your payment could not be processed. Please try again or use a different payment method.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Failed'),
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
                    color: cs.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, size: 80, color: cs.error),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Payment Failed',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Try Again',
                    onPressed: () => context.go(
                      RouteNames.checkout.replaceAll(':courseId', courseId),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Contact Support',
                    variant: ButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please email support@acedra.com'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go(
                    RouteNames.courseDetail.replaceAll(':courseId', courseId),
                  ),
                  child: const Text('Back to Course'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
