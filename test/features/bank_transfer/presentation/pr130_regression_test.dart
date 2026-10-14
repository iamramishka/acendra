import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/bank_transfer_screen.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/bank_transfer_screen.dart'
    as original;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const order = CheckoutOrder(
  orderId: 'order-1',
  orderNumber: 'ORD-REAL',
  courseId: 'course',
  courseTitle: 'Course',
  amountMinor: 423456,
  currencyCode: 'LKR',
  paymentMethod: PaymentMethod.bankTransfer,
  status: 'pending_payment',
  nextAction: 'show_bank_instructions',
  bankInstructions: BankInstructions(
    bankName: 'Trusted Bank',
    accountHolder: 'Holder',
    accountNumber: '456789',
    branch: 'Branch',
    currency: 'LKR',
  ),
);

class LoadedCheckout extends CheckoutNotifier {
  LoadedCheckout(this.order);
  final CheckoutOrder? order;
  @override
  Future<CheckoutOrder?> build() async => order;
}

void main() {
  Widget screen(CheckoutOrder? value, {String id = 'order-1'}) => ProviderScope(
    overrides: [checkoutProvider.overrideWith(() => LoadedCheckout(value))],
    child: MaterialApp(
      theme: ThemeData(
        extensions: [AppThemeExtension.fromTokens(AppColors.light)],
      ),
      home: BankTransferScreen(orderId: id),
    ),
  );
  testWidgets('direct URL without a trusted response fails closed', (
    tester,
  ) async {
    await tester.pumpWidget(screen(null));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Payment instructions are unavailable'),
      findsOneWidget,
    );
    expect(find.text("I've made the transfer"), findsNothing);
  });
  testWidgets('matching order renders exact trusted amount and destination', (
    tester,
  ) async {
    await tester.pumpWidget(screen(order));
    await tester.pumpAndSettle();
    expect(find.text('Trusted Bank'), findsOneWidget);
    expect(find.textContaining('LKR 4,234.56'), findsWidgets);
    expect(find.textContaining('ORD-REAL'), findsWidgets);
  });
  testWidgets('another order cannot reuse cached financial instructions', (
    tester,
  ) async {
    await tester.pumpWidget(screen(order, id: 'order-2'));
    await tester.pumpAndSettle();
    expect(find.text('Trusted Bank'), findsNothing);
    expect(
      find.textContaining('Payment instructions are unavailable'),
      findsOneWidget,
    );
  });
  testWidgets('original PR entry point shows no fabricated instructions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [checkoutProvider.overrideWith(() => LoadedCheckout(null))],
        child: const MaterialApp(
          home: original.BankTransferScreen(
            courseId: 'course',
            orderId: 'order-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Payment instructions are unavailable'),
      findsOneWidget,
    );
    expect(find.text('0123456789'), findsNothing);
    expect(find.text("I've Completed the Transfer"), findsNothing);
    expect(find.textContaining('Transfer noted'), findsNothing);
  });
  testWidgets('checkout reaches bank instructions and receipt flow', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const CheckoutScreen(courseId: 'course'),
        ),
        GoRoute(
          path: '/bank-transfer/:orderId',
          builder: (_, state) =>
              BankTransferScreen(orderId: state.pathParameters['orderId']!),
          routes: [
            GoRoute(
              path: 'status',
              builder: (_, state) =>
                  Text('Receipt flow ${state.pathParameters['orderId']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [checkoutProvider.overrideWith(() => LoadedCheckout(order))],
        child: MaterialApp.router(
          theme: ThemeData(
            extensions: [AppThemeExtension.fromTokens(AppColors.light)],
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue Bank Transfer'));
    await tester.tap(find.text('Continue Bank Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Trusted Bank'), findsOneWidget);
    await tester.ensureVisible(find.text("I've made the transfer"));
    await tester.tap(find.text("I've made the transfer"));
    await tester.pumpAndSettle();
    expect(find.text('Receipt flow order-1'), findsOneWidget);
    expect(find.textContaining('Transfer noted'), findsNothing);
  });
}
