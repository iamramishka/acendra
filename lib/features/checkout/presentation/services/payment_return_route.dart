/// Convert only PayHere entry paths into the application's hash route. A URL
/// locates an order; neither its path nor its query can confirm payment.
Uri? paymentReturnRedirect(Uri location) {
  if (!{'http', 'https'}.contains(location.scheme) ||
      location.fragment.isNotEmpty ||
      !{'/payments/return', '/payments/cancel'}.contains(location.path)) {
    return null;
  }
  final orderId = location.queryParameters['order_id'];
  final route = Uri(
    path: location.path,
    queryParameters: orderId == null ? null : {'order_id': orderId},
  );
  // Relative root URL retains the current origin and drops unrelated hints.
  return Uri(path: '/', fragment: route.toString());
}
