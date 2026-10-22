@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/pdf_reader/data/pdf_outline_web.dart';
import 'package:acendra/features/pdf_reader/data/pdf_reading_store.dart';
import 'package:acendra/features/pdf_reader/data/protected_pdf_repository.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_lesson_reader.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_contents_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdfx/src/renderer/interfaces/platform.dart';
import 'package:pdfx/src/renderer/web/platform.dart';
import 'package:web/web.dart' as web;

const lesson = '27100000-0000-4000-8000-000000000002';
const resource = '27100000-0000-4000-8000-000000000003';

class _SyntheticTransport implements PdfTransport {
  _SyntheticTransport(this.bytes);
  final Uint8List bytes;
  final calls = <Uri>[];
  @override
  void cancel() {}
  @override
  Future<PdfTransportResponse> get(Uri url, String bearer) async {
    expect(bearer, 'synthetic-session');
    calls.add(url);
    if (url.queryParameters['resource_id'] != null) {
      expect(url.queryParameters, {
        'lesson_id': lesson,
        'resource_id': resource,
      });
      return PdfTransportResponse(200, 'application/pdf', bytes);
    }
    return PdfTransportResponse(
      200,
      'application/json',
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'data': {
              'lesson_id': lesson,
              'resource_id': resource,
              'state': 'ready',
              'mode': 'proxied_stream',
              'watermark_applied': true,
            },
          }),
        ),
      ),
    );
  }
}

void main() {
  // Browser debugPrint output can be absent when Flutter is launched through
  // the Node CI wrapper. Preserve normal failure registration while forwarding
  // the synthetic fixture's actual exception through the test print channel.
  final originalReporter = reportTestException;
  reportTestException = (details, description) {
    // ignore: avoid_print
    print(
      'PDF browser failure: ${details.exceptionAsString()}\n${details.stack}',
    );
    originalReporter(details, description);
  };
  tearDownAll(() => reportTestException = originalReporter);
  setUpAll(() async {
    final loaded = Completer<void>();
    final script = web.HTMLScriptElement()
      ..type = 'module'
      ..src = '/.dart_tool/pdf_runtime/pdfjs_runtime.js';
    script.addEventListener('load', ((web.Event _) => loaded.complete()).toJS);
    script.addEventListener(
      'error',
      ((web.Event _) => loaded.completeError(
        StateError(
          'Staged PDF renderer unavailable; run node tool/prepare_pdf_browser.mjs',
        ),
      )).toJS,
    );
    web.document.head!.appendChild(script);
    await loaded.future.timeout(const Duration(seconds: 20));
    PdfxPlatform.instance = PdfxWeb();
  });
  testWidgets(
    'real derivative: chapters, bookmarks, zoom/fit-width and own-user restoration',
    (tester) async {
      final prepared = await tester.runAsync(() async {
        final response = await web.window
            .fetch('/fixtures/csa271_watermarked.pdf'.toJS)
            .toDart;
        expect(response.status, 200);
        final bytes = (await response.arrayBuffer().toDart).toDart
            .asUint8List();
        final transport = _SyntheticTransport(bytes);
        final data = await ProtectedPdfRepository(
          Uri.parse('https://synthetic.invalid/pdf-content'),
          transport,
        ).loadDocument(lesson, 'synthetic-session');
        expect(transport.calls.length, 2);
        final entries = await loadPdfOutline(data!.bytes);
        expect(entries.map((e) => (e.title, e.page, e.level)), [
          ('Introduction', 1, 0),
          ('Reading controls', 2, 1),
          ('Practice', 3, 0),
        ]);
        final document = await pdfx.PdfDocument.openData(
          Uint8List.fromList(data.bytes),
        );
        expect(document.pagesCount, 4);
        return (
          document: document,
          entries: entries,
          watermarked: data.watermarkApplied,
        );
      });
      final document = prepared!.document;
      final entries = prepared.entries;
      addTearDown(document.close);
      final student = PdfReadingStore(
        userId: 'synthetic-reader-271',
        lessonId: lesson,
      );
      student.savePage(1);
      student.saveBookmarks([]);
      Widget host({double textScale = 1, bool dark = false}) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: PdfLessonReader(
              document: document,
              store: student,
              title: 'Synthetic guide',
              outline: entries,
              watermarkApplied: prepared.watermarked,
            ),
          ),
        ),
      );
      Future<void> rendered(int page) async {
        for (var i = 0; i < 100; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          if (find
              .byWidgetPredicate(
                (widget) =>
                    widget is Image && widget.semanticLabel == 'PDF page $page',
              )
              .evaluate()
              .isNotEmpty) {
            return;
          }
        }
        fail('Real PDF page did not render');
      }

      Future<void> waitFor(bool Function() ready, String description) async {
        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
          if (ready()) return;
        }
        fail('Timed out waiting for $description');
      }

      Future<void> contentsClosed() => waitFor(
        () => find.byType(PdfContentsSheet).evaluate().isEmpty,
        'contents dismissal',
      );

      Future<void> openContents() async {
        await contentsClosed();
        await tester.tap(find.widgetWithText(TextButton, 'Contents'));
        await waitFor(() {
          final sheet = find.byType(PdfContentsSheet).evaluate();
          return sheet.length == 1 &&
              ModalRoute.of(sheet.single)!.animation!.status ==
                  AnimationStatus.completed;
        }, 'contents opening');
      }

      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(390, 1000);
      await tester.pumpWidget(host());
      await rendered(1);
      expect(find.textContaining('watermark on every page'), findsOneWidget);
      await openContents();
      await tester.tap(find.text('Practice'));
      await contentsClosed();
      await rendered(3);
      expect(find.text('3 / 4'), findsOneWidget);
      await openContents();
      await tester.tap(find.byTooltip('Close contents'));
      await contentsClosed();
      expect(find.text('3 / 4'), findsOneWidget);
      await tester.tap(find.byTooltip('Bookmark page'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(find.text('125%'), findsOneWidget);
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        1.25,
      );
      await tester.tap(find.byTooltip('Fit to width'));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host());
      await rendered(3);
      expect(find.text('3 / 4'), findsOneWidget);
      await openContents();
      await tester.tap(find.text('Page 3'));
      await contentsClosed();
      expect(find.text('3 / 4'), findsOneWidget);
      expect(
        PdfReadingStore(
          userId: 'other-reader-271',
          lessonId: lesson,
        ).loadPage(4),
        1,
      );
      for (final width in [320.0, 390.0, 768.0, 1440.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 1000);
          await tester.pumpWidget(host(textScale: scale));
          await rendered(3);
          expect(tester.takeException(), isNull);
          for (final button in find.byType(IconButton).evaluate()) {
            final rect = tester.getRect(
              find.byElementPredicate((e) => e == button),
            );
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
          }
        }
      }
      await tester.pumpWidget(host(dark: true));
      await rendered(3);
      await waitFor(
        () =>
            Theme.of(tester.element(find.byType(PdfLessonReader))).brightness ==
            Brightness.dark,
        'dark theme transition',
      );
      expect(
        Theme.of(tester.element(find.byType(PdfLessonReader))).brightness,
        Brightness.dark,
      );
      await openContents();
      await tester.tap(find.text('Introduction'));
      await contentsClosed();
      await rendered(1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host());
      await rendered(1);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(student.loadPage(4), 1);
      student.saveBookmarks([]);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
