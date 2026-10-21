import 'dart:convert';
import 'package:acendra/features/pdf_reader/data/pdf_reading_store.dart';
import 'package:acendra/features/pdf_reader/domain/entities/pdf_outline_entry.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_lesson_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

// The native renderer is the sole fake boundary in VM widget tests. Chrome
// coverage opens the real generated, watermarked PDF with the bundled PDF.js.
class _Document extends pdfx.PdfDocument {
  _Document() : super(sourceName: 'synthetic', id: 'synthetic', pagesCount: 3);
  @override
  Future<void> close() async {}
  @override
  Future<pdfx.PdfPage> getPage(
    int pageNumber, {
    bool autoCloseAndroid = false,
  }) async => _Page(this, pageNumber);
}

class _Page extends pdfx.PdfPage {
  _Page(pdfx.PdfDocument document, int page)
    : super(
        document: document,
        id: '$page',
        pageNumber: page,
        width: 600,
        height: 800,
        autoCloseAndroid: false,
      );
  @override
  Future<void> close() async {}
  @override
  Future<pdfx.PdfPageTexture> createTexture() => throw UnimplementedError();
  @override
  Future<pdfx.PdfPageImage?> render({
    required double width,
    required double height,
    pdfx.PdfPageImageFormat format = pdfx.PdfPageImageFormat.jpeg,
    String? backgroundColor,
    Rect? cropRect,
    int quality = 100,
    bool forPrint = false,
    bool removeTempFile = true,
  }) async => _Image(pageNumber);
}

class _Image extends pdfx.PdfPageImage {
  _Image(int page)
    : super(
        id: '$page',
        pageNumber: page,
        width: 1,
        height: 1,
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC',
        ),
        format: pdfx.PdfPageImageFormat.png,
        quality: 100,
      );
}

void main() {
  final storage = <String, String>{};
  PdfReadingStore store() => PdfReadingStore(
    userId: 'student',
    lessonId: 'lesson',
    read: (key) => storage[key],
    write: (key, value) => storage[key] = value,
  );
  Widget host({bool watermarked = true, double scale = 1, bool dark = false}) =>
      MaterialApp(
        theme: dark ? ThemeData.dark() : null,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: PdfLessonReader(
              document: _Document(),
              store: store(),
              outline: const [
                PdfOutlineEntry(title: 'Introduction', page: 1),
                PdfOutlineEntry(title: 'Practice', page: 3),
              ],
              watermarkApplied: watermarked,
            ),
          ),
        ),
      );
  setUp(storage.clear);
  testWidgets(
    'removing the authenticated reader also clears its open contents',
    (tester) async {
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, value, child) => value
                  ? PdfLessonReader(
                      document: _Document(),
                      store: store(),
                      watermarkApplied: true,
                      outline: const [
                        PdfOutlineEntry(title: 'Private chapter', page: 2),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contents'));
      await tester.pumpAndSettle();
      expect(find.text('Private chapter'), findsOneWidget);
      visible.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Private chapter'), findsNothing);
      expect(find.text('Bookmarks'), findsNothing);
    },
  );
  testWidgets('dark reader keeps chapter and zoom controls usable', (
    tester,
  ) async {
    await tester.pumpWidget(host(dark: true));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(PdfLessonReader))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Contents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('125%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'contents jump, bookmark, zoom/fit width and restoration use active reader',
    (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contents'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      expect(
        find.text('Contents'),
        findsOneWidget,
      ); // sheet closed, header remains
      await tester.tap(find.byTooltip('Bookmark page'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(find.text('125%'), findsOneWidget);
      final matrix = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
          .transformationController!
          .value;
      expect(matrix.getMaxScaleOnAxis(), 1.25);
      await tester.tap(find.byTooltip('Fit to width'));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.tap(find.text('Contents'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Page 3'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pump();
      expect(store().loadBookmarks(3), isEmpty);
      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    },
  );
  testWidgets('disclosure requires trusted delivered watermark evidence', (
    tester,
  ) async {
    await tester.pumpWidget(host(watermarked: false));
    await tester.pumpAndSettle();
    expect(find.textContaining('watermark on every page'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.textContaining('watermark on every page'), findsOneWidget);
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'reader fits $width with text scale $scale and full touch targets',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(host(scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final element in find.byType(IconButton).evaluate()) {
            final rect = tester.getRect(
              find.byElementPredicate((e) => e == element),
            );
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
          }
        },
      );
    }
  }
}
