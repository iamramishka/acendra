import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FinanceReviewScreen extends ConsumerWidget {
  const FinanceReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ref
            .watch(financeQueueProvider)
            .when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () => _LoadingSkeleton(),
              error: (_, _) => AppErrorState(
                message:
                    'Finance review is unavailable. Sign in with an authorized finance account and MFA, or try again later.',
                actionLabel: 'Retry',
                onRetry: () {
                  final identity = ref.read(bankSessionIdentityProvider);
                  if (identity != null) {
                    ref.invalidate(financeQueueRequestProvider(identity));
                  }
                },
              ),
              data: (items) => Column(
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
                              'Finance Review',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              items.isEmpty
                                  ? 'No pending receipts'
                                  : '${items.length} pending receipt${items.length == 1 ? '' : 's'}',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh queue',
                        onPressed: () {
                          final identity = ref.read(
                            bankSessionIdentityProvider,
                          );
                          if (identity != null) {
                            ref.invalidate(
                              financeQueueRequestProvider(identity),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      AppButton(
                        label: 'View Payment History',
                        onPressed: () => context.go('/admin/payments/history'),
                        variant: ButtonVariant.secondary,
                        size: ButtonSize.medium,
                        icon: const Icon(Icons.history_outlined, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        label: 'All Payments',
                        onPressed: () => context.go('/admin/payments'),
                        variant: ButtonVariant.outlined,
                        size: ButtonSize.medium,
                        icon: const Icon(Icons.payments_outlined, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (items.isEmpty)
                    Expanded(
                      child: AppEmptyState(
                        message: 'No receipts to review',
                        actionLabel: 'View Payment History',
                        onAction: () => context.go('/admin/payments/history'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => _ReviewCard(
                          key: ValueKey((
                            items[index]['submission_id'],
                            ref.watch(bankSessionWidgetKeyProvider),
                          )),
                          item: items[index],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(
            width: 200,
            height: 28,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSkeleton(
            width: 140,
            height: 18,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppSkeleton(
                width: double.infinity,
                height: 160,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  final reason = TextEditingController();
  final fields = List.generate(5, (_) => TextEditingController());
  bool busy = false, confirmed = false, approve = false;
  String source = 'bank_portal';

  @override
  void dispose() {
    reason.dispose();
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> decide() async {
    if (busy) return;
    final identity = ref.read(bankSessionIdentityProvider);
    if (identity == null) {
      AppSnackbar.show(
        context,
        'Sign in with an authorized finance account and MFA.',
        variant: SnackbarVariant.error,
      );
      return;
    }
    final item = widget.item;
    if (approve &&
        (!confirmed || fields.any((field) => field.text.trim().isEmpty))) {
      AppSnackbar.show(
        context,
        'Complete the independent bank-credit evidence and confirmation.',
        variant: SnackbarVariant.warning,
      );
      return;
    }
    if (!approve && reason.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Enter a student-safe rejection reason.',
        variant: SnackbarVariant.warning,
      );
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(bankTransferRepositoryProvider)
          .review(
            submissionId: item['submission_id'] as String,
            rejectionReason: approve ? null : reason.text.trim(),
            verifiedCredit: approve
                ? {
                    'bank_credit_confirmed': true,
                    'destination_account_id': fields[0].text.trim(),
                    'bank_transaction_id': fields[1].text.trim(),
                    'amount_minor': fields[2].text.trim(),
                    'currency': 'LKR',
                    'settled_at': fields[3].text.trim(),
                    'source': source,
                    'order_reference': fields[4].text.trim(),
                  }
                : null,
          );
      if (!mounted || ref.read(bankSessionIdentityProvider) != identity) return;
      ref.invalidate(financeQueueRequestProvider(identity));
      if (mounted) {
        AppSnackbar.show(
          context,
          'Decision recorded by the server.',
          variant: SnackbarVariant.success,
        );
        reason.clear();
      }
    } catch (_) {
      if (mounted && ref.read(bankSessionIdentityProvider) == identity) {
        AppSnackbar.show(
          context,
          'The decision was not confirmed. Your inputs are preserved. Refresh before retrying.',
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted && ref.read(bankSessionIdentityProvider) == identity) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    const labels = [
      'Destination account ID',
      'Independent bank transaction ID',
      'Exact amount in minor units',
      'Settled date and time (ISO 8601)',
      'Stored order reference',
    ];

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: ext?.border ?? cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item['course_title'] as String,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Order ${widget.item['order_number']}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.item['currency']} ${widget.item['amount_minor']} minor units',
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ext?.success ?? cs.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Verify settled funds in the business-controlled bank source. A receipt alone does not prove payment.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Approve with independent bank evidence',
                style: tt.bodyMedium,
              ),
              value: approve,
              onChanged: busy
                  ? null
                  : (value) => setState(() => approve = value),
            ),
            if (approve) ...[
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(
                labels.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppTextField(
                    label: labels[i],
                    controller: fields[i],
                    enabled: !busy,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: source,
                decoration: const InputDecoration(
                  labelText: 'Verification source',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'bank_portal',
                    child: Text('Bank portal'),
                  ),
                  DropdownMenuItem(
                    value: 'bank_statement',
                    child: Text('Bank statement'),
                  ),
                  DropdownMenuItem(
                    value: 'authenticated_bank_feed',
                    child: Text('Authenticated bank feed'),
                  ),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() => source = value!),
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I independently verified this settled credit in the bank source',
                  style: tt.bodyMedium,
                ),
                value: confirmed,
                onChanged: busy
                    ? null
                    : (value) => setState(() => confirmed = value ?? false),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Student-safe rejection reason',
                controller: reason,
                enabled: !busy,
                maxLines: 3,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: approve ? 'Record approval' : 'Record rejection',
              onPressed: busy ? null : decide,
              variant: approve
                  ? ButtonVariant.primary
                  : ButtonVariant.destructive,
              isLoading: busy,
            ),
          ],
        ),
      ),
    );
  }
}
