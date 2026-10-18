import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:flutter/material.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.showViewAll = true,
  });

  final String title;
  final VoidCallback? onViewAll;
  final bool showViewAll;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (showViewAll)
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward),
          iconAlignment: IconAlignment.end,
          label: const Text(DashboardCopy.viewAll),
        ),
    ],
  );
}
