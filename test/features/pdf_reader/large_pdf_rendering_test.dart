// Tests for large-PDF edge cases (CSA-198).
//
// No real PDF files are used. Large documents are simulated by driving
// PdfPageNavigation and PdfReaderNotifier directly with high page counts.
// PdfReaderWidget itself depends on the pdfx platform channel which is
// unavailable in the test host, so widget-level loading/error behaviour is
// verified through its provider (PdfReaderNotifier) and through isolated
// sub-widgets (PdfLoadingState, PdfErrorState).

import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_error_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_loading_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_page_navigation.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _materialWrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox.expand(child: child)),
);

/// Builds a [PdfPageNavigation] for a 500-page document at [currentPage].
///
/// [onJump] receives pages committed from the jump dialog.
Widget _nav500({int currentPage = 1, List<int>? jumpedPages}) {
  final captured = jumpedPages;
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: PdfPageNavigation(
          currentPage: currentPage,
          totalPages: 500,
          onPrevious: currentPage > 1 ? () {} : null,
          onNext: currentPage < 500 ? () {} : null,
          onJumpToPage: (p) => captured?.add(p),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 1. PdfPageNavigation — 500-page document
// ---------------------------------------------------------------------------

void main() {
  group('PdfPageNavigation — 500-page document', () {
    testWidgets('displays "1 / 500" on the first page', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 1));
      expect(find.text('1 / 500'), findsOneWidget);
    });

    testWidgets('displays "500 / 500" on the last page', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 500));
      expect(find.text('500 / 500'), findsOneWidget);
    });

    testWidgets('displays "250 / 500" in the middle', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 250));
      expect(find.text('250 / 500'), findsOneWidget);
    });

    testWidgets('previous button is disabled on page 1', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 1));
      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('next button is disabled on page 500', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 500));
      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('previous button is enabled on page 2', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 2));
      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('next button is enabled on page 499', (tester) async {
      await tester.pumpWidget(_nav500(currentPage: 499));
      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(btn.onPressed, isNotNull);
    });

    // Jump dialog — valid page
    testWidgets('jump dialog calls onJumpToPage(250) for valid input', (
      tester,
    ) async {
      final jumped = <int>[];
      await tester.pumpWidget(_nav500(currentPage: 1, jumpedPages: jumped));

      // Open the jump dialog by tapping the page-indicator container.
      await tester.tap(find.text('1 / 500'));
      await tester.pumpAndSettle();

      expect(find.text('Go to page'), findsOneWidget);

      // Clear pre-filled value and enter 250.
      final field = find.byType(TextField).last;
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, '250');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(jumped, [250]);
    });

    // Jump dialog — page 0 is out of range: widget does NOT call onJumpToPage.
    testWidgets('jump dialog rejects page 0 (out of range)', (tester) async {
      final jumped = <int>[];
      await tester.pumpWidget(_nav500(currentPage: 1, jumpedPages: jumped));

      await tester.tap(find.text('1 / 500'));
      await tester.pumpAndSettle();

      final field = find.byType(TextField).last;
      await tester.enterText(field, '0');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(jumped, isEmpty);
    });

    // Jump dialog — page 999 exceeds totalPages: widget does NOT call onJumpToPage.
    testWidgets('jump dialog rejects page 999 (exceeds totalPages)', (
      tester,
    ) async {
      final jumped = <int>[];
      await tester.pumpWidget(_nav500(currentPage: 1, jumpedPages: jumped));

      await tester.tap(find.text('1 / 500'));
      await tester.pumpAndSettle();

      final field = find.byType(TextField).last;
      await tester.enterText(field, '999');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(jumped, isEmpty);
    });

    // Jump dialog — boundary value 500 is valid.
    testWidgets('jump dialog accepts the maximum page (500)', (tester) async {
      final jumped = <int>[];
      await tester.pumpWidget(_nav500(currentPage: 1, jumpedPages: jumped));

      await tester.tap(find.text('1 / 500'));
      await tester.pumpAndSettle();

      final field = find.byType(TextField).last;
      await tester.enterText(field, '500');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(jumped, [500]);
    });

    // Jump dialog — boundary value 1 is valid.
    testWidgets('jump dialog accepts the minimum page (1)', (tester) async {
      final jumped = <int>[];
      await tester.pumpWidget(_nav500(currentPage: 250, jumpedPages: jumped));

      await tester.tap(find.text('250 / 500'));
      await tester.pumpAndSettle();

      final field = find.byType(TextField).last;
      await tester.enterText(field, '1');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(jumped, [1]);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. PdfSearchBar — 500-page document
  // ---------------------------------------------------------------------------

  group('PdfSearchBar — 500-page document', () {
    testWidgets('accepts a mid-range page (250)', (tester) async {
      int? result;
      await tester.pumpWidget(
        _materialWrap(
          PdfSearchBar(totalPages: 500, onGoToPage: (p) => result = p),
        ),
      );

      await tester.enterText(find.byType(TextField), '250');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(result, 250);
    });

    testWidgets('rejects 0 for a 500-page document', (tester) async {
      int? result;
      await tester.pumpWidget(
        _materialWrap(
          PdfSearchBar(totalPages: 500, onGoToPage: (p) => result = p),
        ),
      );

      await tester.enterText(find.byType(TextField), '0');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('rejects 501 for a 500-page document', (tester) async {
      int? result;
      await tester.pumpWidget(
        _materialWrap(
          PdfSearchBar(totalPages: 500, onGoToPage: (p) => result = p),
        ),
      );

      await tester.enterText(find.byType(TextField), '501');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('accepts the last page exactly (500)', (tester) async {
      int? result;
      await tester.pumpWidget(
        _materialWrap(
          PdfSearchBar(totalPages: 500, onGoToPage: (p) => result = p),
        ),
      );

      await tester.enterText(find.byType(TextField), '500');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(result, 500);
    });

    testWidgets('hint text shows the 500-page range', (tester) async {
      await tester.pumpWidget(
        _materialWrap(PdfSearchBar(totalPages: 500, onGoToPage: (_) {})),
      );

      expect(find.text('1–500'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. PdfReaderNotifier — large document logic (unit tests)
  // ---------------------------------------------------------------------------

  group('PdfReaderNotifier — large document state transitions', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test(
      'onDocumentLoaded(500) sets totalPages to 500 and status to ready',
      () {
        container.read(pdfReaderProvider.notifier).onDocumentLoaded(500);
        final state = container.read(pdfReaderProvider);
        expect(state.totalPages, 500);
        expect(state.status, PdfReaderStatus.ready);
      },
    );

    test('onDocumentLoaded(500) starts at page 1', () {
      container.read(pdfReaderProvider.notifier).onDocumentLoaded(500);
      expect(container.read(pdfReaderProvider).currentPage, 1);
    });

    test('goToPage(250) navigates to page 250 within a 500-page document', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(250);
      expect(container.read(pdfReaderProvider).currentPage, 250);
    });

    test('goToPage(0) is ignored — currentPage stays at 1', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(0);
      expect(container.read(pdfReaderProvider).currentPage, 1);
    });

    test('goToPage(999) is ignored — currentPage stays at 1', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(999);
      expect(container.read(pdfReaderProvider).currentPage, 1);
    });

    test('goToPage(500) navigates to the last page', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(500);
      expect(container.read(pdfReaderProvider).currentPage, 500);
    });

    test('goToPage(1) navigates to the first page', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(250);
      notifier.goToPage(1);
      expect(container.read(pdfReaderProvider).currentPage, 1);
    });

    test('onDocumentError sets status to error and records message', () {
      container
          .read(pdfReaderProvider.notifier)
          .onDocumentError(Exception('network timeout'));
      final state = container.read(pdfReaderProvider);
      expect(state.status, PdfReaderStatus.error);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('network timeout'));
    });

    test('progress is 0.5 at page 250 of 500', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(250);
      expect(container.read(pdfReaderProvider).progress, closeTo(0.5, 0.001));
    });

    test('progress is 1.0 at the last page', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.goToPage(500);
      expect(container.read(pdfReaderProvider).progress, closeTo(1.0, 0.001));
    });

    test('multiple bookmarks at widely spaced pages are sorted correctly', () {
      final notifier = container.read(pdfReaderProvider.notifier);
      notifier.onDocumentLoaded(500);
      notifier.toggleBookmark(499);
      notifier.toggleBookmark(1);
      notifier.toggleBookmark(250);

      final pages = container
          .read(pdfReaderProvider)
          .bookmarks
          .map((b) => b.page);
      expect(pages.toList(), [1, 250, 499]);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Loading and error widget rendering
  // ---------------------------------------------------------------------------

  group('PdfLoadingState — rendering', () {
    testWidgets('shows CircularProgressIndicator and label', (tester) async {
      await tester.pumpWidget(_materialWrap(const PdfLoadingState()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading document…'), findsOneWidget);
    });
  });

  group('PdfErrorState — large-document error', () {
    testWidgets('shows message and Retry button for a timed-out large PDF', (
      tester,
    ) async {
      await tester.pumpWidget(
        _materialWrap(
          PdfErrorState(
            errorMessage: 'Failed to load page 347: connection timed out',
            onRetry: () {},
          ),
        ),
      );

      expect(
        find.text('Failed to load page 347: connection timed out'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('calls onRetry when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _materialWrap(
          PdfErrorState(
            errorMessage: 'Timeout on page 499',
            onRetry: () => called = true,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(called, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Long document title — no overflow / RenderFlex errors
  // ---------------------------------------------------------------------------

  group('Long document title — overflow handling', () {
    const longTitle =
        'Advanced Flutter Architecture Patterns for Enterprise Applications: '
        'A Comprehensive Guide to Building Scalable, Maintainable, and '
        'High-Performance Cross-Platform Applications with Riverpod, '
        'go_router, and Feature-First Clean Architecture — Volume I';

    testWidgets('Text with overflow:ellipsis does not throw RenderFlex error', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text(
                longTitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      // No RenderFlex / overflow exception should be thrown.
      expect(tester.takeException(), isNull);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('SizedBox-constrained Text with long title does not throw', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Text(
                longTitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'PdfPageNavigation renders without overflow on a narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Simulate a constrained header with a long title.
                  SizedBox(
                    width: 320,
                    child: Text(
                      longTitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  PdfPageNavigation(
                    currentPage: 1,
                    totalPages: 500,
                    onPrevious: null,
                    onNext: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('1 / 500'), findsOneWidget);
      },
    );
  });
}
