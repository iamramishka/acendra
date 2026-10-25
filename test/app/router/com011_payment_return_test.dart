@TestOn('browser')
library;

import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../features/checkout/com011_payment_status_test.dart'
    show StatusRepository;

void main() => registerPaymentReturnRegressionTests();

void registerPaymentReturnRegressionTests() {
  for (final path in [RouteNames.paymentReturn, RouteNames.paymentCancel]) {
    testWidgets('signed-out $path requires login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sessionRestoredProvider.overrideWithValue(true),
          isAuthenticatedProvider.overrideWithValue(false),
          authStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      addTearDown(router.dispose);
      router.go('$path?order_id=order-1');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, RouteNames.login);
      expect(find.text('Transaction Details'), findsNothing);
    });
  }
  for (final path in [
    '/payments/return?order_id=order-1',
    '/payments/cancel?order_id=order-1',
    '/checkout/course-1/success?order_id=order-1',
    '/checkout/course-1/pending?order_id=order-1',
    '/checkout/course-1/failure?order_id=order-1',
    '/orders/order-1',
  ]) {
    testWidgets(
      'COM-011 direct URL $path recovers backend order without extras',
      (tester) async {
        final repo = StatusRepository();
        final container = ProviderContainer(
          overrides: [
            sessionRestoredProvider.overrideWithValue(true),
            isAuthenticatedProvider.overrideWithValue(true),
            checkoutActorProvider.overrideWithValue('student'),
            authStreamProvider.overrideWith((ref) => const Stream.empty()),
            navigationAccessProvider.overrideWith((ref) async => false),
            studentOrderRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);
        final router = container.read(appRouterProvider);
        addTearDown(router.dispose);
        router.go(path);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Backend Course'), findsOneWidget);
        expect(find.text('Order #ORD-REAL'), findsOneWidget);
        expect(repo.calls, 1);
        expect(find.text('Payment verified'), findsNothing);
      },
    );
  }
  test('return/cancel routes are registered', () {
    final container = ProviderContainer(
      overrides: [
        sessionRestoredProvider.overrideWithValue(true),
        isAuthenticatedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    for (final path in [RouteNames.paymentReturn, RouteNames.paymentCancel]) {
      final match = router.configuration.findMatch(Uri.parse(path));
      expect(match.isError, isFalse);
    }
  });
}
