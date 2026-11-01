import 'package:acendra/features/orders/data/orders_repository.dart';
import 'package:acendra/features/orders/domain/order_summary.dart';
import 'package:acendra/features/orders/presentation/screens/order_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements OrdersRepository {
  _FakeRepo(this.orders, {this.fail = false});
  final List<OrderSummary> orders;
  final bool fail;

  @override
  Future<List<OrderSummary>> listOwn() async {
    if (fail) throw Exception('boom: internal detail');
    return orders;
  }
}

OrderSummary _order(String n, String status, {String method = 'online'}) =>
    OrderSummary(
      id: 'id-$n',
      orderNumber: n,
      courseId: 'c-$n',
      courseTitle: 'Course $n',
      amountMinor: 1250000,
      currencyCode: 'LKR',
      paymentMethod: method,
      status: status,
      createdAt: DateTime.utc(2026, 10, 18),
    );

Future<void> _pump(WidgetTester tester, OrdersRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [ordersRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: OrderHistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('status labels never expose raw backend codes', () {
    expect(_order('1', 'pending_payment').statusLabel, 'Awaiting Payment');
    expect(
      _order('1', 'pending_verification').statusLabel,
      'Awaiting Verification',
    );
    expect(_order('1', 'paid').statusLabel, 'Paid');
    expect(_order('1', 'paid').formattedAmount, 'LKR 12,500.00');
  });

  testWidgets('lists orders with the right action per status', (tester) async {
    await _pump(
      tester,
      _FakeRepo([
        _order('A1', 'paid'),
        _order('B2', 'pending_verification', method: 'bank_transfer'),
        _order('C3', 'cancelled'),
      ]),
    );
    expect(find.text('Order #A1'), findsOneWidget);
    expect(find.text('Go to Course'), findsOneWidget);
    expect(find.text('View Payment Status'), findsNWidgets(2));
    expect(find.text('pending_verification'), findsNothing);
  });

  testWidgets('Paid filter hides unpaid orders; empty state shows', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo([_order('B2', 'pending_payment')]));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Paid'));
    await tester.pumpAndSettle();
    expect(find.text('Order #B2'), findsNothing);
    expect(find.text('No orders here.'), findsOneWidget);
  });

  testWidgets('error state hides internal detail and offers retry', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(const [], fail: true));
    expect(find.textContaining('internal detail'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
