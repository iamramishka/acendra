import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
import 'package:flutter/material.dart';

/// Lazy catalog sliver. Place directly in a CustomScrollView's slivers.
class CourseGrid extends StatelessWidget {
  const CourseGrid({
    super.key,
    required this.courses,
    this.categories = const [],
    this.onCourseTap,
  });
  final List<CourseSummary> courses;
  final List<Category> categories;
  final void Function(CourseSummary)? onCourseTap;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double textHeight(TextStyle? style, int lines) {
      final painter = TextPainter(
        text: TextSpan(text: List.filled(lines, 'Ag').join('\n'), style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    // Reserve bounded text lines rather than a fixed aspect ratio: enlarged
    // text needs taller cards even when the available column width is unchanged.
    final extent =
        160 + // Cover.
        32 + // Vertical padding.
        40 + // Text gaps and rounding allowance.
        textHeight(tt.labelMedium, 1) +
        textHeight(tt.titleLarge, 2) +
        textHeight(tt.bodyMedium, 3) +
        textHeight(tt.titleMedium, 2);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent < AppBreakpoints.compact
            ? 1
            : constraints.crossAxisExtent < AppBreakpoints.medium
            ? 2
            : 3;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: extent,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final matching = categories.where(
              (category) => category.id == course.categoryId,
            );
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onCourseTap == null ? null : () => onCourseTap!(course),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 160,
                      child: CourseThumbnail(
                        courseId: course.id,
                        title: course.title,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (matching.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      matching.first.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.labelMedium,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text(
                              course.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.shortDescription,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium,
                            ),
                            const Spacer(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course.formattedPrice,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.titleMedium,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
