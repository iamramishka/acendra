import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:acendra/features/admin/presentation/widgets/admin_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiptReviewHistoryScreen extends ConsumerStatefulWidget {
  const ReceiptReviewHistoryScreen({super.key});

  @override
  ConsumerState<ReceiptReviewHistoryScreen> createState() =>
      _ReceiptReviewHistoryScreenState();
}

class _ReceiptReviewHistoryScreenState
    extends ConsumerState<ReceiptReviewHistoryScreen> {
  AdminPaymentsFilter _filter = const AdminPaymentsFilter();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onStatusTap(PaymentStatus? status) {
    setState(() {
      _filter = _filter.copyWith(status: status, clearStatus: status == null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(receiptHistoryProvider(_filter));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt Review History',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reviewed bank transfer receipts',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Search',
            hint: 'Student email',
            controller: _searchController,
            prefixIcon: const Icon(Icons.search_outlined, size: 20),
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(searchQuery: value);
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Status', style: tt.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AdminFilterChip(
                  label: 'All',
                  selected: _filter.status == null,
                  onTap: () => _onStatusTap(null),
                ),
                const SizedBox(width: AppSpacing.sm),
                AdminFilterChip(
                  label: 'Approved',
                  selected: _filter.status == PaymentStatus.approved,
                  onTap: () => _onStatusTap(PaymentStatus.approved),
                ),
                const SizedBox(width: AppSpacing.sm),
                AdminFilterChip(
                  label: 'Rejected',
                  selected: _filter.status == PaymentStatus.rejected,
                  onTap: () => _onStatusTap(PaymentStatus.rejected),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'From date',
                  hint: 'YYYY-MM-DD',
                  enabled: false,
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  // TODO: Integrate date picker
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: 'To date',
                  hint: 'YYYY-MM-DD',
                  enabled: false,
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  // TODO: Integrate date picker
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: historyAsync.when(
              loading: () => _LoadingSkeleton(),
              error: (error, _) => AppErrorState(
                message: error is PaymentReportingUnavailable
                    ? 'Receipt review history is unavailable. Please try again later.'
                    : 'Failed to load receipt history. Please try again.',
                actionLabel: 'Retry',
                onRetry: () => ref.invalidate(receiptHistoryProvider(_filter)),
              ),
              data: (records) => records.isEmpty
                  ? const AppEmptyState(message: 'No reviewed receipts yet.')
                  : ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) =>
                          _ReceiptHistoryTile(record: records[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptHistoryTile extends StatelessWidget {
  const _ReceiptHistoryTile({required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final statusBadge = record.status == PaymentStatus.approved
        ? const StatusBadge(label: 'Approved', variant: BadgeVariant.success)
        : const StatusBadge(label: 'Rejected', variant: BadgeVariant.error);

    final submittedStr = _formatDate(record.createdAt.toLocal());
    final reviewedStr = record.processedAt != null
        ? _formatDate(record.processedAt!.toLocal())
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: ext?.border ?? cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
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
                        record.studentEmail.isEmpty
                            ? record.orderNumber ?? record.orderId
                            : record.studentEmail,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        record.courseTitle,
                        style: tt.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                statusBadge,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  record.formattedAmount,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ext?.success ?? cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _DateRow(
                    icon: Icons.upload_outlined,
                    label: 'Submitted',
                    value: submittedStr,
                    cs: cs,
                    tt: tt,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DateRow(
                    icon: Icons.check_circle_outline,
                    label: 'Reviewed',
                    value: reviewedStr,
                    cs: cs,
                    tt: tt,
                  ),
                ),
              ],
            ),
            if (record.status == PaymentStatus.rejected &&
                record.processorNote != null) ...[
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
                        record.processorNote!,
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
            Row(
              children: [
                Container(
                  width: 56,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppButton(
                  label: 'View Receipt',
                  onPressed: null,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.medium,
                  // TODO: Fetch signed URL from backend and open receipt
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(value, style: tt.bodySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppSkeleton(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/${dt.year}, $h:$min';
}
