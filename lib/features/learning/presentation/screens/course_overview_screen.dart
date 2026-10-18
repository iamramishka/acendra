import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final courseProgressProvider = FutureProvider.autoDispose
    .family<List<SavedLessonProgress>, String>((ref, id) {
      final actor = ref.watch(currentSessionProvider)?.user.id;
      if (actor == null) throw StateError('Sign in required');
      return ref.watch(learningProgressRepositoryProvider).read(id);
    });

class CourseOverviewScreen extends ConsumerWidget {
  const CourseOverviewScreen({super.key, required this.courseId});
  final String courseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Course Overview'),
      leading: BackButton(onPressed: () => context.go(RouteNames.myCourses)),
    ),
    body: ref
        .watch(courseDetailProvider(courseId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(courseDetailProvider(courseId)),
              child: const Text('Retry course overview'),
            ),
          ),
          data: (course) {
            final enrollment = ref.watch(isEnrolledProvider(courseId));
            if (enrollment.isLoading)
              return const Center(child: CircularProgressIndicator());
            if (enrollment.asData?.value != true)
              return Center(
                child: TextButton(
                  onPressed: () => context.go(
                    RouteNames.courseDetail.replaceFirst(':courseId', courseId),
                  ),
                  child: const Text('View course access'),
                ),
              );
            final progress = ref.watch(courseProgressProvider(courseId));
            return progress.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(courseProgressProvider(courseId)),
                  child: const Text('Retry saved progress'),
                ),
              ),
              data: (saved) {
                final lessons = course.sections
                    .expand((s) => s.lessons)
                    .toList();
                final completed = saved
                    .where((p) => p.completed)
                    .map((p) => p.lessonId)
                    .toSet();
                final count = lessons
                    .where((l) => completed.contains(l.id))
                    .length;
                final ratio = lessons.isEmpty ? 0.0 : count / lessons.length;
                final remaining = lessons.where(
                  (l) => !completed.contains(l.id),
                );
                final next = remaining.isNotEmpty
                    ? remaining.first
                    : lessons.firstOrNull;
                void open(String lessonId) => context.push(
                  '${RouteNames.learn.replaceFirst(':courseId', Uri.encodeComponent(courseId))}?lesson=${Uri.encodeComponent(lessonId)}',
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const CourseArt(height: 200),
                        const SizedBox(height: 20),
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${course.sections.length} modules · ${lessons.length} lessons',
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Learning Progress',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${(ratio * 100).round()}% · $count of ${lessons.length} lessons completed',
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(value: ratio),
                                if (next != null) ...[
                                  const SizedBox(height: 16),
                                  Text(next.title),
                                  FilledButton(
                                    onPressed: () => open(next.id),
                                    child: Text(
                                      count == 0
                                          ? 'Start Lesson'
                                          : 'Resume Learning',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'Course Curriculum',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ...course.sections.map(
                          (section) => ExpansionTile(
                            title: Text(section.title),
                            children: section.lessons
                                .map(
                                  (lesson) => ListTile(
                                    leading: Icon(
                                      completed.contains(lesson.id)
                                          ? Icons.check_circle
                                          : Icons.play_circle_outline,
                                    ),
                                    title: Text(lesson.title),
                                    trailing: lesson.durationSeconds == null
                                        ? null
                                        : Text(
                                            '${(lesson.durationSeconds! / 60).ceil()} min',
                                          ),
                                    onTap: () => open(lesson.id),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
  );
}
