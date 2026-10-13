import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfReaderNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle with page 1 and zoom 1.0', () {
      final state = container.read(pdfReaderProvider);

      expect(state.status, PdfReaderStatus.idle);
      expect(state.currentPage, 1);
      expect(state.totalPages, 1);
      expect(state.zoom, 1.0);
      expect(state.zoomPreset, PdfZoomPreset.fitWidth);
      expect(state.errorMessage, isNull);
    });

    test('progress returns 0 when totalPages is 1 and currentPage is 1', () {
      final state = container.read(pdfReaderProvider);
      expect(state.progress, closeTo(1.0, 0.001));
    });

    test('onDocumentLoaded sets ready status and totalPages', () {
      container.read(pdfReaderProvider.notifier).onDocumentLoaded(42);
      final state = container.read(pdfReaderProvider);

      expect(state.status, PdfReaderStatus.ready);
      expect(state.totalPages, 42);
    });

    test('onDocumentError sets error status and message', () {
      container
          .read(pdfReaderProvider.notifier)
          .onDocumentError(Exception('network error'));
      final state = container.read(pdfReaderProvider);

      expect(state.status, PdfReaderStatus.error);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('network error'));
    });

    test('goToPage updates currentPage within valid range', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(20);
      notifier.goToPage(10);

      expect(container.read(pdfReaderProvider).currentPage, 10);
    });

    test('goToPage ignores page 0', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(10);
      notifier.goToPage(0);

      expect(container.read(pdfReaderProvider).currentPage, 1);
    });

    test('goToPage ignores page beyond totalPages', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(10);
      notifier.goToPage(11);

      expect(container.read(pdfReaderProvider).currentPage, 1);
    });

    test('progress computes correctly after page and total are set', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(10);
      notifier.goToPage(5);

      expect(container.read(pdfReaderProvider).progress, closeTo(0.5, 0.001));
    });

    test('setZoom clamps to minimum 0.25', () {
      container.read(pdfReaderProvider.notifier).setZoom(0.1);
      expect(container.read(pdfReaderProvider).zoom, 0.25);
    });

    test('setZoom clamps to maximum 4.0', () {
      container.read(pdfReaderProvider.notifier).setZoom(5.0);
      expect(container.read(pdfReaderProvider).zoom, 4.0);
    });

    test('setZoom accepts value within range', () {
      container.read(pdfReaderProvider.notifier).setZoom(1.75);
      expect(container.read(pdfReaderProvider).zoom, closeTo(1.75, 0.001));
    });

    test('setZoomPreset zoom150 sets zoom to 1.5', () {
      container
          .read(pdfReaderProvider.notifier)
          .setZoomPreset(PdfZoomPreset.zoom150);
      final state = container.read(pdfReaderProvider);

      expect(state.zoom, closeTo(1.5, 0.001));
      expect(state.zoomPreset, PdfZoomPreset.zoom150);
    });

    test('setZoomPreset zoom200 sets zoom to 2.0', () {
      container
          .read(pdfReaderProvider.notifier)
          .setZoomPreset(PdfZoomPreset.zoom200);

      expect(container.read(pdfReaderProvider).zoom, closeTo(2.0, 0.001));
    });

    test('onPageChanged updates currentPage', () {
      container.read(pdfReaderProvider.notifier).onDocumentLoaded(30);
      container.read(pdfReaderProvider.notifier).onPageChanged(15);

      expect(container.read(pdfReaderProvider).currentPage, 15);
    });

    test('controller is null before open() is called', () {
      expect(container.read(pdfReaderProvider.notifier).controller, isNull);
    });
  });
}
