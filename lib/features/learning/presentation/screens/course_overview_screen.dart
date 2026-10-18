import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/learning/presentation/providers/course_overview_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Course-level progress and curriculum (COM-017). Opens lessons in the
/// workspace at `/learn/:courseId/:lessonId`.
class CourseOverviewScreen extends ConsumerWidget {
  const CourseOverviewScreen({super.key, required this.courseId});

  final String courseId;

  void _open(BuildContext context, String lessonId) =>
      context.go('/learn/$courseId/$lessonId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(courseOverviewProvider(courseId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AppSkeleton(height: 120, semanticLabel: 'Loading course'),
      ),
      error: (_, _) => AppErrorState(
        message: 'Could not load course content.',
        actionLabel: 'Retry',
        onRetry: () => ref.invalidate(courseOverviewProvider(courseId)),
      ),
      data: (summary) {
        if (summary.totalLessons == 0) {
          return const AppEmptyState(message: 'No lessons available yet.');
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${summary.sections.length} modules · '
                      '${summary.totalLessons} lessons',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProgressCard(summary: summary),
                    const SizedBox(height: AppSpacing.md),
                    _ContinueCard(
                      summary: summary,
                      onOpen: (id) => _open(context, id),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Course Curriculum',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final section in summary.sections)
                      _ModuleTile(
                        section: section,
                        summary: summary,
                        onOpen: (id) => _open(context, id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary});
  final CourseProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Semantics(
          label:
              'Your learning progress, ${summary.percent} percent, '
              '${summary.completedLessons} of ${summary.totalLessons} '
              'lessons completed',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Learning Progress', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('${summary.percent}%', style: tt.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(value: summary.percent / 100),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${summary.completedLessons} of ${summary.totalLessons} '
                'lessons completed',
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.summary, required this.onOpen});
  final CourseProgressSummary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final next = summary.nextLesson;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: next == null
            ? Text('Course completed', style: tt.titleSmall)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Continue learning', style: tt.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(next.title, style: tt.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => onOpen(next.id),
                    child: Text(summary.hasStarted ? 'Resume' : 'Start Lesson'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.section,
    required this.summary,
    required this.onOpen,
  });
  final CurriculumSection section;
  final CourseProgressSummary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = summary.sectionStatus(section.id);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: status == SectionStatus.current,
        leading: Icon(
          status == SectionStatus.completed
              ? Icons.check_circle
              : status == SectionStatus.current
              ? Icons.timelapse
              : Icons.radio_button_unchecked,
          color: status == SectionStatus.todo ? cs.outline : cs.primary,
        ),
        title: Text('${section.position}. ${section.title}'),
        subtitle: status == SectionStatus.completed
            ? const Text('Completed')
            : null,
        children: [
          for (final lesson in section.lessons)
            ListTile(
              dense: true,
              leading: Icon(
                summary.isCompleted(lesson.id)
                    ? Icons.check_circle
                    : lesson.id == summary.nextLesson?.id
                    ? Icons.play_circle_fill
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              title: Text(lesson.title),
              subtitle: lesson.id == summary.nextLesson?.id
                  ? const Text('In Progress')
                  : null,
              trailing: Text(lesson.typeLabel),
              onTap: () => onOpen(lesson.id),
            ),
        ],
      ),
    );
  }
}
