import 'dart:async';

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/dashboard/data/dashboard_sample_data.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_home_screen.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_category_chip.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_course_card.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_hero_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const DashboardHomeData _empty = (
  slides: [],
  categories: [],
  courses: [],
  highlights: [],
);

Widget _app(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: true, textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

const DashboardHomeData _fixture = (
  slides: sampleHeroSlides,
  categories: sampleCategories,
  courses: sampleCourses,
  highlights: sampleWhyLearnItems,
);
Widget _fixtureScope({required Widget child}) => ProviderScope(
  overrides: [dashboardHomeProvider.overrideWith((ref) => _fixture)],
  child: child,
);
void main() {
  testWidgets('screen composes all four overridden source providers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroSlidesProvider.overrideWithValue([sampleHeroSlides[1]]),
          dashboardCategoriesProvider.overrideWith(
            (ref) async => [sampleCategories[1]],
          ),
          featuredCoursesProvider.overrideWith(
            (ref) async => [sampleCourses[1]],
          ),
          whyLearnItemsProvider.overrideWithValue([sampleWhyLearnItems[1]]),
        ],
        child: _app(const DashboardHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(sampleHeroSlides[1].headline), findsOneWidget);
    expect(find.text(sampleHeroSlides.first.headline), findsNothing);
    expect(find.byType(DashboardCategoryChip), findsOneWidget);
    expect(find.byType(DashboardCourseCard), findsOneWidget);
    expect(find.text(sampleCourses[1].title), findsOneWidget);
    expect(find.text(sampleWhyLearnItems[1].title), findsOneWidget);
    expect(find.textContaining('sample content'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pending data becomes readable empty sections', (tester) async {
    final pending = Completer<DashboardHomeData>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardHomeProvider.overrideWith((ref) => pending.future),
        ],
        child: _app(const DashboardHomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel(DashboardCopy.loading), findsOneWidget);
    pending.complete(_empty);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(DashboardCopy.noSlides), findsOneWidget);
    expect(find.text(DashboardCopy.noCategories), findsOneWidget);
    expect(find.text(DashboardCopy.noCourses), findsOneWidget);
    expect(find.text(DashboardCopy.noHighlights), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('errors use public copy and retry reloads the provider', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardHomeProvider.overrideWith((ref) {
            if (++attempts == 1) throw StateError('private backend diagnostic');
            return _empty;
          }),
        ],
        child: _app(const DashboardHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(DashboardCopy.loadError), findsOneWidget);
    expect(find.textContaining('private backend'), findsNothing);
    await tester.tap(find.text(DashboardCopy.retry));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text(DashboardCopy.noCourses), findsOneWidget);
    expect(find.text(DashboardCopy.loadError), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final useHero in [true, false]) {
    testWidgets('browse opens existing marketplace, hero=$useHero', (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardHomeScreen()),
          GoRoute(
            path: '/marketplace',
            builder: (_, _) => const Scaffold(body: Text('Marketplace target')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        _fixtureScope(
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = useHero
          ? find.descendant(
              of: find.byType(DashboardHeroCarousel),
              matching: find.text(sampleHeroSlides.first.ctaLabel),
            )
          : find.text(DashboardCopy.viewAll).first;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/marketplace');
      expect(find.text('Marketplace target'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('retry also invalidates a failed underlying source', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardCategoriesProvider.overrideWith((ref) async => []),
          featuredCoursesProvider.overrideWith((ref) async => []),
          heroSlidesProvider.overrideWith((ref) {
            if (++attempts == 1) throw StateError('source unavailable');
            return [sampleHeroSlides.first];
          }),
        ],
        child: _app(const DashboardHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(DashboardCopy.loadError), findsOneWidget);
    await tester.tap(find.text(DashboardCopy.retry));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text(sampleHeroSlides.first.headline), findsOneWidget);
    expect(find.text(DashboardCopy.loadError), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('course and category actions use real catalog identities', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardHomeScreen()),
        GoRoute(
          path: '/marketplace',
          builder: (_, _) => const Scaffold(body: Text('Catalog')),
        ),
        GoRoute(
          path: '/marketplace/:id',
          builder: (_, state) =>
              Scaffold(body: Text(state.pathParameters['id']!)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _fixtureScope(
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final course = find.byTooltip(
      DashboardCopy.openCourse(sampleCourses.first.title),
    );
    await tester.ensureVisible(course);
    await tester.tap(course);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/marketplace/${sampleCourses.first.id}',
    );
    router.go('/');
    await tester.pumpAndSettle();
    final category = find.byType(DashboardCategoryChip).first;
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/marketplace');
    expect(find.textContaining('sample category'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('screen callbacks receive original category/course identities', (
    tester,
  ) async {
    Object? selected;
    var browseCalls = 0;
    await tester.pumpWidget(
      _fixtureScope(
        child: _app(
          DashboardHomeScreen(
            onBrowseCourses: () => browseCalls++,
            onCategorySelected: (value) => selected = value,
            onCourseSelected: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DashboardHeroCarousel),
        matching: find.text(sampleHeroSlides.first.ctaLabel),
      ),
    );
    expect(browseCalls, 1);
    final category = find.byType(DashboardCategoryChip).first;
    await tester.ensureVisible(category);
    await tester.tap(category);
    expect(identical(selected, sampleCategories.first), isTrue);
    final course = find.byTooltip(
      DashboardCopy.openCourse(sampleCourses.first.title),
    );
    await tester.ensureVisible(course);
    await tester.tap(course);
    expect(identical(selected, sampleCourses.first), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('composed home scrolls at $width, dark=$dark, 200% text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _fixtureScope(
            child: _app(const DashboardHomeScreen(), dark: dark, scale: 2),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final last = find.text(sampleWhyLearnItems.last.subtitle);
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
