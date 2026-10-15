import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/pdf_reader/domain/entities/pdf_document.dart'
    as domain;
import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_bookmarks_panel.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_error_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_loading_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_page_navigation.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_search_bar.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_zoom_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

/// Responsive PDF reader widget.
///
/// - Compact  (<600 px)  : full-screen reader with bottom toolbar
/// - Medium   (600–1023) : reader with side-rail navigation
/// - Expanded (≥1024 px) : centred reader (max 900 px) with bottom toolbar
class PdfReaderWidget extends ConsumerStatefulWidget {
  const PdfReaderWidget({super.key, required this.document});

  final domain.PdfDocument document;

  @override
  ConsumerState<PdfReaderWidget> createState() => _PdfReaderWidgetState();
}

class _PdfReaderWidgetState extends ConsumerState<PdfReaderWidget> {
  late final TransformationController _zoomController;

  @override
  void initState() {
    super.initState();
    _zoomController = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfReaderProvider.notifier).open(widget.document.url);
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfReaderProvider);
    final notifier = ref.read(pdfReaderProvider.notifier);

    ref.listen<double>(pdfReaderProvider.select((s) => s.zoom), (_, next) {
      final currentScale = _zoomController.value.getMaxScaleOnAxis();
      if ((currentScale - next).abs() > 0.001) {
        _zoomController.value = Matrix4.diagonal3Values(next, next, next);
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < AppBreakpoints.compact) {
          return _CompactLayout(
            state: state,
            notifier: notifier,
            documentUrl: widget.document.url,
            transformController: _zoomController,
          );
        } else if (width < AppBreakpoints.medium) {
          return _MediumLayout(
            state: state,
            notifier: notifier,
            documentUrl: widget.document.url,
            transformController: _zoomController,
          );
        } else {
          return _ExpandedLayout(
            state: state,
            notifier: notifier,
            documentUrl: widget.document.url,
            transformController: _zoomController,
          );
        }
      },
    );
  }
}

// ── Compact layout ────────────────────────────────────────────────────────────

class _CompactLayout extends ConsumerWidget {
  const _CompactLayout({
    required this.state,
    required this.notifier,
    required this.documentUrl,
    required this.transformController,
  });

  final PdfReaderState state;
  final PdfReaderNotifier notifier;
  final String documentUrl;
  final TransformationController transformController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfController = ref.watch(pdfControllerProvider);

    return SafeArea(
      bottom: true,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _PdfViewArea(
                  state: state,
                  pdfController: pdfController,
                  notifier: notifier,
                  documentUrl: documentUrl,
                  transformController: transformController,
                ),
              ),
              _BottomToolbar(state: state, notifier: notifier),
            ],
          ),
          if (state.showBookmarks)
            Positioned.fill(
              child: _BookmarksOverlay(state: state, notifier: notifier),
            ),
        ],
      ),
    );
  }
}

// ── Medium layout ─────────────────────────────────────────────────────────────

class _MediumLayout extends ConsumerWidget {
  const _MediumLayout({
    required this.state,
    required this.notifier,
    required this.documentUrl,
    required this.transformController,
  });

  final PdfReaderState state;
  final PdfReaderNotifier notifier;
  final String documentUrl;
  final TransformationController transformController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfController = ref.watch(pdfControllerProvider);
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return SafeArea(
      bottom: true,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _PdfViewArea(
                        state: state,
                        pdfController: pdfController,
                        notifier: notifier,
                        documentUrl: documentUrl,
                        transformController: transformController,
                      ),
                    ),
                    Container(
                      width: 72,
                      color: ext.surfaceSecondary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Previous page',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up),
                              onPressed: state.currentPage > 1
                                  ? notifier.previousPage
                                  : null,
                              tooltip: 'Previous page',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Page-jump chip — tap to show go-to-page dialog.
                          Semantics(
                            label:
                                'Page ${state.currentPage} of ${state.totalPages}. Tap to jump to page.',
                            button: true,
                            child: GestureDetector(
                              onTap: state.status == PdfReaderStatus.ready
                                  ? () => _showPageJumpDialog(context)
                                  : null,
                              child: Column(
                                children: [
                                  Text(
                                    '${state.currentPage}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  Text(
                                    '/ ${state.totalPages}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: ext.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Semantics(
                            label: 'Next page',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onPressed: state.currentPage < state.totalPages
                                  ? notifier.nextPage
                                  : null,
                              tooltip: 'Next page',
                            ),
                          ),
                          const Spacer(),
                          // Bookmark toggle in side-rail
                          Semantics(
                            label: state.isBookmarked(state.currentPage)
                                ? 'Remove bookmark'
                                : 'Add bookmark',
                            button: true,
                            child: IconButton(
                              icon: Icon(
                                state.isBookmarked(state.currentPage)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              tooltip: state.isBookmarked(state.currentPage)
                                  ? 'Remove bookmark'
                                  : 'Add bookmark',
                              onPressed: () =>
                                  notifier.toggleBookmark(state.currentPage),
                            ),
                          ),
                          Semantics(
                            label: 'Show bookmarks list',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.list),
                              tooltip: 'Bookmarks',
                              onPressed: notifier.toggleBookmarksPanel,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _ZoomToolbar(state: state, notifier: notifier),
            ],
          ),
          if (state.showBookmarks)
            Positioned(
              top: 0,
              bottom: 0,
              right: 72, // sits beside the side-rail
              child: _BookmarksOverlay(state: state, notifier: notifier),
            ),
        ],
      ),
    );
  }

  void _showPageJumpDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: '1 – ${state.totalPages}'),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              notifier.goToPage(page);
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) notifier.goToPage(page);
              Navigator.of(ctx).pop();
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}

