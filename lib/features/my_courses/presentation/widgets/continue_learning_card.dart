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
    final tt = Theme.of(context).textTheme;

    final clampedProgress = progressPercent.clamp(0.0, 1.0);
    final percentLabel = '${(clampedProgress * 100).round()}% complete';

    return Semantics(
      label: 'Continue Learning: $courseTitle. $lessonTitle. $percentLabel.',
      button: false,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const RadialGradient(
            center: Alignment(0.7, -0.2),
            radius: 1.5,
            colors: [Color(0xFF1E6BFF), Color(0xFF123A9C), Color(0xFF0B1E4F)],
            stops: [0.0, 0.35, 0.75],
          ),
        ),
        clipBehavior: Clip.antiAlias,
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
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Course title
              Text(
                courseTitle,
                style: tt.titleMedium?.copyWith(
                  color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.65),
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF58D2F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                percentLabel,
                style: tt.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Resume button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B1E4F),
                  ),
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
