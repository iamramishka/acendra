import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter/material.dart';

class CourseGrid extends StatelessWidget {
  const CourseGrid({super.key, required this.courses, this.onCourseTap});

  final List<CourseSummary> courses;
  final void Function(CourseSummary)? onCourseTap;

  int _columnCount(double width) {
    if (width < AppBreakpoints.compact) return 1;
    if (width < AppBreakpoints.medium) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = _columnCount(width);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          title: course.title,
          price: course.formattedPrice,
          onTap: onCourseTap != null ? () => onCourseTap!(course) : null,
        );
      },
    );
  }
}
