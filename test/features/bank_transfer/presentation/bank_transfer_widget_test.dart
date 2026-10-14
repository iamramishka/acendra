import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/bank_transfer_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/finance_review_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_resubmission_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_status_screen.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

AppThemeExtension _ext() => const AppThemeExtension(
  success: Colors.green,
  successContainer: Color(0xFFE8F5E9),
  warning: Colors.orange,
  warningContainer: Color(0xFFFFF3E0),
  focusRing: Colors.blue,
  surfaceSecondary: Color(0xFFF5F5F5),
  surfaceTertiary: Color(0xFFEEEEEE),
  textSecondary: Color(0xFF757575),
  border: Color(0xFFE0E0E0),
);

ThemeData _theme() => ThemeData.light().copyWith(extensions: [_ext()]);

class _LoadedCheckout extends CheckoutNotifier {
  _LoadedCheckout(this.order);
  final CheckoutOrder order;
  @override
  Future<CheckoutOrder?> build() async => order;
}

Widget _scaffold(Widget child, {bool bankAvailable = true}) => ProviderScope(
  overrides: [
    if (child is BankTransferScreen)
      checkoutProvider.overrideWith(
        () => _LoadedCheckout(
          CheckoutOrder(
            orderId: child.orderId,
            orderNumber: 'ORD-001',
            courseId: 'course',
            courseTitle: 'Flutter Mastery',
            amountMinor: 500000,
            currencyCode: 'LKR',
            paymentMethod: PaymentMethod.bankTransfer,
            status: 'pending_payment',
            nextAction: 'show_bank_instructions',
            bankInstructions: bankAvailable ? _fakeBankInstructions : null,
          ),
        ),
      ),
  ],
  child: MaterialApp(theme: _theme(), home: child),
);

const _fakeBankInstructions = BankInstructions(
  bankName: 'Test Bank',
  accountHolder: 'Acedra Pvt Ltd',
  accountNumber: '0001234567',
  branch: 'Colombo',
  currency: 'LKR',
);

// ── CSA-107: BankTransferScreen ───────────────────────────────────────────────

