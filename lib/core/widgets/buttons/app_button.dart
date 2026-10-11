import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, outlined, destructive }

enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final minHeight = switch (size) {
      ButtonSize.small => 36.0,
      ButtonSize.medium => 44.0,
      ButtonSize.large => 48.0,
    };

    final hPad = switch (size) {
      ButtonSize.small => AppSpacing.md,
      ButtonSize.medium => AppSpacing.lg,
      ButtonSize.large => AppSpacing.xl,
    };

    final vPad = switch (size) {
      ButtonSize.small => AppSpacing.xs + 2,
      ButtonSize.medium => AppSpacing.sm + 2,
      ButtonSize.large => AppSpacing.md - 2,
    };

    final (
      Color bgColor,
      Color fgColor,
      Color? borderColor,
    ) = switch (variant) {
      ButtonVariant.primary => (cs.primary, cs.onPrimary, null),
      ButtonVariant.secondary => (
        cs.primaryContainer,
        cs.onPrimaryContainer,
        null,
      ),
      ButtonVariant.outlined => (Colors.transparent, cs.primary, cs.primary),
      ButtonVariant.destructive => (cs.error, cs.onError, null),
    };

    final effectiveOnPressed = (isLoading || onPressed == null)
        ? null
        : onPressed;

    final content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon!,
              const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          )
        : Text(label);

    return Semantics(
      label: isLoading ? '$label, loading' : null,
      button: true,
      enabled: effectiveOnPressed != null,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          minimumSize: Size(0, minHeight),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: content,
      ),
    );
  }
}
