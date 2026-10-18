import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/bank_transfer_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_status_screen.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoadedCheckout extends CheckoutNotifier {
  _LoadedCheckout(this.order);
  final CheckoutOrder order;
  @override
  Future<CheckoutOrder?> build() async => order;
}

ReceiptSubmission _submission(ReceiptStatus status) => ReceiptSubmission(
  orderId: 'order-1',
  orderNumber: 'ORD-001',
  courseTitle: 'Flutter Mastery',
  status: status,
  submissionId: status == ReceiptStatus.awaitingReceipt ? null : 'sub-1',
  rejectionReason: status == ReceiptStatus.rejected ? 'Blurry image' : null,
  submittedAt: status == ReceiptStatus.awaitingReceipt
      ? null
      : DateTime.utc(2026, 10, 12, 8),
);

Widget _statusApp(AsyncValue<ReceiptSubmission> value) => ProviderScope(
  overrides: [receiptSubmissionProvider('order-1').overrideWithValue(value)],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const ReceiptStatusScreen(orderId: 'order-1'),
  ),
);

Widget _bankApp() => ProviderScope(
  overrides: [
    bankSessionIdentityProvider.overrideWithValue('test-session'),
    checkoutProvider.overrideWith(
      () => _LoadedCheckout(
        const CheckoutOrder(
          orderId: 'order-1',
          orderNumber: 'ORD-001',
          courseId: 'course',
          courseTitle: 'Flutter Mastery',
          amountMinor: 500000,
          currencyCode: 'LKR',
          paymentMethod: PaymentMethod.bankTransfer,
          status: 'pending_payment',
          nextAction: 'show_bank_instructions',
          bankInstructions: BankInstructions(
            bankName: 'Test Bank',
            accountHolder: 'Acedra Pvt Ltd',
            accountNumber: '0001234567',
            branch: 'Colombo',
            currency: 'LKR',
          ),
        ),
      ),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const BankTransferScreen(orderId: 'order-1'),
  ),
);

void main() {
  group('COM-013 status screen', () {
    for (final status in ReceiptStatus.values) {
      testWidgets('$status shows details card and four-step timeline', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_statusApp(AsyncData(_submission(status))));
        await tester.pumpAndSettle();

        expect(find.text('Order Details'), findsOneWidget);
        expect(find.text('Flutter Mastery'), findsWidgets);
        expect(find.text('ORD-001'), findsOneWidget);
        expect(find.text('Bank Transfer'), findsOneWidget);
        expect(find.text('Payment Progress'), findsOneWidget);
        for (final t in [
          'Order Created',
          'Receipt Submitted',
          'Bank Verification',
          'Enrollment Activated',
        ]) {
          expect(find.text(t), findsOneWidget);
        }
        expect(find.text('Explore Courses'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('rejected keeps the reason and resubmit action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _statusApp(AsyncData(_submission(ReceiptStatus.rejected))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Blurry image'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
    });

    testWidgets('unexpected errors never show internal details', (
      tester,
    ) async {
      await tester.pumpWidget(
        _statusApp(
          AsyncError(
            StateError('secret table orders_private'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('orders_private'), findsNothing);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('our own failure messages are still shown', (tester) async {
      await tester.pumpWidget(
        _statusApp(
          const AsyncError(
            BankTransferFailure('Sign in to view transfer status.'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in to view transfer status.'), findsOneWidget);
    });
  });

  group('COM-012 instructions screen', () {
    testWidgets('bank, holder, account number and order ref can be copied', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bankApp());
      await tester.pumpAndSettle();

      for (final tip in [
        'Copy order reference',
        'Copy bank',
        'Copy account holder',
        'Copy account number',
      ]) {
        await tester.tap(find.byTooltip(tip));
        await tester.pump();
      }
      expect(copied, ['ORD-001', 'Test Bank', 'Acedra Pvt Ltd', '0001234567']);
    });

    testWidgets('tells the student to use the order reference', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_bankApp());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('put your order reference (ORD-001)'),
        findsOneWidget,
      );
    });
  });
}
