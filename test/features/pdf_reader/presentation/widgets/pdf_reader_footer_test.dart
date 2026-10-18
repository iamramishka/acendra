import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_reader_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 390}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 844)),
    child: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

PdfReaderFooter _footer({
  int page = 2,
  int total = 10,
  double zoom = 1.0,
  bool fitWidth = true,
  VoidCallback? onPrevious,
  VoidCallback? onNext,
  VoidCallback? onZoomIn,
  VoidCallback? onZoomOut,
  VoidCallback? onFitWidth,
}) => PdfReaderFooter(
  currentPage: page,
  totalPages: total,
  zoom: zoom,
  isFitWidth: fitWidth,
  onPrevious: onPrevious,
  onNext: onNext,
  onZoomIn: onZoomIn,
  onZoomOut: onZoomOut,
  onFitWidth: onFitWidth,
);

void main() {
  group('PdfWatermarkDisclosure', () {
    testWidgets('shows the personal watermark disclosure line', (tester) async {
      await tester.pumpWidget(_host(const PdfWatermarkDisclosure()));
      expect(
        find.text('This guide shows your name as a watermark on every page.'),
        findsOneWidget,
      );
    });
  });

  group('PdfReaderFooter', () {
    testWidgets('shows page, zoom percent and all controls in one bar', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_footer(zoom: 1.25)));
      expect(find.text('2 / 10'), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
      expect(find.byTooltip('Previous page'), findsOneWidget);
      expect(find.byTooltip('Next page'), findsOneWidget);
      expect(find.byTooltip('Zoom out'), findsOneWidget);
      expect(find.byTooltip('Zoom in'), findsOneWidget);
      expect(find.byTooltip('Fit to width'), findsOneWidget);
    });

    testWidgets('has no download or print control', (tester) async {
      await tester.pumpWidget(_host(_footer()));
      expect(find.byIcon(Icons.download), findsNothing);
      expect(find.byIcon(Icons.print), findsNothing);
      expect(find.byTooltip('Download'), findsNothing);
      expect(find.byTooltip('Print'), findsNothing);
    });

    testWidgets('invokes callbacks', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          _footer(
            onPrevious: () => calls.add('prev'),
            onNext: () => calls.add('next'),
            onZoomIn: () => calls.add('in'),
            onZoomOut: () => calls.add('out'),
            onFitWidth: () => calls.add('fit'),
          ),
        ),
      );
      for (final tip in [
        'Previous page',
        'Next page',
        'Zoom in',
        'Zoom out',
        'Fit to width',
      ]) {
        await tester.tap(find.byTooltip(tip));
      }
      expect(calls, ['prev', 'next', 'in', 'out', 'fit']);
    });

    testWidgets('disables prev on first page and next on last', (tester) async {
      await tester.pumpWidget(
        _host(_footer(page: 1, total: 1, onPrevious: null, onNext: null)),
      );
      final prev = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prev.onPressed, isNull);
    });

    for (final width in [320.0, 390.0, 768.0, 1440.0]) {
      testWidgets('does not overflow at ${width.toInt()}px', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(_footer(page: 128, total: 256, zoom: 2.5), width: width),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(PdfReaderFooter)).width, width);
      });
    }
  });
}
