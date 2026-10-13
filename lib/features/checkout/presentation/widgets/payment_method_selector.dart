import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: PaymentMethod.values
          .map(
            (method) => Padding(
              padding: EdgeInsets.only(
                bottom: method == PaymentMethod.values.last ? 0 : AppSpacing.sm,
              ),
              child: _PaymentMethodCard(
                method: method,
                isSelected: method == selected,
                onTap: () => onChanged(method),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor =
        isSelected ? colorScheme.primary : colorScheme.outline;
    final backgroundColor =
        isSelected ? colorScheme.primaryContainer : colorScheme.surface;
    final iconColor =
        isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    final labelColor =
        isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    return Semantics(
      selected: isSelected,
      button: true,
      label: method.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(method.icon, color: iconColor, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      method.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
