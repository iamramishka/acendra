import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/presentation/providers/my_courses_provider.dart';
import 'package:acendra/features/my_courses/presentation/widgets/continue_learning_card.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Personal top of Home (COM-015): greeting, resume card and owned courses.
/// Renders nothing until the student has enrolled courses, and never blocks
/// the rest of Home if loading fails.
class DashboardPersonalSection extends ConsumerWidget {
  const DashboardPersonalSection({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime? now;

  static String greetingFor(int hour) => hour < 12
      ? 'Good morning'
      : hour < 17
      ? 'Good afternoon'
      : 'Good evening';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(myCoursesProvider).asData?.value;
    if (courses == null || courses.isEmpty) return const SizedBox.shrink();

    final progress =
        ref.watch(courseProgressProvider).asData?.value ??
        const <String, CourseProgress>{};
    final name = ref.watch(displayNameProvider);
    final tt = Theme.of(context).textTheme;
    final greeting = greetingFor((now ?? DateTime.now()).hour);
    final resume = _resumeCourse(courses, progress);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name == null || name.trim().isEmpty ? greeting : '$greeting, $name',
            style: tt.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume != null)
            ContinueLearningCard(
              courseTitle: resume.$1.title,
              lessonTitle:
                  '${resume.$2.completedLessons} of ${resume.$2.totalLessons} '
                  'lessons completed',
              progressPercent: resume.$2.fraction,
              courseId: resume.$1.courseId,
              onContinue: () => context.go(resume.$2.resumePath),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: Text('My Courses', style: tt.titleMedium)),
              TextButton(
                onPressed: () => context.go(RouteNames.myCourses),
                child: const Text('View all'),
              ),
            ],
          ),
          for (final c in courses.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              title: Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: progress[c.courseId] == null
                  ? null
                  : Text('${progress[c.courseId]!.percent}% complete'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(
                progress[c.courseId]?.resumePath ?? '/learn/${c.courseId}',
              ),
            ),
        ],
      ),
    );
  }

  /// Most recently opened unfinished course.
  (EnrolledCourse, CourseProgress)? _resumeCourse(
    List<EnrolledCourse> courses,
    Map<String, CourseProgress> progress,
  ) {
    (EnrolledCourse, CourseProgress)? best;
    for (final c in courses) {
      final p = progress[c.courseId];
      if (p == null || p.isCompleted || !p.isStarted) continue;
      final opened = p.lastOpenedAt;
      final bestOpened = best?.$2.lastOpenedAt;
      if (best == null ||
          (opened != null &&
              (bestOpened == null || opened.isAfter(bestOpened)))) {
        best = (c, p);
      }
    }
    return best;
  }
}
