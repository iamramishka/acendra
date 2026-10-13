import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A prominent card that shows the "Continue Learning" CTA for a course.
///
/// Displays course title, current lesson title, a linear progress bar,
/// and a "Resume →" button that calls [onContinue].
class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.courseTitle,
    required this.lessonTitle,
    required this.progressPercent,
    required this.courseId,
    required this.onContinue,
  });

  /// The title of the enrolled course.
  final String courseTitle;

  /// The title of the lesson to resume.
  final String lessonTitle;

  /// Progress through the course, in the range [0, 1].
  final double progressPercent;

  /// Identifier for the course (reserved for external use or navigation).
  final String courseId;

  /// Callback invoked when the user taps "Resume →".
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final clampedProgress = progressPercent.clamp(0.0, 1.0);
    final percentLabel = '${(clampedProgress * 100).round()}% complete';

    return Semantics(
      label: 'Continue Learning: $courseTitle. $lessonTitle. $percentLabel.',
      button: false,
      child: Card(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header label
              Text(
                'Continue Learning',
                style: tt.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Course title
              Text(
                courseTitle,
                style: tt.titleMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              // Lesson title
              Text(
                lessonTitle,
                style: tt.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer.withAlpha(180),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              // Progress bar
              Semantics(
                label: percentLabel,
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    minHeight: 6,
                    backgroundColor: cs.onPrimaryContainer.withAlpha(40),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                percentLabel,
                style: tt.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer.withAlpha(180),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Resume button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
