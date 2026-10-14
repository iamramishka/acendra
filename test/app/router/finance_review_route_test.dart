import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/admin/presentation/screens/finance_review_screen.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required bool authenticated,
    required Brightness brightness,
  }) async {
    final container = ProviderContainer(
      overrides: [
        financeQueueProvider.overrideWith(
          (ref) async => throw Exception('Unavailable'),
        ),
        sessionRestoredProvider.overrideWithValue(true),
        isAuthenticatedProvider.overrideWithValue(authenticated),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: ThemeData(
            brightness: brightness,
            extensions: [
              AppThemeExtension.fromTokens(
                brightness == Brightness.light
                    ? AppColors.light
                    : AppColors.dark,
              ),
            ],
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/admin/finance-review');
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 768.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'finance route renders unavailable finance queue at $width / $brightness and fails closed',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await open(tester, authenticated: true, brightness: brightness);
          expect(find.byType(FinanceReviewScreen), findsOneWidget);
          expect(
            find.textContaining('Finance review is unavailable'),
            findsOneWidget,
          );
          expect(find.text('Record approval'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('unauthenticated finance route redirects to login', (
    tester,
  ) async {
    await open(tester, authenticated: false, brightness: Brightness.light);
    expect(find.byType(FinanceReviewScreen), findsNothing);
    expect(find.textContaining('Synthetic preview'), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
