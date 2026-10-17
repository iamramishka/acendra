@TestOn('browser')
library;

import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_home_screen.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_saved_screen.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/domain/repositories/learning_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../features/my_courses/fakes/fake_my_courses_repository.dart';

class _UnavailableLearningRepository implements LearningRepository {
  @override
  Future<List<CurriculumSection>> getCurriculumWithLessons(
    String courseId,
  ) async => throw StateError('Unavailable');
  @override
  Future<LessonContent> getLessonContent(String lessonId) async =>
      throw StateError('Unavailable');
  @override
  Future<bool> isEnrolledOrPreview(String courseId, String lessonId) async =>
      false;
}

Widget _app({required bool sessionRestored, required bool isAuthenticated}) =>
    ProviderScope(
      overrides: [
        sessionRestoredProvider.overrideWithValue(sessionRestored),
        isAuthenticatedProvider.overrideWithValue(isAuthenticated),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
        learningRepositoryProvider.overrideWithValue(
          _UnavailableLearningRepository(),
        ),
        myCoursesRepositoryProvider.overrideWithValue(
          FakeMyCoursesRepository(shouldThrow: true),
        ),
      ],
      child: Consumer(
        builder: (_, ref, _) => MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: ref.watch(appRouterProvider),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );

void main() {
  for (final path in [RouteNames.dashboardHome, RouteNames.savedCourses]) {
    testWidgets('signed-out deep link $path requires login', (tester) async {
      await tester.pumpWidget(
        _app(sessionRestored: true, isAuthenticated: false),
      );
      await tester.pumpAndSettle();
      final router = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      ).read(appRouterProvider);
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, RouteNames.login);
      expect(find.byType(DashboardHomeScreen), findsNothing);
      expect(find.byType(DashboardSavedScreen), findsNothing);
    });

    testWidgets('authenticated deep link $path uses StudentShell', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(sessionRestored: true, isAuthenticated: true),
      );
      await tester.pumpAndSettle();
      final router = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      ).read(appRouterProvider);
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(find.byType(StudentShell), findsOneWidget);
      expect(
        find.byType(
          path == RouteNames.dashboardHome
              ? DashboardHomeScreen
              : DashboardSavedScreen,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('four student tabs select their real routed destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(sessionRestored: true, isAuthenticated: true));
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(appRouterProvider);
    const paths = [
      RouteNames.dashboardHome,
      RouteNames.myCourses,
      RouteNames.savedCourses,
      RouteNames.profile,
    ];
    for (final index in [1, 2, 3, 0]) {
      await tester.tap(find.byType(NavigationDestination).at(index));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, paths[index]);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
      expect(tester.takeException(), isNull);
    }
    router.go(RouteNames.profileEdit);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  for (final route in ['/dashboard/courses', '/learn/course-fixture']) {
    testWidgets(
      'authenticated $route reports unavailable without content access',
      (tester) async {
        await tester.pumpWidget(
          _app(sessionRestored: true, isAuthenticated: true),
        );
        await tester.pumpAndSettle();
        final router = ProviderScope.containerOf(
          tester.element(find.byType(Consumer)),
        ).read(appRouterProvider);
        router.go(route);
        await tester.pumpAndSettle();
        expect(
          find.text(
            route.startsWith('/learn/')
                ? 'Could not load course content.'
                : 'Failed to load your courses. Please try again.',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('unauthenticated $route still requires login', (tester) async {
      await tester.pumpWidget(
        _app(sessionRestored: true, isAuthenticated: false),
      );
      await tester.pumpAndSettle();
      final router = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      ).read(appRouterProvider);
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
      expect(find.textContaining('currently unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unauthenticated user lands on login screen', (tester) async {
    await tester.pumpWidget(
      _app(sessionRestored: true, isAuthenticated: false),
    );
    await tester.pumpAndSettle();
    // Login screen shows "Sign in" button.
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('authenticated user is redirected from login to dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(_app(sessionRestored: true, isAuthenticated: true));
    await tester.pumpAndSettle();
    // Initial location /login redirects to /dashboard for authenticated users.
    expect(find.byType(DashboardHomeScreen), findsOneWidget);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(appRouterProvider);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.dashboardHome,
    );
  });

  testWidgets('unauthenticated user can access forgot-password page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(sessionRestored: true, isAuthenticated: false),
    );
    await tester.pumpAndSettle();
    // Forgot password is a public route — no redirect to login.
    // We verify by navigating there directly.
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(appRouterProvider);
    router.go('/forgot-password');
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('unauthenticated user is redirected from dashboard to login', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(sessionRestored: true, isAuthenticated: false),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(appRouterProvider);
    router.go('/dashboard');
    await tester.pumpAndSettle();
    // Should be redirected back to login.
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('no redirect fires when session not yet restored', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(sessionRestored: false, isAuthenticated: false),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