// ── Expanded layout ───────────────────────────────────────────────────────────

class _ExpandedLayout extends ConsumerWidget {
  const _ExpandedLayout({
    required this.state,
    required this.notifier,
    required this.documentUrl,
    required this.transformController,
  });

  final PdfReaderState state;
  final PdfReaderNotifier notifier;
  final String documentUrl;
  final TransformationController transformController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfController = ref.watch(pdfControllerProvider);

    return SafeArea(
      bottom: true,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _PdfViewArea(
                      state: state,
                      pdfController: pdfController,
                      notifier: notifier,
                      documentUrl: documentUrl,
                      transformController: transformController,
                    ),
                  ),
                ),
              ),
              _BottomToolbar(state: state, notifier: notifier),
            ],
          ),
          if (state.showBookmarks)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: _BookmarksOverlay(state: state, notifier: notifier),
            ),
        ],
      ),
    );
  }
}

// ── Bookmarks overlay ─────────────────────────────────────────────────────────

class _BookmarksOverlay extends StatelessWidget {
  const _BookmarksOverlay({required this.state, required this.notifier});

  final PdfReaderState state;
  final PdfReaderNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PdfBookmarksPanel(
      bookmarks: state.bookmarks,
      currentPage: state.currentPage,
      onGoToPage: notifier.goToPage,
      onClose: notifier.toggleBookmarksPanel,
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _PdfViewArea extends StatelessWidget {
  const _PdfViewArea({
    required this.state,
    required this.pdfController,
    required this.notifier,
    required this.documentUrl,
    required this.transformController,
  });

  final PdfReaderState state;
  final pdfx.PdfController? pdfController;
  final PdfReaderNotifier notifier;
  final String documentUrl;
  final TransformationController transformController;

  @override
  Widget build(BuildContext context) {
    if (state.status == PdfReaderStatus.error) {
      return PdfErrorState(
        errorMessage: state.errorMessage ?? 'Failed to load document.',
        onRetry: () => notifier.open(documentUrl),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (pdfController != null)
          InteractiveViewer(
            transformationController: transformController,
            minScale: 0.25,
            maxScale: 4.0,
            constrained: false,
            child: pdfx.PdfView(
              controller: pdfController!,
              onDocumentLoaded: (doc) =>
                  notifier.onDocumentLoaded(doc.pagesCount),
              onDocumentError: notifier.onDocumentError,
              onPageChanged: notifier.onPageChanged,
            ),
          ),
        if (state.status == PdfReaderStatus.loading || pdfController == null)
          const PdfLoadingState(),
      ],
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({required this.state, required this.notifier});

  final PdfReaderState state;
  final PdfReaderNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          children: [
            PdfPageNavigation(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              onPrevious: state.currentPage > 1 ? notifier.previousPage : null,
              onNext: state.currentPage < state.totalPages
                  ? notifier.nextPage
                  : null,
              onJumpToPage: state.status == PdfReaderStatus.ready
                  ? notifier.goToPage
                  : null,
            ),
            PdfZoomControls(
              currentZoom: state.zoom,
              currentPreset: state.zoomPreset,
              onZoomIn: () => notifier.setZoom(state.zoom + 0.25),
              onZoomOut: () => notifier.setZoom(state.zoom - 0.25),
              onPresetSelected: notifier.setZoomPreset,
            ),
            PdfSearchBar(
              totalPages: state.totalPages,
              onGoToPage: notifier.goToPage,
            ),
            // Bookmark toggle
            Semantics(
              label: state.isBookmarked(state.currentPage)
                  ? 'Remove bookmark from page ${state.currentPage}'
                  : 'Add bookmark to page ${state.currentPage}',
              button: true,
              child: IconButton(
                icon: Icon(
                  state.isBookmarked(state.currentPage)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                tooltip: state.isBookmarked(state.currentPage)
                    ? 'Remove bookmark'
                    : 'Add bookmark',
                onPressed: () => notifier.toggleBookmark(state.currentPage),
              ),
            ),
            // Bookmarks list toggle
            Semantics(
              label: 'Show bookmarks list',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.list),
                tooltip: 'Bookmarks',
                onPressed: notifier.toggleBookmarksPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomToolbar extends StatelessWidget {
  const _ZoomToolbar({required this.state, required this.notifier});

  final PdfReaderState state;
  final PdfReaderNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: PdfZoomControls(
          currentZoom: state.zoom,
          currentPreset: state.zoomPreset,
          onZoomIn: () => notifier.setZoom(state.zoom + 0.25),
          onZoomOut: () => notifier.setZoom(state.zoom - 0.25),
          onPresetSelected: notifier.setZoomPreset,
        ),
      ),
    );
  }
}
