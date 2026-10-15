import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:flutter/material.dart';

class CourseTableRow extends StatelessWidget {
  const CourseTableRow({
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

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _ThumbnailPlaceholder(thumbnailUrl: course.thumbnailUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${course.enrollmentCount}',
              style: tt.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          StatusBadge(
            label: course.isPublished ? 'Published' : 'Draft',
            variant: course.isPublished ? BadgeVariant.success : BadgeVariant.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
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
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({this.thumbnailUrl});
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: thumbnailUrl != null
          ? Image.network(
              thumbnailUrl!,
              width: 56,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(cs),
            )
          : _placeholder(cs),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 56,
      height: 40,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, size: 20, color: cs.onSurfaceVariant),
    );
  }
}
