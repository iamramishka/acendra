import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/domain/entities/receipt_review_item.dart';
import 'package:acendra/features/admin/presentation/widgets/receipt_review_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ReceiptReviewItem _item({
  ReceiptStatus status = ReceiptStatus.pending,
  String? rejectionReason,
}) {
  return ReceiptReviewItem(
    id: 'rec-test-1',
    orderId: 'ord-test-1',
    studentId: 'stu-test-1',
    studentEmail: 'test@example.com',
    courseTitle: 'Test Course',
    amount: 99.99,
    currency: 'USD',
    submittedAt: DateTime(2026, 1, 15, 10, 30),
    status: status,
    receiptStoragePath: 'receipts/test/receipt.pdf',
    rejectionReason: rejectionReason,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReceiptReviewTile', () {
    testWidgets('pending item shows both Approve and Reject buttons',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () {},
            onReject: () {},
          ),
        ),
      );

      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('approved item shows success badge and no action buttons',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.approved),
            onApprove: () {},
            onReject: () {},
          ),
        ),
      );

      // Success badge present
      expect(
        find.byWidgetPredicate(
          (w) => w is StatusBadge && w.variant == BadgeVariant.success,
        ),
        findsOneWidget,
      );

      // No approve / reject action buttons
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets(
        'rejected item shows error badge, rejection reason, and no action buttons',
        (tester) async {
      const reason = 'Receipt image is illegible.';
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(
              status: ReceiptStatus.rejected,
              rejectionReason: reason,
            ),
            onApprove: () {},
            onReject: () {},
          ),
        ),
      );

      // Error badge present
      expect(
        find.byWidgetPredicate(
          (w) => w is StatusBadge && w.variant == BadgeVariant.error,
        ),
        findsOneWidget,
      );

      // Rejection reason shown
      expect(find.text(reason), findsOneWidget);

      // No action buttons
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('Reject button opens dialog requiring a reason', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () {},
            onReject: () {},
          ),
        ),
      );

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Reject Receipt'), findsOneWidget);
      expect(find.text('Confirm Rejection'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Reject dialog requires minimum 10 characters', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () {},
            onReject: () {},
          ),
        ),
      );

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      // Enter too-short reason and try to confirm
      await tester.enterText(find.byType(TextField), 'too short');
      await tester.tap(find.text('Confirm Rejection'));
      await tester.pumpAndSettle();

      // Dialog remains open with validation error
      expect(find.text('Reject Receipt'), findsOneWidget);
      expect(find.text('Please enter at least 10 characters.'), findsOneWidget);
    });

    testWidgets('onApprove fires when Approve is tapped', (tester) async {
      var approved = false;
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () => approved = true,
            onReject: () {},
          ),
        ),
      );

      await tester.tap(find.text('Approve'));
      await tester.pump();

      expect(approved, isTrue);
    });

    testWidgets('onReject fires after entering valid rejection reason',
        (tester) async {
      var rejected = false;
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () {},
            onReject: () => rejected = true,
          ),
        ),
      );

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      // Enter a valid reason
      await tester.enterText(
        find.byType(TextField),
        'The bank receipt amount does not match.',
      );
      await tester.tap(find.text('Confirm Rejection'));
      await tester.pumpAndSettle();

      expect(rejected, isTrue);
    });

    testWidgets('isProcessing: true disables the action buttons', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () {},
            onReject: () {},
            // ignore: avoid_redundant_argument_values
            isProcessing: true,
          ),
        ),
      );

      // Both action buttons should have isLoading: true (label prop identifies them)
      final allButtons = tester.widgetList<AppButton>(find.byType(AppButton));
      final approveButton = allButtons.firstWhere((b) => b.label == 'Approve');
      final rejectButton = allButtons.firstWhere((b) => b.label == 'Reject');

      expect(approveButton.isLoading, isTrue);
      expect(rejectButton.isLoading, isTrue);
    });

    testWidgets('View Receipt button is always present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.approved),
          ),
        ),
      );

      expect(find.text('View Receipt'), findsOneWidget);
    });

    testWidgets('cancel button in reject dialog dismisses without calling onReject',
        (tester) async {
      var rejected = false;
      await tester.pumpWidget(
        _wrap(
          ReceiptReviewTile(
            item: _item(status: ReceiptStatus.pending),
            onApprove: () {},
            onReject: () => rejected = true,
          ),
        ),
      );

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      // Cancel without entering a reason
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(rejected, isFalse);
      // Dialog dismissed
      expect(find.text('Reject Receipt'), findsNothing);
    });
  });
}
