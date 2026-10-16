import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:acendra/features/admin/presentation/widgets/payment_queue_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);

    return statsAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        actionLabel: 'Retry',
        onRetry: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (stats) => _buildContent(context, stats),
    );
  }

  Widget _buildContent(BuildContext context, AdminDashboardStats stats) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AppBreakpoints.compact;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          isCompact
              ? Column(children: _buildStatCards(context, stats))
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.6,
                  children: _buildStatCards(context, stats),
                ),
          const SizedBox(height: AppSpacing.lg),
          PaymentQueueSummary(items: stats.recentPendingPayments),
          const SizedBox(height: AppSpacing.lg),
          Text('Quick Actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Manage Courses',
                onPressed: () => context.go(RouteNames.adminCourses),
                variant: ButtonVariant.secondary,
                icon: const Icon(Icons.library_books_outlined, size: 18),
              ),
              AppButton(
                label: 'Manage Students',
                onPressed: () => context.go(RouteNames.adminStudents),
                variant: ButtonVariant.secondary,
                icon: const Icon(Icons.people_outline, size: 18),
              ),
              AppButton(
                label: 'Finance Review',
                onPressed: () => context.go(RouteNames.financeReview),
                variant: ButtonVariant.secondary,
                icon: const Icon(Icons.account_balance_outlined, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatCards(
    BuildContext context,
    AdminDashboardStats stats,
  ) {
    return [
      _StatCard(
        icon: Icons.people_outline,
        value: stats.totalStudents.toString(),
        label: 'Total Students',
      ),
      _StatCard(
        icon: Icons.library_books_outlined,
        value: stats.totalCourses.toString(),
        label: 'Total Courses',
      ),
      _StatCard(
        icon: Icons.hourglass_empty_outlined,
        value: stats.pendingPayments.toString(),
        label: 'Pending Payments',
        isAlert: stats.pendingPayments > 0,
      ),
      _StatCard(
        icon: Icons.attach_money_outlined,
        value: '${stats.currency} ${_formatRevenue(stats.totalRevenue)}',
        label: 'Total Revenue',
      ),
    ];
  }

  String _formatRevenue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(
            width: 120,
            height: 22,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.6,
            children: List.generate(
              4,
              (_) => AppSkeleton(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const PaymentQueueSummary(items: [], isLoading: true),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.isAlert = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isAlert;

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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isAlert ? cs.errorContainer : cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isAlert ? cs.onErrorContainer : cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
