import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
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
    final progressState = ref.watch(courseProgressProvider);
    // Do not present stale progress or apply stale filters during a retry.
    final progress = progressState.isLoading || progressState.hasError
        ? const <String, CourseProgress>{}
        : progressState.asData?.value ?? const <String, CourseProgress>{};

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
          final completeSummary = courses.every(
            (c) => progress.containsKey(c.courseId),
          );
          final activeFilter = completeSummary ? _filter : ProgressFilter.all;
          final shown = courses.where((c) {
            final p = progress[c.courseId];
            // Without progress data only "All" can be answered honestly.
            return activeFilter == ProgressFilter.all ||
                (p != null && p.matches(activeFilter));
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your learning library',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              if (progressState.isLoading)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Semantics(
                    liveRegion: true,
                    child: const Text('Loading your progress…'),
                  ),
                )
              else if (progressState.hasError || !completeSummary)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progressState.hasError
                                  ? "Couldn't load your progress. You can still open your courses."
                                  : 'Progress unavailable for some courses. You can still open them.',
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  ref.invalidate(courseProgressProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry progress'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (completeSummary)
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
                            selected: f == activeFilter,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = textScale > 1.3
            ? 1
            : _columnCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 400 * textScale.clamp(1, double.infinity),
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _CourseTile(
              course: course,
              progress: progress[course.courseId],
            );
          },
        );
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
    void openOverview() =>
        context.go('/learn/${Uri.encodeComponent(course.courseId)}');
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
        onTap: openOverview,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 140,
                child: CourseThumbnail(
                  courseId: course.courseId,
                  title: course.title,
                  imageUrl: course.thumbnailUrl,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
                child: FilledButton(
                  onPressed: openOverview,
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
