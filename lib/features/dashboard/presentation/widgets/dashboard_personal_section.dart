import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/dashboard/domain/entities/student_home.dart';
import 'package:acendra/features/dashboard/presentation/providers/student_home_provider.dart';
import 'package:acendra/features/dashboard/presentation/widgets/student_home_cards.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardPersonalSection extends ConsumerWidget {
  const DashboardPersonalSection({
    super.key,
    this.now,
    this.onExplore,
    this.onViewAll,
    this.onLessonSelected,
  });
  final DateTime? now;
  final VoidCallback? onExplore;
  final VoidCallback? onViewAll;
  final ValueChanged<String>? onLessonSelected;

  static String greetingFor(int hour) => hour < 12
      ? 'Good morning'
      : hour < 17
      ? 'Good afternoon'
      : 'Good evening';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final name = ref.watch(displayNameProvider)?.trim();
    final state = ref.watch(studentHomeProvider);
    void retry() => ref.invalidate(studentHomeProvider);
    void open(String path) =>
        onLessonSelected != null ? onLessonSelected!(path) : context.go(path);
    void explore() =>
        onExplore != null ? onExplore!() : context.go(RouteNames.marketplace);

    Widget message(String copy) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry learning details'),
          ),
        ],
      ),
    );

    Widget content(StudentHome home) {
      final resume = home.resume;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (home.courses.isEmpty) ...[
            const Text('You are not enrolled in any courses yet.'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: explore,
                child: const Text('Explore Courses'),
              ),
            ),
          ] else ...[
            if (resume != null) ...[
              StudentResumeCard(
                lesson: resume,
                progress: home.progress[resume.course.courseId]!,
                onResume: () => open(resume.path),
              ),
              const SizedBox(height: 24),
            ],
            if (home.progressUnavailable)
              message(
                'Saved progress is unavailable. Your courses are still listed.',
              ),
            Row(
              children: [
                Expanded(child: Text('My Courses', style: text.titleLarge)),
                TextButton(
                  onPressed:
                      onViewAll ?? () => context.go(RouteNames.myCourses),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    constraints.maxWidth >= 300 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 20.8;
                final width = twoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final course in home.courses.take(4))
                      SizedBox(
                        width: width,
                        child: StudentOwnedCourseCard(
                          course: course,
                          progress: home.progress[course.courseId],
                          onOpen: () => open(
                            home.nextLessons[course.courseId]?.path ??
                                '/learn/${course.courseId}',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Recently Accessed', style: text.titleLarge),
            const SizedBox(height: 12),
            if (home.recentUnavailable)
              message('Some recent learning details are unavailable.'),
            if (home.recent.isEmpty && !home.recentUnavailable)
              const Text('Lessons you open will appear here.'),
            for (final lesson in home.recent)
              StudentRecentLesson(
                lesson: lesson,
                onOpen: () => open(lesson.path),
              ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          greetingFor((now ?? DateTime.now()).hour),
          style: text.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name == null || name.isEmpty ? 'Welcome back' : 'Welcome back, $name',
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('Pick up where you left off.'),
        const SizedBox(height: 24),
        state.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading your learning',
              ),
            ),
          ),
          error: (_, _) =>
              message('Unable to load your courses. Please try again.'),
          data: content,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
