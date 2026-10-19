import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:flutter/material.dart';
import 'admin_course_thumbnail.dart';

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
                  child: SizedBox(
                    width: 64,
                    height: 48,
                    child: AdminCourseThumbnail(
                      courseId: course.id,
                      isPublished: course.isPublished,
                      title: course.title,
                      imageUrl: course.thumbnailUrl,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${course.currency} ${course.priceText}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: course.isPublished ? 'Published' : 'Draft',
                  variant: course.isPublished
                      ? BadgeVariant.success
                      : BadgeVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${course.enrollmentCount} enrolled · ${course.sectionCount} sections · ${course.lessonCount} lessons',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: 'Edit',
                  onPressed: onEdit,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                ),
                AppButton(
                  label: 'Curriculum',
                  onPressed: onCurriculum,
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.small,
                ),
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
}
