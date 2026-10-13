import 'dart:async';

import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/finance_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControlledReview extends BankReviewNotifier {
  final completion = Completer<void>();
  int calls = 0;
  String? reason;

  @override
  Future<void> reject({
    required String submissionId,
    required String rejectionReason,
  }) async {
    calls++;
    reason = rejectionReason;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => completion.future);
  }
}

Future<void> _openForm(WidgetTester tester, _ControlledReview notifier) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bankReviewProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [
            const AppThemeExtension(
              success: Colors.green,
              successContainer: Colors.green,
              warning: Colors.orange,
              warningContainer: Colors.orange,
              focusRing: Colors.blue,
              surfaceSecondary: Colors.white,
              surfaceTertiary: Colors.white,
              textSecondary: Colors.grey,
              border: Colors.grey,
            ),
          ],
        ),
        home: const FinanceReviewScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Reject'));
  await tester.tap(find.text('Reject'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '  Amount does not match.  ');
  await tester.ensureVisible(find.text('Confirm Reject'));
  await tester.tap(find.text('Confirm Reject'));
  await tester.pump();
}

void main() {
  testWidgets('failed rejection retains reason and allows retry', (
    tester,
  ) async {
    final notifier = _ControlledReview();
    await _openForm(tester, notifier);
    notifier.completion.completeError(Exception('Review unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Reject'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '  Amount does not match.  ',
    );
    expect(notifier.reason, 'Amount does not match.');
    expect(find.textContaining('Review unavailable'), findsOneWidget);
  });

  testWidgets('pending rejection disables editing and duplicate submission', (
    tester,
  ) async {
    final notifier = _ControlledReview();
    await _openForm(tester, notifier);
    final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
    expect(
      buttons.firstWhere((b) => b.label == 'Confirm Reject').onPressed,
      isNull,
    );
    expect(buttons.firstWhere((b) => b.label == 'Cancel').onPressed, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(notifier.calls, 1);
    notifier.completion.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('successful rejection clears reason after completion', (
    tester,
  ) async {
    final notifier = _ControlledReview();
    await _openForm(tester, notifier);
    notifier.completion.complete();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reject'));
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
