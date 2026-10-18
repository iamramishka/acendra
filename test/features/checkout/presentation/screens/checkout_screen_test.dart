import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/fakes/fake_course_repository.dart';
import 'package:acendra/features/checkout/data/repositories/supabase_checkout_repository.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeCheckoutRepository implements CheckoutRepository {
  const _FakeCheckoutRepository();

  @override
  Future<CheckoutOrder> createOrder({
    required String courseId,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    return CheckoutOrder(
      orderId: 'order-001',
      orderNumber: 'ORD-001',
      courseId: courseId,
      courseTitle: 'Test Course',
      amountMinor: 150000,
      currencyCode: 'LKR',
      paymentMethod: method,
      status: 'pending_payment',
      nextAction: method == PaymentMethod.online
          ? 'initialize_online_payment'
          : 'show_bank_instructions',
      bankInstructions: method == PaymentMethod.bankTransfer
          ? const BankInstructions(
              bankName: 'Test Bank',
              accountHolder: 'Acedra Ltd',
              accountNumber: '1234567890',
              branch: 'Colombo',
              currency: 'LKR',
            )
          : null,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child, CheckoutRepository repo) {
  return ProviderScope(
    overrides: [checkoutRepositoryProvider.overrideWithValue(repo), courseDetailProvider('course-123').overrideWith((ref) async => fakeDetail)],
    child: MaterialApp(home: child),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const testCourseId = 'course-123';

  testWidgets('screen renders without crashing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CheckoutScreen(courseId: testCourseId),
        const _FakeCheckoutRepository(),
      ),
    );

    expect(find.byType(CheckoutScreen), findsOneWidget);
  });

  testWidgets('"Continue to PayHere" button is present initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckoutScreen(courseId: testCourseId),
        const _FakeCheckoutRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Continue to PayHere'), findsOneWidget);
  });

  testWidgets('checkout screen shows Checkout app bar title', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CheckoutScreen(courseId: testCourseId),
        const _FakeCheckoutRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Secure Checkout'), findsOneWidget);
  });

  testWidgets('selecting bank transfer shows Bank Transfer label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckoutScreen(courseId: testCourseId),
        const _FakeCheckoutRepository(),
      ),
    );

    await tester.pumpAndSettle();

    // The PaymentMethodSelector shows both options; find Bank Transfer label
    expect(find.text('Bank Transfer'), findsOneWidget);
  });

  testWidgets('billing details section is shown before order is created', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckoutScreen(courseId: testCourseId),
        const _FakeCheckoutRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Billing Details'), findsOneWidget);
  });

  testWidgets('shows validation errors when form is empty and submitted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckoutScreen(courseId: testCourseId),
        const _FakeCheckoutRepository(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue to PayHere'));
    await tester.tap(find.text('Continue to PayHere'));
    await tester.pumpAndSettle();

    // At least one Required error should appear
    expect(find.text('Required'), findsWidgets);
  });
}
