import 'package:acendra/features/checkout/presentation/services/payment_return_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final route in ['return', 'cancel']) {
    test(
      'external $route preserves only its order locator inside the hash route',
      () {
        final source = Uri.parse(
          'https://app.example.test/payments/$route?order_id=order-1&status=paid&next=https://attacker.test',
        );
        final target = paymentReturnRedirect(source)!;
        expect(source.resolveUri(target).origin, source.origin);
        expect(target.path, '/');
        expect(target.query, isEmpty);
        final appRoute = Uri.parse(target.fragment);
        expect(appRoute.path, '/payments/$route');
        expect(appRoute.queryParameters, {'order_id': 'order-1'});
        expect(paymentReturnRedirect(source.resolveUri(target)), isNull);
      },
    );
  }
  test(
    'unusual locator text cannot inject a route, status, fragment or origin',
    () {
      const locator = 'x&status=paid/#?next=https://attacker.test';
      final source = Uri.https('app.example.test', '/payments/return', {
        'order_id': locator,
      });
      final target = paymentReturnRedirect(source)!;
      expect(source.resolveUri(target).origin, source.origin);
      expect(Uri.parse(target.fragment).queryParameters, {'order_id': locator});
    },
  );
  test(
    'missing locator opens the unavailable-status route without inventing an order',
    () {
      final target = paymentReturnRedirect(
        Uri.parse('https://app.example.test/payments/return'),
      )!;
      expect(target.fragment, '/payments/return');
    },
  );
  for (final url in [
    'https://app.example.test/#/payments/return?order_id=order-1',
    'https://app.example.test/payments/return#access_token=synthetic-token',
    'https://app.example.test/payments/return#type=recovery',
    'https://app.example.test/marketplace?order_id=order-1',
    'https://app.example.test/payments/return/extra?order_id=order-1',
    'file:///payments/return?order_id=order-1',
  ]) {
    test('does not rewrite an unrelated route or auth fragment: $url', () {
      expect(paymentReturnRedirect(Uri.parse(url)), isNull);
    });
  }
}
