import 'package:acendra/features/pdf_reader/domain/entities/pdf_outline_entry.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_contents_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  PdfOutlineEntry(title: 'Introduction', page: 1),
  PdfOutlineEntry(title: 'Basics', page: 5),
  PdfOutlineEntry(title: 'Advanced', page: 12),
];

Widget _host({
  required List<PdfOutlineEntry> entries,
  int currentPage = 6,
  ValueChanged<int>? onGoToPage,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showPdfContentsSheet(
              context,
              entries: entries,
              currentPage: currentPage,
              onGoToPage: onGoToPage ?? (_) {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('currentChapterIndex picks the last entry at or before the page', () {
    expect(currentChapterIndex(_entries, 1), 0);
    expect(currentChapterIndex(_entries, 6), 1);
    expect(currentChapterIndex(_entries, 12), 2);
    expect(currentChapterIndex(const [], 3), -1);
    expect(
      currentChapterIndex(const [PdfOutlineEntry(title: 'X', page: 4)], 2),
      -1,
    );
  });

  testWidgets('lists entries and highlights the current chapter', (
    tester,
  ) async {
    await tester.pumpWidget(_host(entries: _entries));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('Introduction'), findsOneWidget);
    final basics = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Basics'),
    );
    expect(basics.selected, isTrue);
    final intro = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Introduction'),
    );
    expect(intro.selected, isFalse);
  });

  testWidgets('tapping an entry jumps to its page and closes the sheet', (
    tester,
  ) async {
    int? jumped;
    await tester.pumpWidget(
      _host(entries: _entries, onGoToPage: (p) => jumped = p),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(jumped, 12);
    expect(find.text('Contents'), findsNothing);
  });

  testWidgets('shows a clear empty state when there is no outline', (
    tester,
  ) async {
    await tester.pumpWidget(_host(entries: const []));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.text('This document has no table of contents.'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
  });
}
