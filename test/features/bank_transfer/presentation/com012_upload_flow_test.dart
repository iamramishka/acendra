import 'dart:typed_data';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/bank_transfer_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_instructions_provider.dart';
import 'package:acendra/features/checkout/data/repositories/checkout_submission_repository.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/presentation/services/receipt_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const order = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> snapshot({String id = order}) => {
  'order_id': id,
  'order_number': 'ACD-123',
  'course': {'id': 'course', 'title': 'Synthetic Course'},
  'amount_minor': 12345,
  'currency_code': 'LKR',
  'payment_method': 'bank_transfer',
  'status': 'pending_payment',
  'next_action': 'show_bank_instructions',
  'bank_instructions': {
    'bank_name': 'Synthetic Bank',
    'account_holder': 'Synthetic Holder',
    'account_number': '123456',
    'branch_name': 'Test Branch',
    'currency_code': 'LKR',
  },
};

class EmptyCheckout extends CheckoutNotifier {
  @override
  Future<CheckoutOrder?> build() async => null;
}

Finder get submit =>
    find.widgetWithText(AppButton, 'Submit Receipt for Review');
Finder get picker => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics && widget.properties.label == 'Select receipt file',
);
void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'reload, selection, removal and confirmed upload at $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var reads = 0, uploads = 0;
          final repo = CheckoutSubmissionRepository((
            name,
            headers,
            body,
          ) async {
            if (name == 'bank-transfer-read') {
              reads++;
              expect(body, {'order_id': order, 'instructions': true});
              return FunctionResponse(status: 200, data: {'data': snapshot()});
            }
            expect(name, 'upload-bank-receipt');
            expect(headers['X-Order-Id'], order);
            expect(headers['Content-Type'], 'image/png');
            uploads++;
            return const FunctionResponse(
              status: 201,
              data: {
                'data': {
                  'order_id': order,
                  'submission_id': '22222222-2222-4222-8222-222222222222',
                  'status': 'submitted',
                },
              },
            );
          });
          final router = GoRouter(
            initialLocation: '/bank-transfer/$order',
            routes: [
              GoRoute(
                path: '/bank-transfer/:orderId',
                builder: (_, state) => BankTransferScreen(
                  orderId: state.pathParameters['orderId']!,
                  filePicker: () async =>
                      ReceiptFile(name: 'receipt.PNG', bytes: Uint8List(1)),
                ),
              ),
              GoRoute(
                path: '/bank-transfer/:orderId/status',
                builder: (_, _) =>
                    const Scaffold(body: Text('Awaiting Verification')),
              ),
            ],
          );
          addTearDown(router.dispose);
          final container = ProviderContainer(
            overrides: [
              checkoutActorProvider.overrideWithValue('student'),
              checkoutProvider.overrideWith(EmptyCheckout.new),
              checkoutSubmissionRepositoryProvider.overrideWithValue(repo),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: dark ? AppTheme.dark : AppTheme.light,
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Synthetic Bank'), findsOneWidget);
          expect(find.text('Upload Payment Receipt'), findsOneWidget);
          expect(tester.widget<AppButton>(submit).onPressed, isNull);
          expect(
            submit.hitTestable(),
            findsOneWidget,
          ); // Sticky even before scroll.
          expect(reads, 1);
          container.invalidate(bankInstructionsProvider(order));
          await container.read(bankInstructionsProvider(order).future);
          await tester.pumpAndSettle();
          expect(reads, 2);
          expect(find.text('Synthetic Bank'), findsOneWidget);
          await tester.ensureVisible(picker);
          await tester.tap(picker);
          await tester.pumpAndSettle();
          expect(tester.widget<AppButton>(submit).onPressed, isNotNull);
          expect(uploads, 0);
          await tester.ensureVisible(find.text('Remove'));
          await tester.tap(find.text('Remove'));
          await tester.pumpAndSettle();
          expect(tester.widget<AppButton>(submit).onPressed, isNull);
          await tester.ensureVisible(picker);
          await tester.tap(picker);
          await tester.pumpAndSettle();
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(uploads, 1);
          expect(find.text('Awaiting Verification'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final wrong in [true, false]) {
    testWidgets(
      'recovery fails closed on ${wrong ? 'other order' : 'server failure'}',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutActorProvider.overrideWithValue('student'),
              checkoutProvider.overrideWith(EmptyCheckout.new),
              checkoutSubmissionRepositoryProvider.overrideWithValue(
                CheckoutSubmissionRepository(
                  (_, _, _) async => FunctionResponse(
                    status: wrong ? 200 : 503,
                    data: {'data': snapshot(id: wrong ? 'other-order' : order)},
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const BankTransferScreen(orderId: order),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Payment instructions are unavailable'),
          findsOneWidget,
        );
        expect(find.text('Synthetic Bank'), findsNothing);
        expect(submit, findsNothing);
      },
    );
  }
}
