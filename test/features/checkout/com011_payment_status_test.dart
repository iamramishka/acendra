import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/order_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class StatusRepository implements StudentOrderRepository {
  String status = 'pending_payment';
  int calls = 0;
  @override
  Future<StudentOrder?> findOpen(String actor, String courseId) async => null;
  @override
  Future<StudentOrder> read(String actor, String orderId) async {
    calls++;
    return StudentOrder(
      id: orderId,
      courseId: 'course-1',
      title: 'Backend Course',
      number: 'ORD-REAL',
      amountMinor: 12345,
      currency: 'LKR',
      method: 'online',
      status: status,
    );
  }
}

void main() {
  testWidgets(
    'COM-011 shows backend transaction details and history with refresh',
    (tester) async {
      final repo = StatusRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutActorProvider.overrideWithValue('student'),
            studentOrderRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OrderStatusScreen(orderId: 'order-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('Backend Course'), findsOneWidget);
      expect(find.text('Order #ORD-REAL'), findsOneWidget);
      expect(find.text('LKR 123.45'), findsOneWidget);
      expect(find.text('View Order History'), findsOneWidget);
      expect(find.textContaining('receipt'), findsNothing);
      repo.status = 'paid';
      await tester.ensureVisible(find.text('Refresh Payment Status'));
      await tester.tap(find.text('Refresh Payment Status'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.text('Payment verified'), findsOneWidget);
      expect(find.text('Check My Courses'), findsOneWidget);
    },
  );
}
