import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/checkout/domain/entities/receipt_submission.dart';
import 'package:acendra/features/checkout/presentation/widgets/receipt_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

/// 390 px-wide viewport (mobile).
Widget _wrapNarrow(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

ReceiptSubmission _pending() => ReceiptSubmission(
  id: 'r1',
  orderId: 'o1',
  status: ReceiptReviewStatus.pending,
  submittedAt: DateTime(2026, 10, 12, 14, 30),
);

ReceiptSubmission _approved() => ReceiptSubmission(
  id: 'r2',
  orderId: 'o2',
  status: ReceiptReviewStatus.approved,
  submittedAt: DateTime(2026, 10, 12, 9, 0),
  reviewedAt: DateTime(2026, 10, 13, 10, 0),
);

ReceiptSubmission _rejected({String reason = 'Receipt is blurry.'}) =>
    ReceiptSubmission(
      id: 'r3',
      orderId: 'o3',
      status: ReceiptReviewStatus.rejected,
      submittedAt: DateTime(2026, 10, 11, 8, 0),
      rejectionReason: reason,
      reviewedAt: DateTime(2026, 10, 12, 11, 0),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReceiptStatusCard – pending state', () {
    testWidgets('renders warning badge with "Pending Review" label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _pending())),
      );

      expect(find.byType(StatusBadge), findsOneWidget);

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.variant, BadgeVariant.warning);
      expect(badge.label, 'Pending Review');
    });

    testWidgets('shows informational pending text', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _pending())),
      );

      expect(
        find.textContaining('1–2 business days'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT show a "Go to Course" button', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _pending())),
      );

      expect(find.widgetWithText(AppButton, 'Go to Course'), findsNothing);
    });

    testWidgets('does NOT show a "Resubmit Receipt" button', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _pending())),
      );

      expect(find.widgetWithText(AppButton, 'Resubmit Receipt'), findsNothing);
    });

    testWidgets('shows submitted timestamp', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _pending())),
      );

      expect(find.textContaining('Submitted'), findsOneWidget);
      expect(find.textContaining('12 Oct 2026'), findsOneWidget);
    });
  });

  group('ReceiptStatusCard – approved state', () {
    testWidgets('renders success badge with "Approved" label', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _approved())),
      );

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.variant, BadgeVariant.success);
      expect(badge.label, 'Approved');
    });

    testWidgets('shows "Go to Course" button that fires callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ReceiptStatusCard(
            submission: _approved(),
            onGoToCourse: () => tapped = true,
          ),
        ),
      );

      expect(find.widgetWithText(AppButton, 'Go to Course'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Go to Course'));
      expect(tapped, isTrue);
    });

    testWidgets('does NOT show "Resubmit Receipt" button', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _approved())),
      );

      expect(find.widgetWithText(AppButton, 'Resubmit Receipt'), findsNothing);
    });

    testWidgets('shows verification confirmation text', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _approved())),
      );

      expect(find.textContaining('verified'), findsOneWidget);
    });
  });

  group('ReceiptStatusCard – rejected state', () {
    testWidgets('renders error badge with "Rejected" label', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _rejected())),
      );

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.variant, BadgeVariant.error);
      expect(badge.label, 'Rejected');
    });

    testWidgets('shows the rejection reason text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReceiptStatusCard(submission: _rejected(reason: 'Receipt is blurry.')),
        ),
      );

      expect(find.text('Receipt is blurry.'), findsOneWidget);
    });

    testWidgets('shows "Resubmit Receipt" button that fires callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ReceiptStatusCard(
            submission: _rejected(),
            onResubmit: () => tapped = true,
          ),
        ),
      );

      expect(
        find.widgetWithText(AppButton, 'Resubmit Receipt'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Resubmit Receipt'));
      expect(tapped, isTrue);
    });

    testWidgets('does NOT show "Go to Course" button', (tester) async {
      await tester.pumpWidget(
        _wrap(ReceiptStatusCard(submission: _rejected())),
      );

      expect(find.widgetWithText(AppButton, 'Go to Course'), findsNothing);
    });
  });

  group('ReceiptStatusCard – responsive / overflow', () {
    testWidgets('renders without overflow at 390px width', (tester) async {
      // Simulate a 390×844 mobile viewport.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapNarrow(ReceiptStatusCard(submission: _pending())),
      );

      // If there is an overflow exception the test will fail automatically.
      expect(tester.takeException(), isNull);
      expect(find.byType(ReceiptStatusCard), findsOneWidget);
    });

    testWidgets('renders rejected state without overflow at 390px',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapNarrow(
          ReceiptStatusCard(
            submission: _rejected(reason: 'The uploaded image is not legible.'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ReceiptStatusCard), findsOneWidget);
    });
  });
}
