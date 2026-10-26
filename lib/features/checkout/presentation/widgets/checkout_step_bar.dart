import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Three-step progress indicator: Order, Payment, Confirm.
/// [currentIndex] is 0-based; earlier steps are shown as done.
class CheckoutStepBar extends StatelessWidget {
  const CheckoutStepBar({super.key, this.currentIndex = 1});

  static const _labels = ['Order', 'Payment', 'Confirm'];

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Divider(
                  height: 0,
                  thickness: 2,
                  color: i <= currentIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          Expanded(
            child: _Step(
              label: _labels[i],
              index: i,
              currentIndex: currentIndex,
            ),
          ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.currentIndex,
  });

  final String label;
  final int index;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = index < currentIndex;
    final current = index == currentIndex;
    final state = done ? 'done' : (current ? 'current' : 'upcoming');
    final active = done || current;

    return Semantics(
      label: '$label, step ${index + 1} of 3, $state',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: active ? cs.primary : cs.surfaceContainerHighest,
            child: done
                ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                : Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: current ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
