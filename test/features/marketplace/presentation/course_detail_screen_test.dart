import 'dart:async';

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _id = '22222222-2222-4222-8222-222222222222';

const _detail = CourseDetail(
  id: _id,
  slug: 'sample',
  title: 'Sample Course',
  shortDescription: 'Synthetic blurb',
  description: 'Synthetic long description',
  priceMinor: 1500000,
  currencyCode: 'LKR',
  publishedAt: '2026-10-15T00:00:00Z',
  categoryId: 'cat-1',
  sections: [
    CurriculumSection(
      id: 's1',
      title: 'Module One',
      position: 0,
      lessons: [
        LessonItem(
          id: 'l1',
          title: 'Free intro',
          lessonType: 'video',
          position: 0,
          isPreview: true,
          durationSeconds: 120,
        ),
        LessonItem(
          id: 'l2',
          title: 'Paid lesson',
          lessonType: 'video',
          position: 1,
          isPreview: false,
          durationSeconds: 600,
        ),
      ],
    ),
  ],
);

void main() {
  Future<GoRouter> mount(
    WidgetTester tester, {
    CourseDetail? detail = _detail,
    Object? error,
    bool owned = false,
    Size size = const Size(390, 1400),
    ThemeData? theme,
    bool pushed = false,
    Future<CourseDetail>? pending,
    String origin = '/marketplace',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: pushed ? origin : '/course',
      routes: [
        GoRoute(
          path: '/marketplace',
          builder: (_, _) => const Scaffold(body: Text('Marketplace')),
        ),
        GoRoute(
          path: '/course',
          builder: (_, _) => const CourseDetailScreen(courseId: _id),
        ),
        for (final path in ['/dashboard/home', '/dashboard/courses'])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('Origin $path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseDetailProvider(_id).overrideWith((ref) async {
            if (error != null) throw error;
            if (pending != null) return pending;
            return detail!;
          }),
          isEnrolledProvider(_id).overrideWith((ref) async => owned),
          categoriesProvider.overrideWith(
            (ref) async => [
              const Category(id: 'cat-1', name: 'Flutter', slug: 'flutter'),
            ],
          ),
        ],
        child: MaterialApp.router(
          theme: theme ?? AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    if (pushed) router.push('/course');
    if (pending != null) {
      await tester.pump();
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
    return router;
  }

  testWidgets('shows header, category, chips, about and curriculum', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Course Details'), findsOneWidget);
    expect(find.text('FLUTTER'), findsOneWidget);
    expect(find.text('Sample Course'), findsOneWidget);
    expect(find.text('1 module'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Wrap), matching: find.text('2 lessons')),
      findsOneWidget,
    );
    expect(find.text('About This Course'), findsOneWidget);
    expect(find.text('Course Curriculum'), findsOneWidget);
  });

  testWidgets('footer shows price and Buy Course when not owned', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('LKR 15,000.00'), findsOneWidget);
    expect(find.text('Buy Course'), findsOneWidget);
    expect(find.text('You own this course'), findsNothing);
  });

  testWidgets('footer shows ownership and Go to Course when owned', (
    tester,
  ) async {
    await mount(tester, owned: true);
    expect(find.text('You own this course'), findsOneWidget);
    expect(find.text('Go to Course'), findsOneWidget);
  });

  testWidgets('footer stays visible after scrolling', (tester) async {
    await mount(tester, size: const Size(390, 500));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pump();
    expect(find.text('Buy Course'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Buy Course')).dy, lessThan(500));
  });

  testWidgets('locks paid lessons, keeps previews open, for non-owners', (
    tester,
  ) async {
    await mount(tester);
    await tester.ensureVisible(
      find.widgetWithText(ExpansionTile, 'Module One'),
    );
    await tester.tap(find.widgetWithText(ExpansionTile, 'Module One'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('owners see no locks and see lesson durations', (tester) async {
    await mount(tester, owned: true);
    await tester.ensureVisible(
      find.widgetWithText(ExpansionTile, 'Module One'),
    );
    await tester.tap(find.widgetWithText(ExpansionTile, 'Module One'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text('2 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
  });

  testWidgets('back pops to the previous screen', (tester) async {
    await mount(tester, pushed: true);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Marketplace'), findsOneWidget);
  });

  for (final origin in ['/dashboard/home', '/dashboard/courses']) {
    for (final phase in ['loaded', 'loading', 'error']) {
      testWidgets('back restores $origin while course is $phase', (
        tester,
      ) async {
        final router = await mount(
          tester,
          pushed: true,
          origin: origin,
          pending: phase == 'loading' ? Completer<CourseDetail>().future : null,
          error: phase == 'error' ? StateError('private detail') : null,
        );
        expect(find.byType(BackButton), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, origin);
        expect(find.text('Origin $origin'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('error state is shown without internal details and can retry', (
    tester,
  ) async {
    await mount(tester, error: StateError('private db detail'));
    expect(find.text('Failed to load course details.'), findsOneWidget);
    expect(find.textContaining('private db detail'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Buy Course'), findsNothing);
  });

  testWidgets('empty curriculum shows a message and omits blank about card', (
    tester,
  ) async {
    await mount(
      tester,
      detail: const CourseDetail(
        id: _id,
        slug: 's',
        title: 'Bare',
        shortDescription: '',
        priceMinor: 0,
        currencyCode: 'LKR',
        publishedAt: '2026-10-15T00:00:00Z',
        sections: [],
      ),
    );
    expect(find.text('No curriculum available yet.'), findsOneWidget);
    expect(find.text('About This Course'), findsNothing);
    expect(find.text('0 modules'), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(768, 1024), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('renders without overflow at ${size.width}px dark=$dark', (
        tester,
      ) async {
        await mount(
          tester,
          size: size,
          theme: dark ? AppTheme.dark : AppTheme.light,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Buy Course'), findsOneWidget);
      });
    }
  }
}
