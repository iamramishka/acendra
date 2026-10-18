import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Note shown under the page. The watermark itself is burned into the
/// server-delivered file; this only discloses it (SRS FR-PDF-SEC-005/006).
class PdfWatermarkDisclosure extends StatelessWidget {
  const PdfWatermarkDisclosure({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        'This guide shows your name as a watermark on every page.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Single bottom bar: ‹ page / total › · − zoom % + · fit-to-width.
///
/// Scales down instead of scrolling when the viewport is very narrow.
class PdfReaderFooter extends StatelessWidget {
  const PdfReaderFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.zoom,
    required this.isFitWidth,
    this.onPrevious,
    this.onNext,
    this.onZoomIn,
    this.onZoomOut,
    this.onFitWidth,
  });

  final int currentPage;
  final int totalPages;
  final double zoom;
  final bool isFitWidth;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onFitWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    const density = VisualDensity.compact;

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: density,
                tooltip: 'Previous page',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Semantics(
                label: 'Page $currentPage of $totalPages',
                child: ExcludeSemantics(
                  child: Text('$currentPage / $totalPages', style: style),
                ),
              ),
              IconButton(
                visualDensity: density,
                tooltip: 'Next page',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                visualDensity: density,
                tooltip: 'Zoom out',
                onPressed: onZoomOut,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(zoom * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              IconButton(
                visualDensity: density,
                tooltip: 'Zoom in',
                onPressed: onZoomIn,
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                visualDensity: density,
                tooltip: 'Fit to width',
                isSelected: isFitWidth,
                onPressed: onFitWidth,
                icon: const Icon(Icons.fit_screen_outlined),
                selectedIcon: const Icon(Icons.fit_screen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
