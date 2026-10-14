import 'package:acendra/features/admin/presentation/screens/finance_review_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unavailable queue does not fabricate receipt decisions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeQueueProvider.overrideWith(
            (ref) async => throw Exception('503'),
          ),
        ],
        child: const MaterialApp(home: FinanceReviewScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Finance review is unavailable'),
      findsOneWidget,
    );
    expect(find.text('Record approval'), findsNothing);
    expect(find.textContaining('Synthetic preview'), findsNothing);
  });
}