void main() {
  group('BankTransferScreen (CSA-107)', () {
    testWidgets('renders step-by-step instructions', (tester) async {
      await tester.pumpWidget(
        _scaffold(const BankTransferScreen(orderId: 'order-1')),
      );

      await tester.pumpAndSettle();
      expect(find.text("I've made the transfer"), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('ORD-001'), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.textContaining('Flutter Mastery'), findsOneWidget);
    });

    testWidgets('shows bank account details', (tester) async {
      await tester.pumpWidget(
        _scaffold(const BankTransferScreen(orderId: 'order-1')),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Bank'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('0001234567'), findsOneWidget);
    });

    testWidgets('shows disclaimer about independent verification', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BankTransferScreen(orderId: 'order-1')),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('independently verifies'), findsOneWidget);
    });

    testWidgets('renders without bank instructions', (tester) async {
      await tester.pumpWidget(
        _scaffold(
          const BankTransferScreen(orderId: 'order-1'),
          bankAvailable: false,
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.textContaining('Payment instructions are unavailable'),
        findsOneWidget,
      );
      expect(find.text("I've made the transfer"), findsNothing);
    });
  });

  // ── CSA-110: ReceiptStatusScreen ─────────────────────────────────────────────

  group('ReceiptStatusScreen (CSA-110)', () {
    testWidgets('shows upload CTA for awaiting_receipt status', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              receiptSubmissionProvider('order-1').overrideWith(
                (ref) async => const ReceiptSubmission(
                  orderId: 'order-1',
                  orderNumber: 'ORD-001',
                  courseTitle: 'Flutter Course',
                  status: ReceiptStatus.awaitingReceipt,
                ),
              ),
            ],
          ),
          child: MaterialApp(
            theme: _theme(),
            home: const ReceiptStatusScreen(orderId: 'order-1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Upload Receipt'), findsOneWidget);
      expect(find.textContaining('Upload Your Receipt'), findsOneWidget);
    });

    testWidgets('shows under-review message', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              receiptSubmissionProvider('order-2').overrideWith(
                (ref) async => const ReceiptSubmission(
                  orderId: 'order-2',
                  orderNumber: 'ORD-002',
                  courseTitle: 'Dart Course',
                  status: ReceiptStatus.underReview,
                ),
              ),
            ],
          ),
          child: MaterialApp(
            theme: _theme(),
            home: const ReceiptStatusScreen(orderId: 'order-2'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Under Review'), findsOneWidget);
    });

    testWidgets('shows rejection reason and resubmit CTA', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              receiptSubmissionProvider('order-3').overrideWith(
                (ref) async => const ReceiptSubmission(
                  orderId: 'order-3',
                  orderNumber: 'ORD-003',
                  courseTitle: 'Test Course',
                  status: ReceiptStatus.rejected,
                  rejectionReason: 'Amount does not match.',
                ),
              ),
            ],
          ),
          child: MaterialApp(
            theme: _theme(),
            home: const ReceiptStatusScreen(orderId: 'order-3'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Amount does not match.'), findsOneWidget);
      expect(find.text('Submit New Receipt'), findsOneWidget);
    });

    testWidgets('shows approved message without upload button', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              receiptSubmissionProvider('order-4').overrideWith(
                (ref) async => const ReceiptSubmission(
                  orderId: 'order-4',
                  orderNumber: 'ORD-004',
                  courseTitle: 'Test Course',
                  status: ReceiptStatus.approved,
                ),
              ),
            ],
          ),
          child: MaterialApp(
            theme: _theme(),
            home: const ReceiptStatusScreen(orderId: 'order-4'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Payment Verified'), findsOneWidget);
      expect(find.text('Upload Receipt'), findsNothing);
    });
  });

  // ── CSA-115: ReceiptResubmissionScreen ───────────────────────────────────────

  group('ReceiptResubmissionScreen (CSA-115)', () {
    testWidgets('renders file picker and disabled-backend notice', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const ReceiptResubmissionScreen(orderId: 'order-1')),
      );

      expect(find.text('Receipt Rejected'), findsOneWidget);
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
      expect(find.text('Submit New Receipt'), findsOneWidget);
    });

    testWidgets('shows rejection reason when provided', (tester) async {
      await tester.pumpWidget(
        _scaffold(
          const ReceiptResubmissionScreen(
            orderId: 'order-1',
            rejectionReason: 'Wrong account number.',
          ),
        ),
      );

      expect(find.text('Wrong account number.'), findsOneWidget);
    });

    testWidgets('submit button disabled until file selected', (tester) async {
      await tester.pumpWidget(
        _scaffold(const ReceiptResubmissionScreen(orderId: 'order-1')),
      );

      expect(find.text('Submit New Receipt'), findsOneWidget);

      // AppButton renders ElevatedButton; when onPressed=null the button is disabled.
      final btns = tester.widgetList<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final submitBtn = btns.firstWhere(
        (b) =>
            b.child is Text && (b.child as Text).data == 'Submit New Receipt',
        orElse: () => btns.last,
      );
      expect(submitBtn.onPressed, isNull);
    });
  });

  // ── CSA-111: FinanceReviewScreen ──────────────────────────────────────────────

  group('FinanceReviewScreen (CSA-111)', () {
    testWidgets(
      'queue unavailable never renders invented receipts or decisions',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              financeQueueProvider.overrideWith(
                (ref) async => throw Exception('Unavailable'),
              ),
            ],
            child: MaterialApp(
              theme: _theme(),
              home: const FinanceReviewScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Finance review is unavailable'),
          findsOneWidget,
        );
        expect(find.textContaining('Example Student'), findsNothing);
        expect(find.text('Record approval'), findsNothing);
      },
    );
    testWidgets('empty authorized queue renders empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [financeQueueProvider.overrideWith((ref) async => [])],
          child: MaterialApp(
            theme: _theme(),
            home: const FinanceReviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No receipts to review'), findsOneWidget);
    });
  });
}
