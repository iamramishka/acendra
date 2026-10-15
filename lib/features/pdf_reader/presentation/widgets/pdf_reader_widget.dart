import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/pdf_reader/domain/entities/pdf_document.dart'
    as domain;
import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_error_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_loading_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_page_navigation.dart';
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

    ref.listen<double>(
      pdfReaderProvider.select((s) => s.zoom),
      (_, next) {
        final currentScale = _zoomController.value.getMaxScaleOnAxis();
        if ((currentScale - next).abs() > 0.001) {
          _zoomController.value = Matrix4.diagonal3Values(next, next, next);
        }
      },
    );

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

    return Column(
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

    return Column(
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
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                    Text(
                      '${state.currentPage}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '/ ${state.totalPages}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textSecondary,
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
                  ],
                ),
              ),
            ],
          ),
        ),
        _ZoomToolbar(state: state, notifier: notifier),
      ],
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

    return Column(
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
