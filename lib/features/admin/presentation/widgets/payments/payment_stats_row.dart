import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

class PaymentStatsRow extends StatelessWidget {
  const PaymentStatsRow({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.processingCount,
  });

  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int processingCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Pending',
            count: pendingCount,
            bgColor: ext?.warningContainer ?? cs.secondaryContainer,
            fgColor: ext?.warning ?? cs.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Processing',
            count: processingCount,
            bgColor: cs.tertiaryContainer,
            fgColor: cs.onTertiaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Approved',
            count: approvedCount,
            bgColor: ext?.successContainer ?? cs.primaryContainer,
            fgColor: ext?.success ?? cs.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Rejected',
            count: rejectedCount,
            bgColor: cs.errorContainer,
            fgColor: cs.onErrorContainer,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.bgColor,
    required this.fgColor,
  });

  final String label;
  final int count;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: tt.headlineMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: tt.labelMedium?.copyWith(color: fgColor)),
        ],
      ),
    );
  }
}
