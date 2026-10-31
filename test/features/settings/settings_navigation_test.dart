import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:acendra/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _mount(
  WidgetTester tester, {
  String location = RouteNames.profile,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: RouteNames.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
        avatarUrlProvider.overrideWith((ref) async => null),
        userPreferencesProvider.overrideWith(
          (ref) async => const UserPreferences(locale: 'en'),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Settings Back preserves an existing navigation stack', (
    tester,
  ) async {
    final router = await _mount(tester);
    router.push(RouteNames.settings);
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Profile Settings uses a reloadable URL and can return', (
    tester,
  ) async {
    final router = await _mount(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, RouteNames.settings);

    // Model initialization from the browser's actual address after a reload.
    final location = router.routeInformationProvider.value.uri.toString();
    await tester.pumpWidget(const SizedBox());
    final reloaded = await _mount(tester, location: location);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      reloaded.routeInformationProvider.value.uri.path,
      RouteNames.profile,
    );
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('direct Settings link has an explicit return to Profile', (
    tester,
  ) async {
    final router = await _mount(tester, location: RouteNames.settings);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RouteNames.profile);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
