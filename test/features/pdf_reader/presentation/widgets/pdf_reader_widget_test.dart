import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_error_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_loading_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_page_navigation.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_zoom_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfLoadingState', () {
    testWidgets('shows CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(child: PdfLoadingState()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(child: PdfLoadingState()),
          ),
        ),
      );

      expect(find.text('Loading document…'), findsOneWidget);
    });
  });

  group('PdfErrorState', () {
    testWidgets('shows error message and Retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: PdfErrorState(
                errorMessage: 'Failed to load',
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });

    testWidgets('hides Retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: PdfErrorState(errorMessage: 'Network error'),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('calls onRetry when Retry button is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: PdfErrorState(
                errorMessage: 'Error',
                onRetry: () => called = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(called, isTrue);
    });
  });

  group('PdfPageNavigation', () {
    testWidgets('previous button is disabled when at page 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPageNavigation(
              currentPage: 1,
              totalPages: 10,
              onPrevious: null,
              onNext: () {},
            ),
          ),
        ),
      );

      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('next button is disabled when at last page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPageNavigation(
              currentPage: 10,
              totalPages: 10,
              onPrevious: () {},
              onNext: null,
            ),
          ),
        ),
      );

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('shows current page and total pages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPageNavigation(
              currentPage: 5,
              totalPages: 42,
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 / 42'), findsOneWidget);
    });
  });

  group('PdfZoomControls', () {
    testWidgets('shows 100% when zoom is 1.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PdfZoomControls(
              currentZoom: 1.0,
              currentPreset: PdfZoomPreset.zoom100,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows 150% when zoom is 1.5', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PdfZoomControls(
              currentZoom: 1.5,
              currentPreset: PdfZoomPreset.zoom150,
            ),
          ),
        ),
      );

      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('zoom-out button is disabled at minimum zoom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfZoomControls(
              currentZoom: 0.25,
              currentPreset: PdfZoomPreset.fitPage,
              onZoomOut: () {},
              onZoomIn: () {},
            ),
          ),
        ),
      );

      final minusButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove),
      );
      expect(minusButton.onPressed, isNull);
    });

    testWidgets('zoom-in button is disabled at maximum zoom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfZoomControls(
              currentZoom: 4.0,
              currentPreset: PdfZoomPreset.fitPage,
              onZoomOut: () {},
              onZoomIn: () {},
            ),
          ),
        ),
      );

      final plusButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(plusButton.onPressed, isNull);
    });

    testWidgets('calls onZoomIn when + button is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfZoomControls(
              currentZoom: 1.0,
              currentPreset: PdfZoomPreset.zoom100,
              onZoomIn: () => called = true,
              onZoomOut: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      expect(called, isTrue);
    });
  });
}
