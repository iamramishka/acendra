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
/// Wraps control groups at narrow widths without shrinking touch targets.
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

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
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
                  tooltip: 'Next page',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: onZoomOut,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${(zoom * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: onZoomIn,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Fit to width',
              isSelected: isFitWidth,
              onPressed: onFitWidth,
              icon: const Icon(Icons.fit_screen_outlined),
              selectedIcon: const Icon(Icons.fit_screen),
            ),
          ],
        ),
      ),
    );
  }
}
