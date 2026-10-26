/// Maps a backend order status to a student-facing label. Unknown values
/// never leak raw to the UI.
String checkoutStatusLabel(String status) => switch (status) {
  'pending_payment' => 'Awaiting payment',
  'pending_verification' => 'Verification pending',
  'created' => 'Order created',
  'paid' => 'Payment verified',
  'failed' => 'Payment failed',
  'cancelled' => 'Cancelled',
  'refunded' => 'Refunded',
  _ => 'Status unavailable',
};
