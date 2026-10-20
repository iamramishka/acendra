import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Selectable filter chip for admin lists.
///
/// 44 px minimum tap target, keyboard focusable with a visible focus ring,
/// and announced to assistive tech as a selected/unselected button.
class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.chip);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Material(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            focusColor: cs.onSurface.withAlpha(41),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
