import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/dashboard/data/dashboard_sample_data.dart';
import 'package:acendra/features/dashboard/domain/entities/hero_slide.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_category_chip.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_category_row.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_course_card.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_featured_courses_grid.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_hero_carousel.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_why_learn_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  bool dark = false,
  double scale = 1,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  ),
);

void main() {
  for (final width in [320.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('layout at $width, dark=$dark and enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _host(
            Column(
              children: [
                DashboardHeroCarousel(
                  slides: sampleHeroSlides,
                  onAction: (_) {},
                ),
                DashboardCategoryRow(
                  categories: sampleCategories,
                  onCategorySelected: (_) {},
                  onViewAll: () {},
                ),
                DashboardFeaturedCoursesGrid(
                  courses: sampleCourses,
                  categoryNames: {
                    for (final category in sampleCategories)
                      category.id: category.name,
                  },
                  onCourseSelected: (_) {},
                  onViewAll: () {},
                ),
                const DashboardWhyLearnSection(items: sampleWhyLearnItems),
              ],
            ),
            dark: dark,
            scale: 2,
            reduceMotion: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cards = find.byType(DashboardCourseCard);
        expect(cards, findsNWidgets(4));
        final first = tester.getTopLeft(cards.at(0));
        final second = tester.getTopLeft(cards.at(1));
        if (width < 632) {
          expect(first.dx, second.dx);
          expect(second.dy, greaterThan(first.dy));
        } else {
          expect(first.dy, second.dy);
          expect(second.dx, greaterThan(first.dx));
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('empty collections have readable states', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            DashboardHeroCarousel(slides: []),
            DashboardCategoryRow(categories: []),
            DashboardFeaturedCoursesGrid(courses: []),
            DashboardWhyLearnSection(items: []),
          ],
        ),
      ),
    );
    expect(find.text(DashboardCopy.noSlides), findsOneWidget);
    expect(find.text(DashboardCopy.noCategories), findsOneWidget);
    expect(find.text(DashboardCopy.noCourses), findsOneWidget);
    expect(find.text(DashboardCopy.noHighlights), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category controls support keyboard activation', (tester) async {
    Object? selection;
    await tester.pumpWidget(
      _host(
        DashboardCategoryChip(
          category: sampleCategories.first,
          onSelected: (value) => selection = value,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(identical(selection, sampleCategories.first), isTrue);
  });

  testWidgets('background carousel pauses until the application resumes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const DashboardHeroCarousel(slides: sampleHeroSlides)),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 9));
    expect(
      find.text(sampleHeroSlides.first.headline).hitTestable(),
      findsOneWidget,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text(sampleHeroSlides[1].headline).hitTestable(),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('callbacks preserve category, course and CTA identity', (
    tester,
  ) async {
    Object? selection;
    var viewAll = 0;
    await tester.pumpWidget(
      _host(
        DashboardCategoryRow(
          categories: sampleCategories,
          onCategorySelected: (value) => selection = value,
          onViewAll: () => viewAll++,
        ),
      ),
    );
    await tester.tap(find.byType(DashboardCategoryChip).first);
    expect(identical(selection, sampleCategories.first), isTrue);
    await tester.tap(find.text(DashboardCopy.viewAll));
    expect(viewAll, 1);

    await tester.pumpWidget(
      _host(
        DashboardCourseCard(
          course: sampleCourses.first,
          categoryName: sampleCategories.first.name,
          onSelected: (value) => selection = value,
        ),
      ),
    );
    expect(find.text('LKR 4,500.00'), findsOneWidget);
    await tester.ensureVisible(
      find.byTooltip(DashboardCopy.openCourse(sampleCourses.first.title)),
    );
    await tester.tap(
      find.byTooltip(DashboardCopy.openCourse(sampleCourses.first.title)),
    );
    expect(identical(selection, sampleCourses.first), isTrue);

    await tester.pumpWidget(
      _host(
        DashboardHeroCarousel(
          slides: [sampleHeroSlides.first],
          onAction: (value) => selection = value,
        ),
      ),
    );
    await tester.tap(find.text(sampleHeroSlides.first.ctaLabel));
    expect(identical(selection, sampleHeroSlides.first), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('carousel advances, pauses and disposes its timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const DashboardHeroCarousel(slides: sampleHeroSlides)),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text(sampleHeroSlides[1].headline).hitTestable(),
      findsOneWidget,
    );
    final selected = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byTooltip(DashboardCopy.slide(2, 3)),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.selected != null,
            ),
          )
          .first,
    );
    expect(selected.properties.selected, isTrue);
    await tester.tap(find.byTooltip(DashboardCopy.pauseSlides));
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(
      find.text(sampleHeroSlides[1].headline).hitTestable(),
      findsOneWidget,
    );
    expect(find.byTooltip(DashboardCopy.resumeSlides), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables autoplay and keeps manual navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const DashboardHeroCarousel(slides: sampleHeroSlides),
        reduceMotion: true,
      ),
    );
    await tester.pump(const Duration(seconds: 9));
    expect(
      find.text(sampleHeroSlides.first.headline).hitTestable(),
      findsOneWidget,
    );
    expect(find.byTooltip(DashboardCopy.pauseSlides), findsNothing);
    await tester.tap(find.byTooltip(DashboardCopy.nextSlide));
    await tester.pumpAndSettle();
    expect(
      find.text(sampleHeroSlides[1].headline).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(DashboardCopy.slide(3, 3)));
    await tester.pumpAndSettle();
    expect(
      find.text(sampleHeroSlides.last.headline).hitTestable(),
      findsOneWidget,
    );
    // Replacing a collection after paging must reset the controller safely.
    await tester.pumpWidget(
      _host(
        DashboardHeroCarousel(slides: <HeroSlide>[sampleHeroSlides.first]),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(sampleHeroSlides.first.headline).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
