import 'dart:async';

import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes/fake_course_repository.dart';

class _PendingRepository extends FakeCourseRepository {
  final pending = Completer<List<CourseSummary>>();

  @override
  Future<List<CourseSummary>> listPublished() => pending.future;
}

Future<({GoRouter router, ProviderContainer container})> _pump(
  WidgetTester tester, {
  String initial = RouteNames.dashboardHome,
  FakeCourseRepository? repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      authStreamProvider.overrideWith((ref) => const Stream.empty()),
      navigationAccessProvider.overrideWith((ref) async => false),
      courseRepositoryProvider.overrideWithValue(
        repository ?? FakeCourseRepository(),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (_, _, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboardHome,
            builder: (_, _) => const Text('Home fixture'),
          ),
          GoRoute(
            path: RouteNames.marketplace,
            builder: (_, state) => MarketplaceScreen(
              focusSearch: state.uri.queryParameters['search'] == 'true',
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return (router: router, container: container);
}

void main() {
  testWidgets('returning to marketplace restores the visible active query', (
    tester,
  ) async {
    final app = await _pump(tester, initial: RouteNames.marketplace);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Design');
    app.router.go(RouteNames.dashboardHome);
    await tester.pumpAndSettle();
    app.router.go(RouteNames.marketplace);
    await tester.pumpAndSettle();
    expect(app.container.read(searchQueryProvider), 'Design');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Design',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'AppBar search opens and refocuses search without clearing query',
    (tester) async {
      final app = await _pump(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(DashboardCopy.searchCourses));
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.path,
        RouteNames.marketplace,
      );
      expect(
        app.router.routeInformationProvider.value.uri.queryParameters['search'],
        'true',
      );
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.enterText(find.byType(SearchBar), 'flutter');
      expect(app.container.read(searchQueryProvider), 'flutter');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).focusNode!.hasFocus,
        isFalse,
      );
      await tester.tap(find.byTooltip(DashboardCopy.searchCourses));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).focusNode!.hasFocus,
        isTrue,
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'flutter',
      );
      expect(app.container.read(searchQueryProvider), 'flutter');
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search request focuses when delayed catalog data arrives', (
    tester,
  ) async {
    final repository = _PendingRepository();
    await _pump(
      tester,
      initial: '${RouteNames.marketplace}?search=true',
      repository: repository,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pending.complete([]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SearchBar>(find.byType(SearchBar)).focusNode!.hasFocus,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary marketplace entry does not autofocus search', (
    tester,
  ) async {
    await _pump(tester, initial: RouteNames.marketplace);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SearchBar>(find.byType(SearchBar)).focusNode!.hasFocus,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
