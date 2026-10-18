import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseGrid extends ConsumerWidget {
  const CourseGrid({super.key, required this.courses, this.onCourseTap});
  final List<CourseSummary> courses;
  final void Function(CourseSummary)? onCourseTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    final tt = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 1024
            ? 2
            : 3;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: courses.map((course) {
            final matching = categories.where(
              (category) => category.id == course.categoryId,
            );
            return SizedBox(
              width: width,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onCourseTap == null
                      ? null
                      : () => onCourseTap!(course),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CourseArt(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (matching.isNotEmpty)
                              Text(matching.first.name, style: tt.labelMedium),
                            const SizedBox(height: 8),
                            Text(course.title, style: tt.titleLarge),
                            const SizedBox(height: 8),
                            Text(course.shortDescription, style: tt.bodyMedium),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course.formattedPrice,
                                    style: tt.titleMedium,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
