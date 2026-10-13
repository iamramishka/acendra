import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/presentation/providers/my_courses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myCoursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/marketplace'),
        icon: const Icon(Icons.explore_outlined),
        label: const Text('Explore Courses'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: 'Failed to load your courses. Please try again.',
          actionLabel: 'Retry',
          onRetry: () => ref.read(myCoursesProvider.notifier).refresh(),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const AppEmptyState(
              message: 'You have not enrolled in any courses yet.',
            );
          }
          return _CourseGrid(courses: courses);
        },
      ),
    );
  }
}

class _CourseGrid extends StatelessWidget {
  const _CourseGrid({required this.courses});

  final List<EnrolledCourse> courses;

  int _columnCount(double width) {
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = _columnCount(width);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          title: course.title,
          instructorName: course.shortDescription,
          price: 'Enrolled',
          imageUrl: course.thumbnailUrl,
          onTap: () => context.go('/learn/${course.courseId}'),
        );
      },
    );
  }
}
