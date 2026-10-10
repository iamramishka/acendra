import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

enum SnackbarVariant { info, success, warning, error }

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    SnackbarVariant variant = SnackbarVariant.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final (Color bg, Color fg) = switch (variant) {
      SnackbarVariant.success => (
          ext?.successContainer ?? cs.primaryContainer,
          ext?.success ?? cs.primary,
        ),
      SnackbarVariant.warning => (
          ext?.warningContainer ?? cs.secondaryContainer,
          ext?.warning ?? cs.secondary,
        ),
      SnackbarVariant.error => (cs.errorContainer, cs.onErrorContainer),
      SnackbarVariant.info => (cs.primaryContainer, cs.onPrimaryContainer),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
