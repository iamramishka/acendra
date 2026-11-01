import 'dart:async';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_failure_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_pending_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

StudentOrder order({
  String id = 'order-1',
  String course = 'course-1',
  String method = 'online',
  String status = 'pending_payment',
}) => StudentOrder(
  id: id,
  courseId: course,
  title: 'Backend Course',
  number: 'ORD-REAL',
  amountMinor: 12345,
  currency: 'LKR',
  method: method,
  status: status,
);

class Repo implements StudentOrderRepository {
  Repo(this.result);
  final Future<StudentOrder> Function(String actor, String id) result;
  @override
  Future<StudentOrder?> findOpen(String actor, String course) async => null;
  @override
  Future<StudentOrder> read(String actor, String id) => result(actor, id);
}

void main() {
  for (final entry in <String, Widget>{
    'success': const PaymentSuccessScreen(
      orderId: 'order-1',
      courseId: 'course-1',
    ),
    'pending': const PaymentPendingScreen(
      orderId: 'order-1',
      courseId: 'course-1',
    ),
    'cancel': const PaymentFailureScreen(
      orderId: 'order-1',
      courseId: 'course-1',
    ),
  }.entries) {
    testWidgets(
      '${entry.key} URL cannot assert payment before backend verification',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutActorProvider.overrideWithValue('student'),
              studentOrderRepositoryProvider.overrideWithValue(
                Repo((_, _) async => order()),
              ),
            ],
            child: MaterialApp(theme: AppTheme.light, home: entry.value),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Checking your payment'), findsOneWidget);
        expect(find.text('Payment verified'), findsNothing);
        expect(find.text('Backend Course'), findsOneWidget);
        expect(find.textContaining('receipt'), findsNothing);
        expect(find.textContaining('support@'), findsNothing);
      },
    );
  }
  for (final bad in [
    'missing',
    'wrong-order',
    'wrong-course',
    'bank',
    'error',
  ]) {
    testWidgets('$bad fails closed without financial details', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutActorProvider.overrideWithValue('student'),
            studentOrderRepositoryProvider.overrideWithValue(
              Repo((_, _) async {
                if (bad == 'error') throw StateError('private_table secret');
                return order(
                  id: bad == 'wrong-order' ? 'other' : 'order-1',
                  course: bad == 'wrong-course' ? 'other' : 'course-1',
                  method: bad == 'bank' ? 'bank_transfer' : 'online',
                );
              }),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: PaymentSuccessScreen(
              orderId: bad == 'missing' ? null : 'order-1',
              courseId: 'course-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Backend Course'), findsNothing);
      expect(find.textContaining('private_table'), findsNothing);
      expect(find.text('View Order History'), findsOneWidget);
    });
  }
  testWidgets('cancel return respects paid backend order', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutActorProvider.overrideWithValue('student'),
          studentOrderRepositoryProvider.overrideWithValue(
            Repo((_, _) async => order(status: 'paid')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PaymentFailureScreen(orderId: 'order-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Payment verified'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });
  testWidgets('cancel retry uses backend course and history exit works', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/return',
      routes: [
        GoRoute(
          path: '/return',
          builder: (_, _) => const PaymentFailureScreen(orderId: 'order-1'),
        ),
        GoRoute(
          path: '/checkout/:courseId',
          builder: (_, s) => Text('Checkout ${s.pathParameters['courseId']}'),
        ),
        GoRoute(path: '/orders', builder: (_, _) => const Text('History')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutActorProvider.overrideWithValue('student'),
          studentOrderRepositoryProvider.overrideWithValue(
            Repo((_, _) async => order()),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Try Again'));
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout course-1'), findsOneWidget);
    router.go('/return');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View Order History'));
    await tester.tap(find.text('View Order History'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
  });
  testWidgets('account change discards late previous-account order', (
    tester,
  ) async {
    final actor = StateProvider<String?>((ref) => 'a');
    final pending = Completer<StudentOrder>();
    final container = ProviderContainer(
      overrides: [
        checkoutActorProvider.overrideWith((ref) => ref.watch(actor)),
        studentOrderRepositoryProvider.overrideWithValue(
          Repo(
            (a, _) => a == 'a'
                ? pending.future
                : Future.error(StateError('Unavailable')),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PaymentSuccessScreen(orderId: 'order-1'),
        ),
      ),
    );
    await tester.pump();
    container.read(actor.notifier).state = 'b';
    await tester.pump();
    pending.complete(order(status: 'paid'));
    await tester.pumpAndSettle();
    expect(find.text('Payment verified'), findsNothing);
    expect(find.text('Backend Course'), findsNothing);
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('payment layout $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutActorProvider.overrideWithValue('student'),
              studentOrderRepositoryProvider.overrideWithValue(
                Repo((_, _) async => order()),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: const PaymentPendingScreen(orderId: 'order-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('View Order History'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
