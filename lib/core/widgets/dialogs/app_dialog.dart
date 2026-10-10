import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

abstract final class AppDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    ButtonVariant confirmVariant = ButtonVariant.primary,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          AppButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: ButtonVariant.outlined,
            size: ButtonSize.small,
          ),
          AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: confirmVariant,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }
}
