import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_course_card.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter/material.dart';

class DashboardFeaturedCoursesGrid extends StatelessWidget {
  const DashboardFeaturedCoursesGrid({
    super.key,
    required this.courses,
    this.categoryNames = const {},
    this.onCourseSelected,
    this.onViewAll,
  });

  final List<CourseSummary> courses;
  final Map<String, String> categoryNames;
  final ValueChanged<CourseSummary>? onCourseSelected;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DashboardSectionHeader(
        title: DashboardCopy.featured,
        onViewAll: onViewAll,
      ),
      const SizedBox(height: AppSpacing.md),
      if (courses.isEmpty)
        const Text(DashboardCopy.noCourses)
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < AppBreakpoints.compact
                ? 1
                : constraints.maxWidth < AppBreakpoints.medium
                ? 2
                : 3;
            final width =
                (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                columns;
            // Natural card heights accommodate large text without clipping.
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final course in courses)
                  SizedBox(
                    width: width,
                    child: DashboardCourseCard(
                      course: course,
                      categoryName: categoryNames[course.categoryId] ?? '',
                      onSelected: onCourseSelected,
                    ),
                  ),
              ],
            );
          },
        ),
    ],
  );
}
