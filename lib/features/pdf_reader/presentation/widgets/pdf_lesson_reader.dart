import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import '../../data/pdf_reading_store.dart';
import '../../domain/entities/pdf_outline_entry.dart';
import 'pdf_contents_sheet.dart';
import 'pdf_error_state.dart';
import 'pdf_loading_state.dart';
import 'pdf_reader_footer.dart';

/// The active protected reader. The parent owns the authenticated document
/// lease and removes this widget whenever the account/session/lesson changes.
class PdfLessonReader extends StatefulWidget {
  const PdfLessonReader({
    super.key,
    required this.document,
    required this.store,
    required this.outline,
    required this.watermarkApplied,
    this.outlineUnavailable = false,
    this.title = 'PDF guide',
  });
  final pdfx.PdfDocument document;
  final PdfReadingStore store;
  final List<PdfOutlineEntry> outline;
  final bool watermarkApplied, outlineUnavailable;
  final String title;
  @override
  State<PdfLessonReader> createState() => _PdfLessonReaderState();
}

class _PdfLessonReaderState extends State<PdfLessonReader> {
  late final PageController _controller;
  late int _page;
  late List<int> _bookmarks;
  double _zoom = 1;
  Route<dynamic>? _contentsRoute;
  final _transform = TransformationController();
  int get _pages => widget.document.pagesCount;

  @override
  void initState() {
    super.initState();
    _page = widget.store.loadPage(_pages);
    _bookmarks = widget.store.loadBookmarks(_pages);
    _controller = PageController(initialPage: _page - 1);
  }

  @override
  void dispose() {
    final route = _contentsRoute;
    final navigator = route?.navigator;
    if (route != null && navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted && route.isActive) navigator.removeRoute(route);
      });
    }
    _controller.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _setZoom(double value) {
    setState(() => _zoom = value.clamp(1.0, 3.0));
    _transform.value = Matrix4.diagonal3Values(_zoom, _zoom, 1);
  }

  void _goTo(int page) {
    if (mounted && page >= 1 && page <= _pages && _controller.hasClients) {
      _controller.jumpToPage(page - 1);
    }
  }

  void _bookmark() {
    if (!_bookmarks.contains(_page) && _bookmarks.length >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can save up to 100 bookmarks per guide.'),
        ),
      );
      return;
    }
    setState(() {
      _bookmarks.contains(_page)
          ? _bookmarks.remove(_page)
          : _bookmarks.add(_page);
      _bookmarks.sort();
    });
    widget.store.saveBookmarks(_bookmarks);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Flexible(
                child: TextButton.icon(
                  onPressed: () => showPdfContentsSheet(
                    context,
                    entries: widget.outline,
                    currentPage: _page,
                    bookmarks: List.of(_bookmarks),
                    outlineUnavailable: widget.outlineUnavailable,
                    onRouteCreated: (route) => _contentsRoute = route,
                    onGoToPage: _goTo,
                  ),
                  icon: const Icon(Icons.list),
                  label: const Text('Contents'),
                ),
              ),
              IconButton(
                tooltip: _bookmarks.contains(_page)
                    ? 'Remove bookmark'
                    : 'Bookmark page',
                isSelected: _bookmarks.contains(_page),
                onPressed: _bookmark,
                icon: const Icon(Icons.bookmark_border),
                selectedIcon: const Icon(Icons.bookmark),
              ),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color:
                Theme.of(
                  context,
                ).extension<AppThemeExtension>()?.surfaceSecondary ??
                colors.surfaceContainerHighest,
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages,
              physics: _zoom > 1 ? const NeverScrollableScrollPhysics() : null,
              onPageChanged: (index) {
                setState(() => _page = index + 1);
                _transform.value = Matrix4.diagonal3Values(_zoom, _zoom, 1);
                widget.store.savePage(_page);
              },
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(12),
                child: _PdfCanvas(
                  key: ValueKey((widget.document.id, index)),
                  document: widget.document,
                  page: index + 1,
                  zoom: _zoom,
                  transform: _transform,
                ),
              ),
            ),
          ),
        ),
        if (widget.watermarkApplied) const PdfWatermarkDisclosure(),
        PdfReaderFooter(
          currentPage: _page,
          totalPages: _pages,
          zoom: _zoom,
          isFitWidth: _zoom == 1,
          onPrevious: _page > 1 ? () => _goTo(_page - 1) : null,
          onNext: _page < _pages ? () => _goTo(_page + 1) : null,
          onZoomIn: _zoom < 3 ? () => _setZoom(_zoom + .25) : null,
          onZoomOut: _zoom > 1 ? () => _setZoom(_zoom - .25) : null,
          onFitWidth: () => _setZoom(1),
        ),
      ],
    );
  }
}

class _PdfCanvas extends StatefulWidget {
  const _PdfCanvas({
    super.key,
    required this.document,
    required this.page,
    required this.zoom,
    required this.transform,
  });
  final pdfx.PdfDocument document;
  final int page;
  final double zoom;
  final TransformationController transform;
  @override
  State<_PdfCanvas> createState() => _PdfCanvasState();
}

class _PdfCanvasState extends State<_PdfCanvas> {
  late Future<Uint8List> _image;
  @override
  void initState() {
    super.initState();
    _image = _render();
  }

  Future<Uint8List> _render() async {
    final page = await widget.document.getPage(widget.page);
    try {
      // Bound raster memory even for unusually large source page geometry.
      final scale = math.min(2.0, 4096 / math.max(page.width, page.height));
      final image = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: pdfx.PdfPageImageFormat.png,
        backgroundColor: '#ffffff',
      );
      if (image == null) throw StateError('Page unavailable');
      return image.bytes;
    } finally {
      await page.close();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _image,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return PdfErrorState(
          errorMessage: 'This page could not be rendered. Please retry.',
          onRetry: () => setState(() => _image = _render()),
        );
      }
      if (!snapshot.hasData) return const PdfLoadingState();
      return LayoutBuilder(
        builder: (context, constraints) => ClipRect(
          child: InteractiveViewer(
            transformationController: widget.transform,
            minScale: 1,
            maxScale: 3,
            panEnabled: widget.zoom > 1,
            scaleEnabled: false,
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Image.memory(
                snapshot.data!,
                width: constraints.maxWidth,
                fit: BoxFit.fitWidth,
                gaplessPlayback: true,
                semanticLabel: 'PDF page ${widget.page}',
                errorBuilder: (_, error, stack) =>
                    const Text('This page could not be displayed.'),
              ),
            ),
          ),
        ),
      );
    },
  );
}
