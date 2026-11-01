import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:flutter/material.dart';

class DashboardCategoryChip extends StatelessWidget {
  const DashboardCategoryChip({
    super.key,
    required this.category,
    this.onSelected,
  });

  final DashboardCategory category;
  final ValueChanged<DashboardCategory>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (category.icon) {
      DashboardCategoryIcon.development => Icons.code,
      DashboardCategoryIcon.design => Icons.palette_outlined,
      DashboardCategoryIcon.business => Icons.business_center_outlined,
      DashboardCategoryIcon.languages => Icons.language,
      DashboardCategoryIcon.general => Icons.menu_book_outlined,
    };
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.outline),
        minimumSize: const Size(48, 48),
      ),
      onPressed: onSelected == null ? null : () => onSelected!(category),
      icon: Icon(icon),
      label: Text(category.name),
    );
  }
}
