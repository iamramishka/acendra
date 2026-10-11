// Read-only real sandbox verification. Never creates or finalizes a payment.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { createPayHereAdapter, PaymentAdapterError } from '../supabase/functions/_shared/payments/payhere.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const required = ['MERCHANT_ID','MERCHANT_SECRET','APP_ID','APP_SECRET','ORDER_ID','PAYMENT_ID','AMOUNT_MINOR','NOTIFICATION_FILE'];
export async function verifySandbox(env = process.env) {
  const values = {};
  for (const name of required) {
    const value = env[`PAYHERE_SANDBOX_${name}`];
    if (typeof value !== 'string' || !value.trim()) throw new PaymentAdapterError('SANDBOX_CONFIGURATION_REQUIRED');
    values[name] = value;
  }
  const notificationFile = path.resolve(values.NOTIFICATION_FILE);
  const stat = fs.statSync(notificationFile);
  if (!stat.isFile() || stat.size > 16384) throw new PaymentAdapterError('INVALID_NOTIFICATION_FILE');
  const form = new URLSearchParams(fs.readFileSync(notificationFile, 'utf8'));
  const adapter = createPayHereAdapter({ ready: true, environment: 'sandbox',
    merchantId: values.MERCHANT_ID, merchantSecret: values.MERCHANT_SECRET,
    appId: values.APP_ID, appSecret: values.APP_SECRET,
    // Not used by retrieval; no checkout or callback endpoint is created here.
    returnUrl: 'https://example.invalid/return', cancelUrl: 'https://example.invalid/cancel', notifyUrl: 'https://example.invalid/notify',
  });
  const attempt = Object.freeze({ provider: 'payhere', method: 'online', environment: 'sandbox',
    merchantId: values.MERCHANT_ID, currency: 'LKR', amountMinor: values.AMOUNT_MINOR,
    orderId: values.ORDER_ID, attemptId: 'sandbox-acceptance-probe',
  });
  const notification = adapter.verifyNotification(form, attempt);
  if (notification.statusCode !== '2' || notification.paymentId !== values.PAYMENT_ID) throw new PaymentAdapterError('SANDBOX_EXPECTED_PAYMENT_MISMATCH');
  const settlement = await adapter.retrieveSettlement(notification, attempt);
  if (settlement.evidence !== 'authenticated_retrieval' || settlement.environment !== 'sandbox') throw new PaymentAdapterError('SETTLEMENT_NOT_VERIFIED');
  const checks = ['real_callback_checksum','real_oauth_retrieval','payment_order_reference_binding','exact_lkr_top_and_gross_amount'];
  async function rejects(operation, expected) {
    try { await operation(); } catch (error) {
      if (error instanceof PaymentAdapterError && expected.includes(error.code)) return;
      throw new PaymentAdapterError('SANDBOX_NEGATIVE_CHECK_FAILED');
    }
    throw new PaymentAdapterError('SANDBOX_NEGATIVE_CHECK_FAILED');
  }
  const unsigned = new URLSearchParams(form); unsigned.set('payment_id', '0');
  await rejects(() => adapter.retrieveSettlement(adapter.verifyNotification(unsigned, attempt), attempt), ['SETTLEMENT_NOT_VERIFIED']);
  checks.push('changed_unsigned_payment_id_rejected');
  const badSignature = new URLSearchParams(form); badSignature.set('md5sig', '0'.repeat(32));
  await rejects(() => adapter.verifyNotification(badSignature, attempt), ['INVALID_SIGNATURE']);
  const badAmount = new URLSearchParams(form); badAmount.set('payhere_amount', '0.01');
  if (values.AMOUNT_MINOR === '1') badAmount.set('payhere_amount', '0.02');
  await rejects(() => adapter.verifyNotification(badAmount, attempt), ['PAYMENT_SCOPE_MISMATCH']);
  const duplicated = new URLSearchParams(form); duplicated.append('order_id', values.ORDER_ID);
  await rejects(() => adapter.verifyNotification(duplicated, attempt), ['INVALID_NOTIFICATION']);
  checks.push('forged_signature_rejected','changed_amount_rejected','duplicate_fields_rejected');
  // Minimal evidence; no merchant ID, order ID, provider payload, card data or keys.
  const evidence = { version: 1, environment: 'sandbox', completed_at: new Date().toISOString(),
    adapter_sha256: createHash('sha256').update(fs.readFileSync(path.join(root,'supabase/functions/_shared/payments/payhere.mjs'))).digest('hex'), checks,
    limitation: 'Read-only existing successful sandbox payment; this probe does not verify full checkout or fulfillment.',
  };
  const output = path.join(root,'build','payhere-sandbox','evidence.json');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, JSON.stringify(evidence,null,2)+'\n', { mode: 0o600 });
  return evidence;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { const result = await verifySandbox(); console.log(`PASS: ${result.checks.length} real sandbox retrieval checks; private local evidence written.`); }
  catch (error) {
    // Print only adapter codes; never arbitrary filesystem/network diagnostics.
    console.error(`FAIL: ${error instanceof PaymentAdapterError ? error.code : 'SANDBOX_VERIFICATION_FAILED'}`);
    process.exitCode = 1;
  }
}
