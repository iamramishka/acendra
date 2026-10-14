import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:flutter/material.dart';

import '../services/receipt_file_picker.dart'
    if (dart.library.js_interop) '../services/receipt_file_picker_web.dart'
    as picker;
import '../services/receipt_file.dart';

/// A form that allows a student to upload a new bank transfer receipt after
/// their previous one was rejected by the finance team.
///
/// Usage:
/// ```dart
/// ReceiptResubmissionForm(
///   orderId: 'order-123',
///   rejectionReason: 'Reference ID not visible in the uploaded image.',
/// )
/// ```
class ReceiptResubmissionForm extends StatefulWidget {
  const ReceiptResubmissionForm({
    super.key,
    required this.orderId,
    this.rejectionReason,
    this.filePicker,
  });

  /// The order for which the receipt is being resubmitted.
  final String orderId;

  /// The rejection reason provided by the finance team, if any.
  final String? rejectionReason;

  /// Injectable selection boundary for widget tests.
  final ReceiptFilePicker? filePicker;

  @override
  State<ReceiptResubmissionForm> createState() =>
      _ReceiptResubmissionFormState();
}

class _ReceiptResubmissionFormState extends State<ReceiptResubmissionForm> {
  String? _fileName;
  String? _fileError;
  bool _isPicking = false;

  Future<void> _pickFile() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final file = await (widget.filePicker ?? picker.pickReceiptFile)();
      if (!mounted || file == null) return;
      final error = receiptFileError(file.name, file.bytes.length);
      setState(() {
        _fileError = error;
        _fileName = error == null ? file.name : null;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _fileName = null;
        _fileError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _fileError = 'Could not read the receipt. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final borderColor = ext?.border ?? cs.outlineVariant;
    final surfaceSecondary = ext?.surfaceSecondary ?? cs.surfaceContainerLow;
    final textSecondary = ext?.textSecondary ?? cs.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header badge ──────────────────────────────────────────────────
            const StatusBadge(
              variant: BadgeVariant.error,
              label: 'Receipt Rejected',
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Rejection reason box ──────────────────────────────────────────
            if (widget.rejectionReason != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: cs.error.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: cs.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Reason for rejection',
                          style: tt.labelMedium?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.rejectionReason!,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Instruction text ──────────────────────────────────────────────
            Text(
              'Please upload a new receipt showing the bank transfer details. '
              'Make sure the reference ID is clearly visible.',
              style: tt.bodyMedium?.copyWith(color: textSecondary),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── File picker ───────────────────────────────────────────────────
            _FilePicker(
              fileName: _fileName,
              fileError: _fileError,
              borderColor: borderColor,
              surfaceSecondary: surfaceSecondary,
              onTap: _isPicking ? null : _pickFile,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Online receipt submission is temporarily unavailable. '
              'Selecting a file does not upload it. Please contact support '
              'with your order number; do not email receipt attachments.',
              style: tt.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Submit button ─────────────────────────────────────────────────
            const SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Submit New Receipt',
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                onPressed: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget: file picker tap target
// ---------------------------------------------------------------------------

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.fileName,
    required this.fileError,
    required this.borderColor,
    required this.surfaceSecondary,
    required this.onTap,
  });

  final String? fileName;
  final String? fileError;
  final Color borderColor;
  final Color surfaceSecondary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasFile = fileName != null;
    final hasError = fileError != null;

    return Semantics(
      label: 'Select receipt file',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasError
                  ? cs.error
                  : hasFile
                  ? cs.primary
                  : borderColor,
              width: hasFile ? 1.5 : 1.0,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFile
                    ? Icons.insert_drive_file_outlined
                    : Icons.upload_file_outlined,
                size: 32,
                color: hasFile ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (hasFile)
                Text(
                  fileName!,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Tap to select receipt image\n(JPG or PDF, max 5 MB)',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              if (hasError) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  fileError!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
