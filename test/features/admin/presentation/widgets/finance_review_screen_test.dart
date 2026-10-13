import 'package:acendra/features/admin/presentation/screens/finance_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FinanceReviewScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unavailable approval never marks a receipt approved', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    expect(find.text('Approved (1)'), findsOneWidget);
    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('Receipt approved successfully.'), findsNothing);
    expect(
      find.textContaining('Bank review is temporarily unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('Synthetic preview'), findsOneWidget);
  });

  testWidgets('unavailable rejection never marks a receipt rejected', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Amount does not match.');
    await tester.tap(find.text('Confirm Rejection'));
    await tester.pumpAndSettle();
    expect(find.text('Rejected (1)'), findsOneWidget);
    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('Receipt rejected.'), findsNothing);
    expect(
      find.textContaining('Bank review is temporarily unavailable'),
      findsOneWidget,
    );
  });
}
