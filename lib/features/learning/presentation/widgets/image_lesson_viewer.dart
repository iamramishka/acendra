import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

class ImageLessonViewer extends StatelessWidget {
  const ImageLessonViewer({
    super.key,
    required this.title,
    required this.imageUrl,
    this.caption,
    this.semanticLabel,
    this.onNext,
    this.onPrevious,
  });

  final String title;

  /// Must be a pre-authorized signed URL obtained from the trusted backend.
  /// Never pass a permanently public storage URL.
  final String imageUrl;
  final String? caption;

  /// Accessible description of the image content. Falls back to [title].
  final String? semanticLabel;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    assert(imageUrl.isNotEmpty, 'imageUrl must not be empty');
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 480),
            child: Semantics(
              label: semanticLabel ?? title,
              image: true,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: cs.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Image could not be loaded',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (onPrevious != null || onNext != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrevious != null)
                  AppButton(
                    label: '← Previous',
                    onPressed: onPrevious,
                    variant: ButtonVariant.outlined,
                  )
                else
                  const SizedBox.shrink(),
                if (onNext != null)
                  AppButton(
                    label: 'Next →',
                    onPressed: onNext,
                    variant: ButtonVariant.primary,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
