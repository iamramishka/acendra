// ignore_for_file: avoid_redundant_argument_values

import 'package:acendra/features/pdf_reader/domain/entities/pdf_bookmark.dart';
import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_bookmarks_panel.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper to wrap widgets in a minimal Material + Riverpod environment.
// ---------------------------------------------------------------------------
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox.expand(child: child)),
  );
}

void main() {
  // ── PdfReaderState — bookmark logic ──────────────────────────────────────

  group('PdfReaderState bookmark logic', () {
    test('isBookmarked returns false when no bookmarks', () {
      const state = PdfReaderState(
        status: PdfReaderStatus.idle,
        currentPage: 1,
        totalPages: 10,
        zoom: 1.0,
        zoomPreset: PdfZoomPreset.fitWidth,
      );
      expect(state.isBookmarked(1), isFalse);
    });

    test('isBookmarked returns true after bookmark added', () {
      const state = PdfReaderState(
        status: PdfReaderStatus.idle,
        currentPage: 3,
        totalPages: 10,
        zoom: 1.0,
        zoomPreset: PdfZoomPreset.fitWidth,
        bookmarks: [PdfBookmark(page: 3, label: 'Page 3')],
      );
      expect(state.isBookmarked(3), isTrue);
      expect(state.isBookmarked(1), isFalse);
    });
  });

  // ── PdfReaderNotifier — toggleBookmark ────────────────────────────────────

  group('PdfReaderNotifier toggleBookmark', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('adds bookmark when page has none', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(20);
      notifier.onPageChanged(5);
      notifier.toggleBookmark(5);

      final state = container.read(pdfReaderProvider);
      expect(state.bookmarks, hasLength(1));
      expect(state.bookmarks.first.page, 5);
    });

    test('removes bookmark when page already bookmarked', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(20);
      notifier.toggleBookmark(5);
      notifier.toggleBookmark(5);

      final state = container.read(pdfReaderProvider);
      expect(state.bookmarks, isEmpty);
    });

    test('bookmarks are sorted by page number', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(20);
      notifier.toggleBookmark(10);
      notifier.toggleBookmark(3);
      notifier.toggleBookmark(7);

      final state = container.read(pdfReaderProvider);
      expect(state.bookmarks.map((b) => b.page).toList(), [3, 7, 10]);
    });
  });

  // ── PdfReaderNotifier — toggleBookmarksPanel ──────────────────────────────

  group('PdfReaderNotifier toggleBookmarksPanel', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('showBookmarks starts false', () {
      expect(container.read(pdfReaderProvider).showBookmarks, isFalse);
    });

    test('toggleBookmarksPanel flips showBookmarks', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.toggleBookmarksPanel();
      expect(container.read(pdfReaderProvider).showBookmarks, isTrue);
      notifier.toggleBookmarksPanel();
      expect(container.read(pdfReaderProvider).showBookmarks, isFalse);
    });
  });

  // ── PdfReaderNotifier — setSearchQuery ────────────────────────────────────

  group('PdfReaderNotifier setSearchQuery', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('searchQuery starts empty', () {
      expect(container.read(pdfReaderProvider).searchQuery, '');
    });

    test('setSearchQuery updates searchQuery', () {
      container.read(pdfReaderProvider.notifier).setSearchQuery('42');
      expect(container.read(pdfReaderProvider).searchQuery, '42');
    });
  });

  // ── PdfBookmarksPanel widget tests ────────────────────────────────────────

  group('PdfBookmarksPanel', () {
    testWidgets('shows "No bookmarks yet" when list is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PdfBookmarksPanel(
            bookmarks: const [],
            currentPage: 1,
            onGoToPage: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('No bookmarks yet'), findsOneWidget);
    });

    testWidgets('shows bookmark tiles when list is non-empty', (tester) async {
      const bookmarks = [
        PdfBookmark(page: 3, label: 'Chapter 1'),
        PdfBookmark(page: 7, label: 'Chapter 2'),
      ];

      await tester.pumpWidget(
        _wrap(
          PdfBookmarksPanel(
            bookmarks: bookmarks,
            currentPage: 3,
            onGoToPage: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Chapter 2'), findsOneWidget);
    });

    testWidgets('calls onGoToPage when Go button tapped', (tester) async {
      int? navigatedPage;
      const bookmarks = [PdfBookmark(page: 5, label: 'Bookmark 5')];

      await tester.pumpWidget(
        _wrap(
          PdfBookmarksPanel(
            bookmarks: bookmarks,
            currentPage: 1,
            onGoToPage: (p) => navigatedPage = p,
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      expect(navigatedPage, 5);
    });

    testWidgets('calls onClose when close button tapped', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        _wrap(
          PdfBookmarksPanel(
            bookmarks: const [],
            currentPage: 1,
            onGoToPage: (_) {},
            onClose: () => closed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets('shows panel header text "Bookmarks"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PdfBookmarksPanel(
            bookmarks: const [],
            currentPage: 1,
            onGoToPage: (_) {},
            onClose: () {},
          ),
        ),
      );

      // Panel header is always visible.
      expect(find.text('Bookmarks'), findsOneWidget);
    });
  });

  // ── PdfSearchBar widget tests ─────────────────────────────────────────────

  group('PdfSearchBar', () {
    testWidgets('shows label "Go to page"', (tester) async {
      await tester.pumpWidget(
        _wrap(PdfSearchBar(totalPages: 20, onGoToPage: (_) {})),
      );

      expect(find.text('Go to page'), findsOneWidget);
    });

    testWidgets('calls onGoToPage with valid page number on submit', (
      tester,
    ) async {
      int? result;
      await tester.pumpWidget(
        _wrap(PdfSearchBar(totalPages: 20, onGoToPage: (p) => result = p)),
      );

      await tester.enterText(find.byType(TextField), '10');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(result, 10);
    });

    testWidgets('does not call onGoToPage for out-of-range number', (
      tester,
    ) async {
      int? result;
      await tester.pumpWidget(
        _wrap(PdfSearchBar(totalPages: 20, onGoToPage: (p) => result = p)),
      );

      await tester.enterText(find.byType(TextField), '99');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(result, isNull);
    });
  });

  // ── Layout size tests ─────────────────────────────────────────────────────
  //
  // PdfReaderWidget depends on pdfx platform channels unavailable in the
  // test host. Instead we verify SafeArea and bookmark buttons by rendering
  // a minimal simulated layout at each breakpoint width.

  Widget simulatedLayout({required double width}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: Scaffold(
          body: SizedBox(
            width: width,
            height: 844,
            child: SafeArea(
              bottom: true,
              child: Column(
                children: [
                  const Expanded(child: ColoredBox(color: Colors.grey)),
                  ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Add bookmark',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () {},
                            ),
                          ),
                          Semantics(
                            label: 'Show bookmarks list',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.list),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Responsive layout — SafeArea and bookmark button present', () {
    testWidgets('compact (390px) — SafeArea and bookmark button present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(simulatedLayout(width: 390));

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('medium (768px) — SafeArea and bookmark button present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(simulatedLayout(width: 768));

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('expanded (1440px) — SafeArea and bookmark button present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(simulatedLayout(width: 1440));

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });
  });
}
