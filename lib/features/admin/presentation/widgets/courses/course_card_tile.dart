import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:flutter/material.dart';

class CourseCardTile extends StatelessWidget {
  const CourseCardTile({
    super.key,
    required this.course,
    required this.onEdit,
    required this.onCurriculum,
    required this.onDelete,
  });

  final AdminCourse course;
  final VoidCallback onEdit;
  final VoidCallback onCurriculum;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: course.thumbnailUrl != null
                      ? Image.network(
                          course.thumbnailUrl!,
                          width: 64,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(cs),
                        )
                      : _placeholder(cs),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${course.currency} ${course.price.toStringAsFixed(0)}',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: course.isPublished ? 'Published' : 'Draft',
                  variant: course.isPublished ? BadgeVariant.success : BadgeVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${course.enrollmentCount} enrolled · ${course.sectionCount} sections · ${course.lessonCount} lessons',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Edit',
                  onPressed: onEdit,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Curriculum',
                  onPressed: onCurriculum,
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.small,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Delete',
                  onPressed: onDelete,
                  variant: ButtonVariant.destructive,
                  size: ButtonSize.small,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 64,
      height: 48,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, size: 24, color: cs.onSurfaceVariant),
    );
  }
}
