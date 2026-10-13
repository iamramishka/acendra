import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CSA-111 — Minimum finance review screen (P0, admin only).
///
/// Accessible only to finance_admin / super_admin roles (enforced on the
/// backend). The UI shows pending bank-transfer submissions and allows
/// the reviewer to approve or reject each one with a reason.
///
/// The backend endpoint is hard-disabled (503 BANK_REVIEW_UNAVAILABLE);
/// this screen surfaces that gracefully. Approval here never directly
/// grants course access — the trusted backend controls enrollment.
class FinanceReviewScreen extends ConsumerStatefulWidget {
  const FinanceReviewScreen({super.key});

  @override
  ConsumerState<FinanceReviewScreen> createState() =>
      _FinanceReviewScreenState();
}

class _FinanceReviewScreenState extends ConsumerState<FinanceReviewScreen> {
  final _rejectionController = TextEditingController();
  String? _activeSubmissionId;
  bool _showRejectForm = false;

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(bankReviewProvider);
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Review'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pending Bank Transfers',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Review submitted receipts and approve or reject each transfer. '
                  'Approval is verified independently — never trust receipt images alone.',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Backend-disabled notice ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: ext.warningContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: ext.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.construction_outlined,
                        size: 18,
                        color: ext.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Bank transfer review is not yet enabled. '
                          'This screen will be functional once the backend is activated.',
                          style: tt.bodySmall?.copyWith(
                            color: ext.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                if (reviewState is AsyncError) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      reviewState.error.toString(),
                      style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _PendingCard(
                  submissionId: 'stub-001',
                  orderNumber: '---',
                  studentName: 'Example Student',
                  courseTitle: 'Example Course',
                  amount: '—',
                  submittedAt: '—',
                  isProcessing:
                      reviewState is AsyncLoading &&
                      _activeSubmissionId == 'stub-001',
                  showRejectForm:
                      _showRejectForm && _activeSubmissionId == 'stub-001',
                  rejectionController: _rejectionController,
                  ext: ext,
                  tt: tt,
                  cs: cs,
                  onApprove: () => _onApprove('stub-001'),
                  onRejectTap: () => setState(() {
                    _activeSubmissionId = 'stub-001';
                    _showRejectForm = true;
                  }),
                  onRejectConfirm: () => _onReject('stub-001'),
                  onRejectCancel: () => setState(() {
                    _showRejectForm = false;
                    _activeSubmissionId = null;
                    _rejectionController.clear();
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onApprove(String submissionId) {
    setState(() => _activeSubmissionId = submissionId);
    ref
        .read(bankReviewProvider.notifier)
        .approve(submissionId: submissionId, verifiedCredit: '');
  }

  Future<void> _onReject(String submissionId) async {
    if (ref.read(bankReviewProvider).isLoading) return;
    final reason = _rejectionController.text.trim();
    if (reason.isEmpty) return;
    await ref
        .read(bankReviewProvider.notifier)
        .reject(submissionId: submissionId, rejectionReason: reason);
    if (!mounted || ref.read(bankReviewProvider).hasError) return;
    setState(() {
      _showRejectForm = false;
      _rejectionController.clear();
    });
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.submissionId,
    required this.orderNumber,
    required this.studentName,
    required this.courseTitle,
    required this.amount,
    required this.submittedAt,
    required this.isProcessing,
    required this.showRejectForm,
    required this.rejectionController,
    required this.ext,
    required this.tt,
    required this.cs,
    required this.onApprove,
    required this.onRejectTap,
    required this.onRejectConfirm,
    required this.onRejectCancel,
  });

  final String submissionId;
  final String orderNumber;
  final String studentName;
  final String courseTitle;
  final String amount;
  final String submittedAt;
  final bool isProcessing;
  final bool showRejectForm;
  final TextEditingController rejectionController;
  final AppThemeExtension ext;
  final TextTheme tt;
  final ColorScheme cs;
  final VoidCallback onApprove;
  final VoidCallback onRejectTap;
  final VoidCallback onRejectConfirm;
  final VoidCallback onRejectCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      courseTitle,
                      style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: ext.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  'PENDING',
                  style: tt.labelSmall?.copyWith(
                    color: ext.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          _DetailRow(label: 'Order', value: '#$orderNumber', tt: tt, ext: ext),
          _DetailRow(label: 'Amount', value: amount, tt: tt, ext: ext),
          _DetailRow(label: 'Submitted', value: submittedAt, tt: tt, ext: ext),

          const SizedBox(height: AppSpacing.md),

          if (showRejectForm) ...[
            TextField(
              controller: rejectionController,
              enabled: !isProcessing,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: 'Rejection reason (shown to student)',
                hintText: 'Describe what was wrong with the receipt…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Confirm Reject',
                    onPressed: isProcessing ? null : onRejectConfirm,
                    variant: ButtonVariant.destructive,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    onPressed: isProcessing ? null : onRejectCancel,
                    variant: ButtonVariant.outlined,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: isProcessing ? 'Processing…' : 'Approve',
                    onPressed: isProcessing ? null : onApprove,
                    variant: ButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    onPressed: isProcessing ? null : onRejectTap,
                    variant: ButtonVariant.destructive,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.tt,
    required this.ext,
  });

  final String label;
  final String value;
  final TextTheme tt;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            ),
          ),
          Text(
            value,
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
