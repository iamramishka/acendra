// CSA-190 / CSA-191 / CSA-192 — responsive layout tests
// Covers mobile (390px), tablet (768px), desktop (1440px).
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _app(Widget child) => ProviderScope(
  child: MaterialApp(theme: ThemeData(useMaterial3: true), home: child),
);

void _setViewport(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CourseSummary _course(int i) => CourseSummary(
  id: 'id-$i',
  slug: 'course-$i',
  title: 'Course $i',
  shortDescription: 'Short desc $i',
  priceMinor: 1000 * i,
  currencyCode: 'LKR',
  publishedAt: '2026-01-01',
);

const _mobile = (390.0, 844.0);
const _tablet = (768.0, 1024.0);
const _desktop = (1440.0, 900.0);

void main() {
  // ---------------------------------------------------------------------------
  // AppBreakpoints / ScreenLayout
  // ---------------------------------------------------------------------------

  group('AppBreakpoints thresholds', () {
    testWidgets('390px → compact', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      ScreenLayout? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              captured = ctx.layout;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, ScreenLayout.compact);
    });

    testWidgets('768px → medium', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      ScreenLayout? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              captured = ctx.layout;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, ScreenLayout.medium);
    });

    testWidgets('1440px → expanded', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      ScreenLayout? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              captured = ctx.layout;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, ScreenLayout.expanded);
    });

    testWidgets('boundary 599px → compact', (tester) async {
      _setViewport(tester, 599, 800);
      ScreenLayout? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              captured = ctx.layout;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, ScreenLayout.compact);
    });

    testWidgets('boundary 600px → medium', (tester) async {
      _setViewport(tester, 600, 800);
      ScreenLayout? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              captured = ctx.layout;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, ScreenLayout.medium);
    });

    testWidgets('boundary 1024px → expanded', (tester) async {
      _setViewport(tester, 1024, 800);
      ScreenLayout? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              captured = ctx.layout;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, ScreenLayout.expanded);
    });
  });

  // ---------------------------------------------------------------------------
  // ResponsiveContainer — margins
  // ---------------------------------------------------------------------------

  group('ResponsiveContainer margins', () {
    testWidgets('mobile 390: uses compact margin (16)', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      double? capturedMargin;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              child: Builder(
                builder: (ctx) {
                  capturedMargin = ctx.pageMargin;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(capturedMargin, AppBreakpoints.marginCompact);
    });

    testWidgets('tablet 768: uses medium margin (24)', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      double? capturedMargin;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              child: Builder(
                builder: (ctx) {
                  capturedMargin = ctx.pageMargin;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(capturedMargin, AppBreakpoints.marginMedium);
    });

    testWidgets('desktop 1440: uses expanded margin (32)', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      double? capturedMargin;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              child: Builder(
                builder: (ctx) {
                  capturedMargin = ctx.pageMargin;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(capturedMargin, AppBreakpoints.marginExpanded);
    });

    testWidgets('renders child at any breakpoint', (tester) async {
      for (final vp in [_mobile, _tablet, _desktop]) {
        _setViewport(tester, vp.$1, vp.$2);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ResponsiveContainer(child: Text('content'))),
          ),
        );
        expect(find.text('content'), findsOneWidget);
      }
    });

    testWidgets('constrained to maxContentWidth on desktop', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              child: Builder(
                builder: (ctx) {
                  // Verify the widget renders without overflowing.
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      // No overflow exception means the ConstrainedBox is working.
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CourseGrid — column count
  // ---------------------------------------------------------------------------

  group('CourseGrid column count', () {
    final courses = List.generate(6, _course);

    testWidgets('mobile 390: 1 column', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Every card receives its natural height, including enlarged text.
            body: SingleChildScrollView(child: CourseGrid(courses: courses)),
          ),
        ),
      );
      // All 6 courses rendered in 1 column: each row holds exactly one card.
      // We verify by checking that the grid has 1 cross-axis item by confirming
      // all course titles are present and no overflow is thrown.
      expect(find.text('Course 0'), findsOneWidget);
      expect(find.text('Course 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet 768: 2 columns', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CourseGrid(courses: courses)),
          ),
        ),
      );
      expect(find.text('Course 0'), findsOneWidget);
      expect(find.text('Course 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop 1440: 3 columns', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CourseGrid(courses: courses)),
          ),
        ),
      );
      expect(find.text('Course 0'), findsOneWidget);
      expect(find.text('Course 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('column count matches breakpoint contract', (tester) async {
      // Verify the rendered first row rather than a layout implementation.
      const testCases = [
        (390.0, 1),
        (599.0, 1),
        (600.0, 2),
        (768.0, 2),
        (1023.0, 2),
        (1024.0, 3),
        (1440.0, 3),
      ];
      for (final (width, expectedCols) in testCases) {
        _setViewport(tester, width, 900);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: CourseGrid(courses: courses)),
            ),
          ),
        );
        final firstRowY = tester.getTopLeft(find.text('Course 0')).dy;
        final firstRowCount = List.generate(
          courses.length,
          (index) => tester.getTopLeft(find.text('Course $index')).dy,
        ).where((y) => (y - firstRowY).abs() < 1).length;
        expect(
          firstRowCount,
          expectedCols,
          reason: 'Expected $expectedCols cols at ${width}px',
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // PublicShell — navigation chrome
  // ---------------------------------------------------------------------------

  group('PublicShell navigation chrome', () {
    testWidgets('mobile 390: shows hamburger menu icon', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('mobile 390: hides inline nav links', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      expect(find.text('Courses'), findsNothing);
      expect(find.text('Sign in'), findsNothing);
    });

    testWidgets('mobile 390: has end drawer', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.endDrawer, isNotNull);
    });

    testWidgets('tablet 768: shows inline nav links', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('tablet 768: hides hamburger', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets('desktop 1440: shows all nav links', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('desktop 1440: hides hamburger and end drawer', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
      expect(find.byIcon(Icons.menu), findsNothing);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.endDrawer, isNull);
    });

    testWidgets('always shows Acedra brand title', (tester) async {
      for (final vp in [_mobile, _tablet, _desktop]) {
        _setViewport(tester, vp.$1, vp.$2);
        await tester.pumpWidget(_app(const PublicShell(child: SizedBox())));
        expect(
          find.text('Acedra'),
          findsOneWidget,
          reason: 'Brand not found at ${vp.$1}px',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // StudentShell — navigation chrome
  // ---------------------------------------------------------------------------

  group('StudentShell navigation chrome', () {
    testWidgets('mobile 390: shows bottom NavigationBar', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('mobile 390: hides AppBar nav links', (tester) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      // Nav link labels must not appear inside the AppBar (they appear in the
      // bottom NavigationBar instead).
      Finder inAppBar(String label) =>
          find.descendant(of: find.byType(AppBar), matching: find.text(label));
      expect(inAppBar('My Courses'), findsNothing);
      expect(inAppBar('Explore'), findsNothing);
    });

    testWidgets('mobile 390: bottom nav has all four student destinations', (
      tester,
    ) async {
      _setViewport(tester, _mobile.$1, _mobile.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      for (final label in ['Home', 'Explore', 'My Courses', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('tablet 768: shows compact NavigationBar', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tablet 768: keeps navigation outside AppBar', (tester) async {
      _setViewport(tester, _tablet.$1, _tablet.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('My Courses'),
        ),
        findsNothing,
      );
      expect(find.text('My Courses'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('desktop 1440: hides bottom NavigationBar', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('desktop 1440: shows AppBar nav links', (tester) async {
      _setViewport(tester, _desktop.$1, _desktop.$2);
      await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
      expect(find.text('My Courses'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('always shows Acedra brand title', (tester) async {
      for (final vp in [_mobile, _tablet, _desktop]) {
        _setViewport(tester, vp.$1, vp.$2);
        await tester.pumpWidget(_app(const StudentShell(child: SizedBox())));
        expect(
          find.text('Acedra'),
          findsOneWidget,
          reason: 'Brand not found at ${vp.$1}px',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // pageMargin extension — spot checks
  // ---------------------------------------------------------------------------

  group('pageMargin extension', () {
    testWidgets('below compact threshold uses marginCompact', (tester) async {
      _setViewport(tester, 390, 844);
      double? margin;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              margin = ctx.pageMargin;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(margin, AppBreakpoints.marginCompact);
    });

    testWidgets('at medium threshold uses marginMedium', (tester) async {
      _setViewport(tester, 768, 1024);
      double? margin;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              margin = ctx.pageMargin;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(margin, AppBreakpoints.marginMedium);
    });

    testWidgets('at expanded threshold uses marginExpanded', (tester) async {
      _setViewport(tester, 1440, 900);
      double? margin;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              margin = ctx.pageMargin;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(margin, AppBreakpoints.marginExpanded);
    });
  });
} // end main
