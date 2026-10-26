import 'package:web/web.dart' as web;
import 'payment_return_route.dart';

bool restorePaymentReturnLocation() {
  final target = paymentReturnRedirect(Uri.base);
  if (target == null) return false;
  web.window.location.replace(target.toString());
  return true;
}
