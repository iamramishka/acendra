import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentQueueSummary extends StatelessWidget {
  const PaymentQueueSummary({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  final List<PaymentQueueItem> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: ext?.surfaceSecondary ?? cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: ext?.border ?? cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pending Payments',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      '${items.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (isLoading)
              _buildSkeleton()
            else if (items.isEmpty)
              const AppEmptyState(message: 'No pending payments')
            else
              Column(
                children: [
                  ...items.take(5).map((item) => _PaymentQueueRow(item: item)),
                ],
              ),
            if (!isLoading && items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(RouteNames.adminPayments),
                  child: const Text('View all payments'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: AppSkeleton(
                  height: 16,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppSkeleton(
                width: 60,
                height: 16,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentQueueRow extends StatelessWidget {
  const _PaymentQueueRow({required this.item});

  final PaymentQueueItem item;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final cs = theme.colorScheme;
    final badgeVariant = switch (item.status) {
      'approved' => BadgeVariant.success,
      'rejected' => BadgeVariant.error,
      _ => BadgeVariant.warning,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentEmail,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext?.textSecondary ?? cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(item.submittedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext?.textSecondary ?? cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.currency} ${item.amount.toStringAsFixed(2)}',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(label: item.status, variant: badgeVariant),
            ],
          ),
        ],
      ),
    );
  }
}
