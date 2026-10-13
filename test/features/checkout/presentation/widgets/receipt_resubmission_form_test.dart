import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/checkout/presentation/widgets/receipt_resubmission_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in a [MaterialApp] that uses the Acendra light theme, which
/// registers [AppThemeExtension] so theme-dependent widgets render correctly.
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

/// Finds the submit [AppButton] by its label text.
Finder get _submitButtonFinder =>
    find.widgetWithText(AppButton, 'Submit New Receipt');

/// Calls [simulateFilePick] on the [ReceiptResubmissionForm] state.
void _simulateFilePick(
  WidgetTester tester, {
  required String filename,
  required int sizeBytes,
}) {
  // The state is accessed via dynamic to avoid referencing the private class
  // name from outside the library.
  // ignore: avoid_dynamic_calls
  (tester.state(find.byType(ReceiptResubmissionForm)) as dynamic)
      .simulateFilePick(filename: filename, sizeBytes: sizeBytes);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReceiptResubmissionForm', () {
    // ── 1. Submit button disabled when no file selected ─────────────────────
    testWidgets('submit button is disabled when no file is selected',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ReceiptResubmissionForm(orderId: 'order-001')),
      );
      await tester.pump();

      final button = tester.widget<AppButton>(_submitButtonFinder);
      // onPressed is null when no file is selected → button is disabled.
      expect(button.onPressed, isNull);
    });

    // ── 2. Submit button enabled after valid file selected ───────────────────
    testWidgets('submit button becomes enabled after a valid file is selected',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ReceiptResubmissionForm(orderId: 'order-002')),
      );
      await tester.pump();

      // Simulate picking a valid 1 MB JPG.
      _simulateFilePick(
        tester,
        filename: 'receipt.jpg',
        sizeBytes: 1024 * 1024,
      );
      await tester.pump();

      final button = tester.widget<AppButton>(_submitButtonFinder);
      expect(button.onPressed, isNotNull);
    });

    // ── 3. File too large shows inline validation error ──────────────────────
    testWidgets('selecting a file larger than 5 MB shows an inline error',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ReceiptResubmissionForm(orderId: 'order-003')),
      );
      await tester.pump();

      // 6 MB > 5 MB limit.
      _simulateFilePick(
        tester,
        filename: 'large_receipt.pdf',
        sizeBytes: 6 * 1024 * 1024,
      );
      await tester.pump();

      expect(find.textContaining('File is too large'), findsOneWidget);

      // Submit button must remain disabled.
      final button = tester.widget<AppButton>(_submitButtonFinder);
      expect(button.onPressed, isNull);
    });

    // ── 4. onSubmitted fires after successful mock submit ────────────────────
    testWidgets('onSubmitted callback fires after successful submission',
        (tester) async {
      var callbackFired = false;

      await tester.pumpWidget(
        _wrap(
          ReceiptResubmissionForm(
            orderId: 'order-004',
            onSubmitted: () => callbackFired = true,
          ),
        ),
      );
      await tester.pump();

      // Simulate picking a valid file.
      _simulateFilePick(
        tester,
        filename: 'receipt.pdf',
        sizeBytes: 512 * 1024,
      );
      await tester.pump();

      // Tap the submit button.
      await tester.tap(_submitButtonFinder);
      // Pump past the fake 1-second upload delay.
      await tester.pump(const Duration(seconds: 2));

      expect(callbackFired, isTrue);
    });

    // ── 5. Rejection reason is shown when provided ───────────────────────────
    testWidgets('rejection reason text is shown when provided', (tester) async {
      const reason =
          'The bank reference number is not visible in your receipt.';

      await tester.pumpWidget(
        _wrap(
          const ReceiptResubmissionForm(
            orderId: 'order-005',
            rejectionReason: reason,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(reason), findsOneWidget);
      expect(find.text('Reason for rejection'), findsOneWidget);
    });

    // ── 6. No rejection reason rendered when null ────────────────────────────
    testWidgets(
        'rejection reason box is absent when rejectionReason is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ReceiptResubmissionForm(orderId: 'order-006')),
      );
      await tester.pump();

      expect(find.text('Reason for rejection'), findsNothing);
    });

    // ── 7. No overflow at 390 px width ───────────────────────────────────────
    testWidgets('no overflow at 390 px viewport width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const ReceiptResubmissionForm(orderId: 'order-007')),
      );
      await tester.pump();

      // pumpWidget completing without a layout overflow exception is the pass.
      expect(find.byType(ReceiptResubmissionForm), findsOneWidget);
    });

    // ── 8. Unsupported file type shows validation error ──────────────────────
    testWidgets('unsupported file type shows validation error', (tester) async {
      await tester.pumpWidget(
        _wrap(const ReceiptResubmissionForm(orderId: 'order-008')),
      );
      await tester.pump();

      _simulateFilePick(
        tester,
        filename: 'receipt.png',
        sizeBytes: 200 * 1024,
      );
      await tester.pump();

      expect(find.textContaining('Only JPG and PDF'), findsOneWidget);

      final button = tester.widget<AppButton>(_submitButtonFinder);
      expect(button.onPressed, isNull);
    });
  });
}
