import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:flutter/material.dart';

class PaymentRecordTile extends StatelessWidget {
  const PaymentRecordTile({super.key, required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final statusBadge = switch (record.status) {
      PaymentStatus.pending => const StatusBadge(
        label: 'Pending',
        variant: BadgeVariant.warning,
      ),
      PaymentStatus.approved => const StatusBadge(
        label: 'Approved',
        variant: BadgeVariant.success,
      ),
      PaymentStatus.rejected => const StatusBadge(
        label: 'Rejected',
        variant: BadgeVariant.error,
      ),
      PaymentStatus.processing => const StatusBadge(
        label: 'Processing',
        variant: BadgeVariant.info,
      ),
    };

    final methodBadge = switch (record.paymentMethod) {
      PaymentMethod.online => const StatusBadge(
        label: 'Online',
        variant: BadgeVariant.info,
      ),
      PaymentMethod.bankTransfer => const StatusBadge(
        label: 'Bank Transfer',
        variant: BadgeVariant.warning,
      ),
      PaymentMethod.adminGrant => const StatusBadge(
        label: 'Admin Grant',
        variant: BadgeVariant.success,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    record.orderNumber ?? record.orderId,
                    style: tt.labelLarge?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                statusBadge,
              ],
            ),
            if (record.studentEmail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                record.studentEmail,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              record.courseTitle,
              style: tt.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  record.formattedAmount,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ext?.success ?? cs.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                methodBadge,
                const Spacer(),
                Text(
                  _formatDate(record.createdAt.toLocal()),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            // TODO: Add View button when payment detail screen is implemented
          ],
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
