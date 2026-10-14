import 'dart:async';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/checkout/data/repositories/checkout_submission_repository.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/payment_launcher_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';

const orderId = '11111111-1111-4111-8111-111111111111';
const attempt = '22222222-2222-4222-8222-222222222222';

class ReadyCheckout extends CheckoutNotifier {
  @override
  Future<CheckoutOrder?> build() async => const CheckoutOrder(
    orderId: orderId,
    orderNumber: 'TEST-ORDER',
    courseId: 'sample-course',
    courseTitle: 'Sample Course',
    amountMinor: 12345,
    currencyCode: 'LKR',
    paymentMethod: PaymentMethod.online,
    status: 'pending_payment',
    nextAction: 'initialize_online_payment',
  );
}

void main() {
  for (final change in ['actor', 'order']) {
    testWidgets('pending initialization cannot launch after $change switch', (
      tester,
    ) async {
      final pending = Completer<FunctionResponse>();
      final actor = StateProvider<String?>((ref) => 'student-a');
      var launched = 0;
      final container = ProviderContainer(
        overrides: [
          checkoutActorProvider.overrideWith((ref) => ref.watch(actor)),
          checkoutProvider.overrideWith(ReadyCheckout.new),
          checkoutSubmissionRepositoryProvider.overrideWithValue(
            CheckoutSubmissionRepository(
              (name, headers, body) => pending.future,
            ),
          ),
          paymentLauncherProvider.overrideWithValue((payment) async {
            launched++;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CheckoutScreen(courseId: 'sample-course'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final values = [
        'Sample',
        'Student',
        '+94771234567',
        'Test Street',
        'Colombo',
        'Sri Lanka',
      ];
      for (var i = 0; i < values.length; i++) {
        final field = find.byType(TextField).at(i);
        await tester.ensureVisible(field);
        await tester.enterText(field, values[i]);
      }
      await tester.ensureVisible(find.text('Pay Now'));
      await tester.tap(find.text('Pay Now'));
      await tester.pump();
      if (change == 'actor') {
        container.read(actor.notifier).state = 'student-b';
      } else {
        container.read(checkoutProvider.notifier).reset();
      }
      await tester.pump();
      pending.complete(
        const FunctionResponse(
          status: 201,
          data: {
            'data': {
              'order_id': orderId,
              'attempt_id': attempt,
              'status': 'pending_payment',
              'checkout': {
                'action': 'https://sandbox.payhere.lk/pay/checkout',
                'fields': {
                  'first_name': 'Sample',
                  'last_name': 'Student',
                  'email': 'sample@example.test',
                  'phone': '+94771234567',
                  'address': 'Test Street',
                  'city': 'Colombo',
                  'country': 'Sri Lanka',
                  'return_url': 'https://app.example.test/return',
                  'cancel_url': 'https://app.example.test/cancel',
                  'notify_url': 'https://app.example.test/notify',
                  'merchant_id': '123456',
                  'order_id': attempt,
                  'items': 'Sample Course',
                  'currency': 'LKR',
                  'amount': '123.45',
                  'hash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                },
              },
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(launched, 0);
      expect(tester.takeException(), isNull);
    });
  }
  for (final gated in [true, false]) {
    testWidgets(
      'Pay Now invokes initialization; gated=$gated and never claims paid access',
      (tester) async {
        var initialized = 0, launched = 0;
        final keys = <String>[];
        final repository = CheckoutSubmissionRepository((
          name,
          headers,
          body,
        ) async {
          initialized++;
          keys.add(headers['Idempotency-Key']!);
          expect(name, 'initialize-checkout');
          expect((body as Map)['order_id'], orderId);
          if (gated)
            throw const FunctionException(
              status: 503,
              details: 'private/provider-secret',
            );
          return const FunctionResponse(
            status: 201,
            data: {
              'data': {
                'order_id': orderId,
                'attempt_id': attempt,
                'status': 'pending_payment',
                'checkout': {
                  'action': 'https://sandbox.payhere.lk/pay/checkout',
                  'fields': {
                    'first_name': 'Sample',
                    'last_name': 'Student',
                    'email': 'sample@example.test',
                    'phone': '+94771234567',
                    'address': 'Test Street',
                    'city': 'Colombo',
                    'country': 'Sri Lanka',
                    'return_url': 'https://app.example.test/return',
                    'cancel_url': 'https://app.example.test/cancel',
                    'notify_url': 'https://app.example.test/notify',
                    'merchant_id': '123456',
                    'order_id': attempt,
                    'items': 'Sample Course',
                    'currency': 'LKR',
                    'amount': '123.45',
                    'hash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                  },
                },
              },
            },
          );
        });
        final container = ProviderContainer(
          overrides: [
            checkoutActorProvider.overrideWithValue('synthetic-student'),
            checkoutProvider.overrideWith(ReadyCheckout.new),
            checkoutSubmissionRepositoryProvider.overrideWithValue(repository),
            paymentLauncherProvider.overrideWithValue((payment) async {
              launched++;
              expect(payment.orderId, orderId);
            }),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const CheckoutScreen(courseId: 'sample-course'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final values = [
          'Sample',
          'Student',
          '+94771234567',
          'Test Street',
          'Colombo',
          'Sri Lanka',
        ];
        for (var i = 0; i < values.length; i++) {
          final field = find.byType(TextField).at(i);
          await tester.ensureVisible(field);
          await tester.enterText(field, values[i]);
        }
        final pay = find.text('Pay Now');
        await tester.ensureVisible(pay);
        await tester.tap(pay);
        await tester.pumpAndSettle();
        expect(initialized, 1);
        expect(launched, gated ? 0 : 1);
        expect(find.textContaining('Payment Successful'), findsNothing);
        expect(find.textContaining('private/provider-secret'), findsNothing);
        expect(
          container.read(checkoutProvider).value!.status,
          'pending_payment',
        );
        if (gated) {
          expect(
            find.textContaining('temporarily unavailable'),
            findsOneWidget,
          );
          await tester.tap(pay);
          await tester.pumpAndSettle();
          expect(keys[0], keys[1]);
          expect(launched, 0);
        }
      },
    );
  }
}
