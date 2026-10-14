import 'package:acendra/features/checkout/domain/entities/payment_handoff.dart';
import 'package:web/web.dart' as web;

Future<void> launchPayment(PaymentHandoff payment) async {
  final form = web.HTMLFormElement()
    ..method = 'POST'
    ..action = payment.action.toString()
    ..style.display = 'none';
  for (final entry in payment.fields.entries) {
    form.appendChild(
      web.HTMLInputElement()
        ..type = 'hidden'
        ..name = entry.key
        ..value = entry.value,
    );
  }
  web.document.body!.appendChild(form);
  try {
    form.submit();
  } finally {
    form.remove();
  }
}
