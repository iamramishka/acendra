import 'dart:async';

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';

import '../marketplace/fakes/fake_course_repository.dart';

const _pending = StudentOrder(
  id: 'existing-order',
  courseId: 'fake-id-1',
  title: 'Original order title',
  number: 'SYNTHETIC-ORDER',
  amountMinor: 12345,
  currency: 'LKR',
  method: 'online',
  status: 'pending_payment',
);

class _Orders implements StudentOrderRepository {
  final reads = <String>[];
  final pending = Completer<StudentOrder>();

  @override
  Future<StudentOrder?> findOpen(String actor, String courseId) async =>
      _pending;

  @override
  Future<StudentOrder> read(String actor, String orderId) {
    reads.add('$actor:$orderId');
    return pending.future;
  }
}

void main() {
  for (final switchAccount in [false, true]) {
    testWidgets('resume reads the owned order; account switch=$switchAccount', (
      tester,
    ) async {
      final orders = _Orders();
      final actor = StateProvider<String?>((ref) => 'student-a');
      final container = ProviderContainer(
        overrides: [
          checkoutActorProvider.overrideWith((ref) => ref.watch(actor)),
          studentOrderRepositoryProvider.overrideWithValue(orders),
          courseDetailProvider(
            'fake-id-1',
          ).overrideWith((ref) async => fakeDetail),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CheckoutScreen(courseId: 'fake-id-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resume Payment'), findsOneWidget);
      await tester.tap(find.text('Resume Payment'));
      await tester.pump();
      expect(orders.reads, ['student-a:existing-order']);
      if (switchAccount) {
        container.read(actor.notifier).state = 'student-b';
        await tester.pump();
      }
      orders.pending.complete(_pending);
      await tester.pumpAndSettle();
      final restored = container.read(checkoutProvider).asData?.value;
      if (switchAccount) {
        expect(restored, isNull);
        expect(find.text('Original order title'), findsNothing);
      } else {
        expect(restored?.orderId, 'existing-order');
        expect(restored?.amountMinor, 12345);
        expect(find.text('Pay Now'), findsOneWidget);
        expect(find.text('Original order title'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
