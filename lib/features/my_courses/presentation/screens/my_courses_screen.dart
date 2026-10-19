import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/presentation/providers/my_courses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  ProgressFilter _filter = ProgressFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCoursesProvider);
    final progress =
        ref.watch(courseProgressProvider).asData?.value ??
        const <String, CourseProgress>{};

    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: 'Failed to load your courses. Please try again.',
          actionLabel: 'Retry',
          onRetry: () => ref.read(myCoursesProvider.notifier).refresh(),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return AppEmptyState(
              message: 'You have not enrolled in any courses yet.',
              actionLabel: 'Browse courses',
              onAction: () => context.go('/marketplace'),
            );
          }
          final shown = courses.where((c) {
            final p = progress[c.courseId];
            // Without progress data only "All" can be answered honestly.
            return _filter == ProgressFilter.all ||
                (p != null && p.matches(_filter));
          }).toList();
          return Column(
            children: [
              if (progress.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final f in ProgressFilter.values)
                          ChoiceChip(
                            label: Text(_label(f)),
                            selected: f == _filter,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: shown.isEmpty
                    ? AppEmptyState(
                        message: 'No courses in this view.',
                        actionLabel: 'Explore courses',
                        onAction: () => context.go('/marketplace'),
                      )
                    : _CourseGrid(courses: shown, progress: progress),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _label(ProgressFilter f) => switch (f) {
    ProgressFilter.all => 'All',
    ProgressFilter.inProgress => 'In Progress',
    ProgressFilter.notStarted => 'Not Started',
    ProgressFilter.completed => 'Completed',
  };
}

class _CourseGrid extends StatelessWidget {
  const _CourseGrid({required this.courses, required this.progress});

  final List<EnrolledCourse> courses;
  final Map<String, CourseProgress> progress;

  int _columnCount(double width) {
    if (width >= AppBreakpoints.medium) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columnCount(MediaQuery.sizeOf(context).width);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 208,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _CourseTile(course: course, progress: progress[course.courseId]);
      },
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course, required this.progress});

  final EnrolledCourse course;
  final CourseProgress? progress;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = progress;
    final label = p == null
        ? 'Open Course'
        : p.isCompleted
        ? 'Review Course'
        : p.isStarted
        ? 'Continue Learning'
        : 'Start Learning';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(p?.resumePath ?? '/learn/${course.courseId}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: tt.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                course.shortDescription,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (p != null) ...[
                Text(
                  '${p.completedLessons} of ${p.totalLessons} lessons completed'
                  ' • ${p.percent}%',
                  style: tt.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(value: p.fraction, minHeight: 6),
                const SizedBox(height: AppSpacing.sm),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: tt.labelLarge?.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
