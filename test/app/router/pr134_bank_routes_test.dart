@TestOn('browser')
library;

import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bank flow caller URLs match the registered nested routes', () {
    final container = ProviderContainer(
      overrides: [
        sessionRestoredProvider.overrideWithValue(true),
        isAuthenticatedProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    for (final template in [
      RouteNames.bankTransfer,
      RouteNames.receiptStatus,
      RouteNames.receiptResubmit,
      RouteNames.financeReview,
    ]) {
      final path = template.replaceFirst(':orderId', 'test-order');
      expect(path.contains(':'), isFalse);
      final match = router.configuration.findMatch(Uri.parse(path));
      expect(match.isError, isFalse, reason: path);
    }
  });
}
