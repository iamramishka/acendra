import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/dashboard/domain/entities/why_learn_item.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:flutter/material.dart';

class DashboardWhyLearnSection extends StatelessWidget {
  const DashboardWhyLearnSection({super.key, required this.items});

  final List<WhyLearnItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: DashboardCopy.whyLearn,
          showViewAll: false,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const Text(DashboardCopy.noHighlights)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < AppBreakpoints.compact
                  ? 1
                  : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.lg) /
                  columns;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            child: Icon(switch (item.icon) {
                              WhyLearnIcon.flexibleLearning =>
                                Icons.schedule_outlined,
                              WhyLearnIcon.practicalSkills =>
                                Icons.auto_awesome_outlined,
                              WhyLearnIcon.learningMaterials =>
                                Icons.menu_book_outlined,
                              WhyLearnIcon.progress => Icons.trending_up,
                            }),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  item.subtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
