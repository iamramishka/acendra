import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:pdfx/pdfx.dart' as pdfx;

enum PdfReaderStatus { idle, loading, ready, error }

enum PdfZoomPreset { fitPage, fitWidth, zoom100, zoom150, zoom200 }

@immutable
class PdfReaderState {
  const PdfReaderState({
    required this.status,
    required this.currentPage,
    required this.totalPages,
    required this.zoom,
    required this.zoomPreset,
    this.errorMessage,
  });

  final PdfReaderStatus status;

  /// 1-indexed current page number.
  final int currentPage;
  final int totalPages;

  /// Scale factor where 1.0 = 100%.
  final double zoom;
  final PdfZoomPreset zoomPreset;
  final String? errorMessage;

  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;

  PdfReaderState copyWith({
    PdfReaderStatus? status,
    int? currentPage,
    int? totalPages,
    double? zoom,
    PdfZoomPreset? zoomPreset,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => PdfReaderState(
    status: status ?? this.status,
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    zoom: zoom ?? this.zoom,
    zoomPreset: zoomPreset ?? this.zoomPreset,
    errorMessage: clearErrorMessage
        ? null
        : (errorMessage ?? this.errorMessage),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfReaderState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          currentPage == other.currentPage &&
          totalPages == other.totalPages &&
          zoom == other.zoom &&
          zoomPreset == other.zoomPreset &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
    status,
    currentPage,
    totalPages,
    zoom,
    zoomPreset,
    errorMessage,
  );
}

class PdfReaderNotifier extends StateNotifier<PdfReaderState> {
  PdfReaderNotifier()
    : super(
        const PdfReaderState(
          status: PdfReaderStatus.idle,
          currentPage: 1,
          totalPages: 1,
          zoom: 1.0,
          zoomPreset: PdfZoomPreset.fitWidth,
        ),
      );

  pdfx.PdfController? _controller;

  pdfx.PdfController? get controller => _controller;

  /// Opens the document at [url].
  ///
  /// On Flutter Web, [PdfDocument.openFile] accepts a network URL directly.
  void open(String url) {
    _controller?.dispose();
    _controller = null;

    try {
      _controller = pdfx.PdfController(
        document: pdfx.PdfDocument.openFile(url),
      );
      state = state.copyWith(
        status: PdfReaderStatus.loading,
        currentPage: 1,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: PdfReaderStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Called by [PdfView.onDocumentLoaded] once the document is fully parsed.
  void onDocumentLoaded(int pagesCount) {
    state = state.copyWith(
      status: PdfReaderStatus.ready,
      totalPages: pagesCount,
    );
  }

  /// Called by [PdfView.onDocumentError].
  void onDocumentError(Object error) {
    state = state.copyWith(
      status: PdfReaderStatus.error,
      errorMessage: error.toString(),
    );
  }

  /// Called by [PdfView.onPageChanged].
  void onPageChanged(int page) {
    state = state.copyWith(currentPage: page);
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    _controller?.jumpToPage(page);
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    if (state.currentPage >= state.totalPages) return;
    _controller?.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void previousPage() {
    if (state.currentPage <= 1) return;
    _controller?.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void setZoom(double zoom) {
    final clamped = zoom.clamp(0.25, 4.0);
    state = state.copyWith(zoom: clamped, zoomPreset: PdfZoomPreset.fitPage);
  }

  void setZoomPreset(PdfZoomPreset preset) {
    state = state.copyWith(zoomPreset: preset, zoom: _zoomForPreset(preset));
  }

  double _zoomForPreset(PdfZoomPreset preset) => switch (preset) {
    PdfZoomPreset.fitPage => 0.75,
    PdfZoomPreset.fitWidth => 1.0,
    PdfZoomPreset.zoom100 => 1.0,
    PdfZoomPreset.zoom150 => 1.5,
    PdfZoomPreset.zoom200 => 2.0,
  };

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

final pdfReaderProvider =
    StateNotifierProvider.autoDispose<PdfReaderNotifier, PdfReaderState>(
      (ref) => PdfReaderNotifier(),
    );

/// Exposes the [pdfx.PdfController] once the document has started loading.
/// Returns null in idle/error states.
final pdfControllerProvider = Provider.autoDispose<pdfx.PdfController?>((ref) {
  final status = ref.watch(pdfReaderProvider.select((s) => s.status));
  if (status == PdfReaderStatus.idle || status == PdfReaderStatus.error) {
    return null;
  }
  return ref.read(pdfReaderProvider.notifier).controller;
});
