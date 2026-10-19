import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Auth extends AuthRepository {
  _Auth() : super.forTesting();
  final registrations = <String>[];

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    registrations.add(email);
  }
}

void main() {
  testWidgets('registration fits narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful signup navigates with pending verification email', (
    tester,
  ) async {
    final auth = _Auth();
    final router = GoRouter(
      initialLocation: RouteNames.register,
      routes: [
        GoRoute(
          path: RouteNames.register,
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: RouteNames.verifyEmail,
          builder: (_, _) => const VerifyEmailScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    for (final entry in [
      'Jane Doe',
      'jane@example.com',
      'password123',
      'password123',
    ].asMap().entries) {
      await tester.enterText(find.byType(TextField).at(entry.key), entry.value);
    }
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(auth.registrations, ['jane@example.com']);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.verifyEmail,
    );
    expect(find.text('ja••@example.com'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('learning deep link back navigates to My Courses', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/review-lesson',
      routes: [
        GoRoute(
          path: '/review-lesson',
          builder: (_, _) => const LearningShell(child: Text('Lesson')),
        ),
        GoRoute(
          path: RouteNames.myCourses,
          builder: (_, _) => const Scaffold(body: Text('Course list')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.myCourses,
    );
    expect(find.text('Course list'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
