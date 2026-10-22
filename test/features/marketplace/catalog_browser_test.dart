import 'dart:convert';
import 'dart:ui' as ui;

import 'package:acendra/features/marketplace/presentation/widgets/course_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/catalog_preview_app.dart';

const _captureKey = ValueKey('catalog-capture');

Future<void> _mount(
  WidgetTester tester, {
  double width = 390,
  bool dark = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: CatalogPreviewApp(dark: dark, textScale: scale),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('catalog $width dark=$dark scale=$scale', (tester) async {
          await _mount(tester, width: width, dark: dark, scale: scale);
          expect(find.text('Explore Courses'), findsOneWidget);
          expect(find.text('6 Courses'), findsOneWidget);
          final grid = find.byType(CourseGrid);
          await tester.scrollUntilVisible(
            find.text('Flutter Development Essentials'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.descendant(of: grid, matching: find.text('Development')),
            findsWidgets,
          );
          expect(
            find.text(
              'Build responsive apps with Dart, reusable widgets and practical projects.',
            ),
            findsOneWidget,
          );
          expect(find.text('LKR 12,500.00'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('CATALOG_CAPTURE')) {
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(_captureKey),
              );
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              // The caller saves JSON print events as PNGs; no browser filesystem.
              // ignore: avoid_print
              print(
                'CATALOG_PNG:${width.toInt()}-${dark ? 'dark' : 'light'}-${scale.toInt()}:'
                '${base64Encode(bytes!.buffer.asUint8List())}',
              );
            });
          }
        });
      }
    }
  }

  testWidgets(
    'catalog search, category, price sort and real detail navigation',
    (tester) async {
      await _mount(tester);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Design'));
      await tester.tap(find.widgetWithText(FilterChip, 'Design'));
      await tester.pumpAndSettle();
      expect(find.text('2 Courses'), findsOneWidget);
      expect(find.text('Flutter Development Essentials'), findsNothing);

      await tester.ensureVisible(
        find.widgetWithText(FilterChip, 'All Courses'),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'All Courses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: low to high').last);
      await tester.pumpAndSettle();
      final titles = find.descendant(
        of: find.byType(CourseGrid),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.maxLines == 2,
        ),
      );
      expect(tester.widget<Text>(titles.first).data, 'Project Planning Basics');

      await tester.tap(find.text('Price: low to high'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(titles.first).data,
        'Flutter Development Essentials',
      );

      // Category navigation may have scrolled the search field out of view.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'no matching course');
      await tester.pumpAndSettle();
      expect(find.text('0 Courses'), findsOneWidget);
      expect(
        find.text('No courses found. Try a different word or category.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(SearchBar), 'Flutter');
      await tester.pumpAndSettle();
      expect(find.text('1 Course'), findsOneWidget);
      await tester.ensureVisible(find.text('Flutter Development Essentials'));
      await tester.tap(find.text('Flutter Development Essentials'));
      await tester.pumpAndSettle();
      expect(find.text('Course Details'), findsOneWidget);
      expect(find.textContaining('Synthetic course details'), findsOneWidget);
      expect(find.text('Buy Course'), findsOneWidget);
      await tester.tap(find.text('Buy Course'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No order has been created.'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Course Details'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Explore Courses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
