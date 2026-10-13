import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_status_screen.dart';
import 'package:acendra/features/checkout/presentation/widgets/receipt_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final status in [
    ReceiptStatus.submitted,
    ReceiptStatus.underReview,
    ReceiptStatus.approved,
    ReceiptStatus.rejected,
  ]) {
    testWidgets(
      'routed status screen uses provider data and actions: $status',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/status',
          routes: [
            GoRoute(
              path: '/status',
              builder: (_, _) =>
                  const ReceiptStatusScreen(orderId: 'order-test'),
            ),
            GoRoute(
              path: RouteNames.myCourses,
              builder: (_, _) =>
                  const Scaffold(body: Text('My courses destination')),
            ),
            GoRoute(
              path: '/bank-transfer/:orderId/resubmit',
              builder: (_, state) => Scaffold(
                body: Text('Resubmit ${state.pathParameters['orderId']}'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              receiptSubmissionProvider('order-test').overrideWith(
                (ref) async => ReceiptSubmission(
                  orderId: 'order-test',
                  orderNumber: 'ORD-TEST',
                  courseTitle: 'Test Course',
                  status: status,
                  submittedAt: DateTime(2026, 10, 13, 9, 15),
                  rejectionReason: status == ReceiptStatus.rejected
                      ? 'Verified rejection reason'
                      : null,
                ),
              ),
            ],
            child: MaterialApp.router(
              theme: ThemeData(
                extensions: [
                  const AppThemeExtension(
                    success: Colors.green,
                    successContainer: Colors.white,
                    warning: Colors.orange,
                    warningContainer: Colors.white,
                    focusRing: Colors.blue,
                    surfaceSecondary: Colors.white,
                    surfaceTertiary: Colors.white,
                    textSecondary: Colors.grey,
                    border: Colors.grey,
                  ),
                ],
              ),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ReceiptStatusCard), findsOneWidget);
        expect(find.text('Submitted 13 Oct 2026 at 09:15'), findsOneWidget);
        expect(find.textContaining('12 Oct 2026'), findsNothing);
        if (status == ReceiptStatus.approved) {
          await tester.tap(find.text('Go to Course'));
          await tester.pumpAndSettle();
          expect(find.text('My courses destination'), findsOneWidget);
        } else if (status == ReceiptStatus.rejected) {
          expect(find.text('Verified rejection reason'), findsOneWidget);
          await tester.tap(find.text('Submit New Receipt'));
          await tester.pumpAndSettle();
          expect(find.text('Resubmit order-test'), findsOneWidget);
        } else {
          expect(find.text('Go to Course'), findsNothing);
          expect(find.text('Submit New Receipt'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
