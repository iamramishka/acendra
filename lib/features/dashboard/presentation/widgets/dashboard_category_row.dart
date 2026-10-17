import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_category_chip.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:flutter/material.dart';

class DashboardCategoryRow extends StatelessWidget {
  const DashboardCategoryRow({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.onViewAll,
  });

  final List<DashboardCategory> categories;
  final ValueChanged<DashboardCategory>? onCategorySelected;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DashboardSectionHeader(
        title: DashboardCopy.categories,
        onViewAll: onViewAll,
      ),
      const SizedBox(height: AppSpacing.md),
      if (categories.isEmpty)
        const Text(DashboardCopy.noCategories)
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                DashboardCategoryChip(
                  category: categories[i],
                  onSelected: onCategorySelected,
                ),
              ],
            ],
          ),
        ),
    ],
  );
}
