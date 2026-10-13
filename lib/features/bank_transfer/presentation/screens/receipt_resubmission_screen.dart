import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CSA-115 — Receipt resubmission screen.
///
/// Allows a student to submit a new receipt after their previous one was
/// rejected. The backend upload endpoint is hard-disabled (503); this screen
/// shows a graceful "temporarily unavailable" message and never implies
/// that uploading a receipt grants course access.
class ReceiptResubmissionScreen extends ConsumerStatefulWidget {
  const ReceiptResubmissionScreen({
    super.key,
    required this.orderId,
    this.rejectionReason,
  });

  final String orderId;
  final String? rejectionReason;

  @override
  ConsumerState<ReceiptResubmissionScreen> createState() =>
      _ReceiptResubmissionScreenState();
}

class _ReceiptResubmissionScreenState
    extends ConsumerState<ReceiptResubmissionScreen> {
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(receiptUploadProvider);
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (uploadState is AsyncData && _selectedFileName != null) {
      return _SuccessBody(tt: tt, ext: ext);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resubmit Receipt'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Submit a New Receipt',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Upload your bank transfer confirmation to re-start verification.',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                ),

                if (widget.rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Previous rejection reason',
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.rejectionReason!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // ── File picker area ──────────────────────────────────────
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: ext.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: _selectedFileName != null
                            ? cs.primary
                            : ext.border,
                        width: _selectedFileName != null ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFileName != null
                              ? Icons.check_circle_outline
                              : Icons.upload_file_outlined,
                          size: 40,
                          color: _selectedFileName != null
                              ? cs.primary
                              : ext.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _selectedFileName ?? 'Tap to select file',
                          style: tt.bodyMedium?.copyWith(
                            color: _selectedFileName != null
                                ? cs.primary
                                : ext.textSecondary,
                            fontWeight: _selectedFileName != null
                                ? FontWeight.w600
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFileName == null)
                          Text(
                            'JPG, PNG or PDF — max 5 MB',
                            style: tt.bodySmall?.copyWith(
                              color: ext.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Backend-disabled notice ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: ext.warningContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: ext.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: ext.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Online receipt submission is temporarily unavailable. '
                          'Please email your receipt to support with your order number.',
                          style: tt.bodySmall?.copyWith(
                            color: ext.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (uploadState is AsyncError) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      uploadState.error.toString(),
                      style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: uploadState is AsyncLoading
                      ? 'Uploading…'
                      : 'Submit Receipt',
                  onPressed:
                      uploadState is AsyncLoading || _selectedFileName == null
                      ? null
                      : _submit,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickFile() {
    setState(() => _selectedFileName = 'receipt.pdf');
  }

  void _submit() {
    ref
        .read(receiptUploadProvider.notifier)
        .upload(
          orderId: widget.orderId,
          fileName: _selectedFileName ?? 'receipt.pdf',
          bytes: const [],
        );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.tt, required this.ext});
  final TextTheme tt;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resubmit Receipt')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: ext.success),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Receipt Submitted',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your new receipt has been submitted. '
                'We\'ll verify your payment and update you within 1–2 business days.',
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
