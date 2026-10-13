import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

class TextLessonViewer extends StatelessWidget {
  const TextLessonViewer({
    super.key,
    required this.title,
    required this.content,
    this.onNext,
    this.onPrevious,
  });

  final String title;
  final String content;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                content,
                style: tt.bodyLarge?.copyWith(height: 1.6, color: cs.onSurface),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
