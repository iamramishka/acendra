import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

enum BadgeVariant { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.variant});
  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>();

    final (Color bg, Color fg) = switch (variant) {
      BadgeVariant.success => (
        ext?.successContainer ?? cs.primaryContainer,
        ext?.success ?? cs.primary,
      ),
      BadgeVariant.warning => (
        ext?.warningContainer ?? cs.secondaryContainer,
        ext?.warning ?? cs.secondary,
      ),
      BadgeVariant.error => (cs.errorContainer, cs.onErrorContainer),
      BadgeVariant.info => (cs.primaryContainer, cs.onPrimaryContainer),
    };

    final variantLabel = switch (variant) {
      BadgeVariant.success => 'Success',
      BadgeVariant.warning => 'Warning',
      BadgeVariant.error => 'Error',
      BadgeVariant.info => 'Info',
    };

    return Semantics(
      label: '$variantLabel: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: ExcludeSemantics(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
