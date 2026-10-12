import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/curriculum_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(courseDetailProvider(courseId));
    final enrollState = ref.watch(isEnrolledProvider(courseId));

    return detailState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: AppErrorState(
          message: 'Failed to load course details.',
          actionLabel: 'Retry',
          onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
        ),
      ),
      data: (detail) {
        final isEnrolled = enrollState.asData?.value ?? false;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: Text(detail.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price + enrollment badge row
                Row(
                  children: [
                    Text(
                      detail.formattedPrice,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isEnrolled)
                      Chip(
                        label: const Text('Enrolled'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        avatar: const Icon(Icons.check_circle_outline,
                            size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Short description
                Text(
                  detail.shortDescription,
                  style: theme.textTheme.bodyLarge,
                ),

                // Full description
                if (detail.description != null &&
                    detail.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(detail.description!),
                ],

                const SizedBox(height: 24),

                // Stats row
                Wrap(
                  spacing: 16,
                  children: [
                    _StatChip(
                      icon: Icons.library_books_outlined,
                      label: '${detail.sections.length} section'
                          '${detail.sections.length == 1 ? '' : 's'}',
                    ),
                    _StatChip(
                      icon: Icons.play_lesson_outlined,
                      label: '${detail.totalLessons} lesson'
                          '${detail.totalLessons == 1 ? '' : 's'}',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: isEnrolled ? 'Continue Learning' : 'Enroll Now',
                    onPressed: isEnrolled ? () {} : () {},
                  ),
                ),

                const SizedBox(height: 32),

                // Curriculum preview
                Text(
                  'Curriculum',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CurriculumPreview(sections: detail.sections),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
