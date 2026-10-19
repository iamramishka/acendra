import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'course_thumbnail.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.title,
    this.instructorName,
    required this.price,
    this.imageUrl,
    this.courseId,
    this.rating,
    this.reviewCount,
    this.onTap,
  });

  final String? courseId;
  final String title;
  final String? instructorName;
  final String price;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;

  String _semanticLabel() =>
      instructorName != null && instructorName!.isNotEmpty
      ? '$title. By $instructorName. $price'
      : '$title. $price';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: _semanticLabel(),
      excludeSemantics: false,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CourseThumbnail(
                  title: title,
                  imageUrl: imageUrl,
                  courseId: courseId,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (instructorName != null &&
                        instructorName!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        instructorName!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFF4BF70),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: tt.labelSmall,
                          ),
                          if (reviewCount != null)
                            Text(
                              ' ($reviewCount)',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      price,
                      style: tt.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
