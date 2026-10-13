import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional import for web file picking.
// On non-web platforms this stub is used; on web the real implementation is
// wired up at runtime via `_pickFileWeb`.
// TODO: wire up actual file picker using dart:html on web.

/// Maximum allowed file size in bytes (5 MB).
const int _kMaxFileSizeBytes = 5 * 1024 * 1024;

/// Accepted MIME types / extensions for receipt uploads.
const List<String> _kAcceptedExtensions = ['jpg', 'jpeg', 'pdf'];

/// A form that allows a student to upload a new bank transfer receipt after
/// their previous one was rejected by the finance team.
///
/// Usage:
/// ```dart
/// ReceiptResubmissionForm(
///   orderId: 'order-123',
///   rejectionReason: 'Reference ID not visible in the uploaded image.',
///   onSubmitted: () { /* navigate away or refresh */ },
/// )
/// ```
class ReceiptResubmissionForm extends StatefulWidget {
  const ReceiptResubmissionForm({
    super.key,
    required this.orderId,
    this.rejectionReason,
    this.onSubmitted,
  });

  /// The order for which the receipt is being resubmitted.
  final String orderId;

  /// The rejection reason provided by the finance team, if any.
  final String? rejectionReason;

  /// Called after a successful mock submission.
  final VoidCallback? onSubmitted;

  @override
  State<ReceiptResubmissionForm> createState() =>
      _ReceiptResubmissionFormState();
}

class _ReceiptResubmissionFormState extends State<ReceiptResubmissionForm> {
  /// Selected file bytes (null until a file is chosen).
  Uint8List? _fileBytes;

  /// Display name of the selected file.
  String? _fileName;

  /// Inline validation error message for the selected file.
  String? _fileError;

  /// Whether the upload/submit is in progress.
  bool _isSubmitting = false;

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // File picking
  // ---------------------------------------------------------------------------

  /// Simulates picking a file on non-web platforms for testing purposes.
  /// On web, this delegates to [_pickFileWeb].
  Future<void> _pickFile() async {
    if (kIsWeb) {
      await _pickFileWeb();
    } else {
      // Non-web: simulate picking for tests / non-web debug builds.
      // In a real native build, integrate file_picker package here.
      // TODO: wire up actual file picker for non-web platforms.
      _applyMockFile(
        Uint8List(0),
        'mock_receipt.jpg',
        overrideForTest: true,
      );
    }
  }

  /// Picks a file using the browser's file input element.
  /// TODO: wire up actual file picker using dart:html on web.
  Future<void> _pickFileWeb() async {
    // Platform-specific implementation is deferred to CSA-108 integration.
    // For now, show a snackbar indicating the action is pending.
    if (!mounted) return;
    AppSnackbar.show(
      context,
      'File picker integration pending (CSA-108).',
    );
  }

  /// Applies the given file bytes and name, validating type and size.
  void _applyMockFile(
    Uint8List bytes,
    String filename, {
    bool overrideForTest = false,
  }) {
    final ext = filename.split('.').last.toLowerCase();
    final isValidType = _kAcceptedExtensions.contains(ext);
    final isValidSize = bytes.length <= _kMaxFileSizeBytes || overrideForTest;

    setState(() {
      if (!isValidType) {
        _fileBytes = null;
        _fileName = null;
        _fileError = 'Only JPG and PDF files are accepted.';
        return;
      }
      if (!isValidSize) {
        _fileBytes = null;
        _fileName = null;
        _fileError =
            'File is too large. Maximum size is 5 MB. '
            'Selected file: ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB.';
        return;
      }
      _fileBytes = bytes;
      _fileName = filename;
      _fileError = null;
    });
  }

  /// Validates file metadata without real bytes (used in widget tests).
  @visibleForTesting
  void simulateFilePick({
    required String filename,
    required int sizeBytes,
  }) {
    final ext = filename.split('.').last.toLowerCase();
    final isValidType = _kAcceptedExtensions.contains(ext);
    final isValidSize = sizeBytes <= _kMaxFileSizeBytes;

    setState(() {
      if (!isValidType) {
        _fileBytes = null;
        _fileName = null;
        _fileError = 'Only JPG and PDF files are accepted.';
        return;
      }
      if (!isValidSize) {
        _fileBytes = null;
        _fileName = null;
        _fileError =
            'File is too large. Maximum size is 5 MB. '
            'Selected file: ${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB.';
        return;
      }
      // Use empty bytes to satisfy non-null check without needing real data.
      _fileBytes = Uint8List(sizeBytes > 0 ? 1 : 0);
      _fileName = filename;
      _fileError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  /// Stub upload call.
  /// TODO: Replace with real call to Supabase receipt upload Edge Function (CSA-108).
  /// The function validates file type, size, and ownership before storing privately.
  Future<void> _uploadReceipt(Uint8List bytes, String filename) async {
    await Future.delayed(const Duration(seconds: 1)); // mock
  }

  Future<void> _submit() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _uploadReceipt(_fileBytes!, _fileName!);

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Receipt submitted successfully. The finance team will review it.',
        variant: SnackbarVariant.success,
      );

      widget.onSubmitted?.call();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        'Submission failed. Please try again.',
        variant: SnackbarVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
              onTap: _pickFile,
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Optional note ─────────────────────────────────────────────────
            AppTextField(
              label: 'Note to finance team (optional)',
              hint: 'e.g. Transfer reference shown on page 2',
              controller: _noteController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _noteController,
                  builder: (_, value, child) => Text(
                    '${value.text.length}/200',
                    style: tt.labelSmall?.copyWith(color: textSecondary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Submit button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Submit New Receipt',
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                isLoading: _isSubmitting,
                onPressed: _fileBytes != null ? _submit : null,
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
  final VoidCallback onTap;

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
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
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
