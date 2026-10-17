import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:acendra/features/admin/presentation/widgets/payments/payment_filter_bar.dart';
import 'package:acendra/features/admin/presentation/widgets/payments/payment_record_tile.dart';
import 'package:acendra/features/admin/presentation/widgets/payments/payment_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final paymentsAsync = ref.watch(adminPaymentsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: paymentsAsync.when(
        loading: () => SingleChildScrollView(child: _LoadingSkeleton()),
        error: (error, _) => AppErrorState(
          message: error is PaymentReportingUnavailable
              ? 'Payment reporting is unavailable. Please try again later.'
              : 'Failed to load payments. Please try again.',
          actionLabel: 'Retry',
          onRetry: () => ref.read(adminPaymentsProvider.notifier).refresh(),
        ),
        data: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${state.totalCount} total payments · ${state.records.length} loaded for current filters',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Receipt History',
                  onPressed: () => context.go('/admin/payments/history'),
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                  icon: const Icon(Icons.history_outlined, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () =>
                      ref.read(adminPaymentsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('All payments by status', style: tt.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            PaymentStatsRow(
              pendingCount: state.pendingCount,
              processingCount: state.processingCount,
              approvedCount: state.approvedCount,
              rejectedCount: state.rejectedCount,
            ),
            const SizedBox(height: AppSpacing.lg),
            PaymentFilterBar(
              filter: state.filter,
              onFilterChanged: (filter) =>
                  ref.read(adminPaymentsProvider.notifier).applyFilter(filter),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.isLoading && state.records.isEmpty)
              _LoadingSkeleton()
            else if (state.records.isEmpty)
              const Expanded(
                child: AppEmptyState(
                  message: 'No payments found for the selected filters.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: state.records.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index == state.records.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Center(
                          child: AppButton(
                            label: 'Load more',
                            onPressed: state.isLoading
                                ? null
                                : () => ref
                                      .read(adminPaymentsProvider.notifier)
                                      .loadMore(),
                            variant: ButtonVariant.outlined,
                            isLoading: state.isLoading,
                          ),
                        ),
                      );
                    }
                    return PaymentRecordTile(record: state.records[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(
          width: 160,
          height: 28,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppSkeleton(
                width: double.infinity,
                height: 64,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppSkeleton(
                width: double.infinity,
                height: 64,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppSkeleton(
                width: double.infinity,
                height: 64,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppSkeleton(
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ),
      ],
    );
  }
}
