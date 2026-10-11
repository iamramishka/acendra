// Synthetic protocol fixtures exercise local behavior; these are not PayHere
// sandbox observations or evidence that a merchant account is ready.
import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createPayHereAdapter, formatLkr, PaymentAdapterError } from './payhere.mjs';

const config = () => ({ ready: true, environment: 'sandbox', merchantId: '123456',
  merchantSecret: 'synthetic-merchant-secret', appId: 'synthetic-app', appSecret: 'synthetic-app-secret',
  returnUrl: 'https://example.test/return', cancelUrl: 'https://example.test/cancel',
  notifyUrl: 'https://example.test/notify' });
const attempt = () => ({ provider: 'payhere', method: 'online', environment: 'sandbox',
  merchantId: '123456', currency: 'LKR', attemptId: 'attempt-1', orderId: 'order-1',
  amountMinor: '12345', title: 'Synthetic course' });
const customer = { first_name: 'Test', last_name: 'Student', email: 'test@example.test',
  phone: '+94111234567', address: 'Synthetic address', city: 'Colombo', country: 'Sri Lanka' };
const digest = (input) => createHash('md5').update(input, 'utf8').digest('hex').toUpperCase();
// Independently construct protocol signatures; never ask the adapter to generate
// the signature that its own verifier will check.
const notification = (overrides = {}) => {
  const values = { merchant_id: '123456', order_id: 'order-1', payment_id: '9007199254740993',
    payhere_amount: '123.45', payhere_currency: 'LKR', status_code: '2', ...overrides };
  values.md5sig = digest(values.merchant_id + values.order_id + values.payhere_amount +
    values.payhere_currency + values.status_code + digest(config().merchantSecret));
  return new URLSearchParams(values);
};
const payment = (overrides = {}) => ({ payment_id: '9007199254740993', order_id: 'order-1',
  status: 'RECEIVED', currency: 'LKR', amount: '123.45',
  amount_detail: { currency: 'LKR', exchange_from: 'LKR', exchange_to: 'LKR', exchange_rate: '1.00', gross: '123.45' },
  ...overrides });
const response = (value) => new Response(JSON.stringify(value));
const harness = (rows = [payment()], token = { token_type: 'Bearer', access_token: 'synthetic-token' }) => {
  const calls = [];
  const adapter = createPayHereAdapter(config(), { fetch: async (url, options) => {
    calls.push({ url, options });
    return calls.length === 1 ? response(token) : response({ status: 1, data: rows });
  } });
  return { adapter, calls };
};
const errorCode = (expected) => (error) => error instanceof PaymentAdapterError && error.code === expected;
const rejectsSettlement = async (rows, code = 'SETTLEMENT_NOT_VERIFIED') => {
  const { adapter } = harness(rows);
  const verified = adapter.verifyNotification(notification(), attempt());
  await assert.rejects(adapter.retrieveSettlement(verified, attempt()), errorCode(code));
};

test('exact LKR formatting preserves minor units including signed bigint boundary', () => {
  for (const [input, expected] of [['1', '0.01'], ['99', '0.99'], ['100', '1.00'],
    ['12345', '123.45'], ['9223372036854775807', '92233720368547758.07']]) assert.equal(formatLkr(input), expected);
  for (const value of ['0', '-1', '01', '1.2', '1e3', '9223372036854775808', 12345, null])
    assert.throws(() => formatLkr(value), errorCode('INVALID_AMOUNT'));
});

test('checkout uses trusted exact terms and independent wire checksum', () => {
  const checkout = createPayHereAdapter(config()).createCheckout(attempt(), customer);
  assert.equal(checkout.action, 'https://sandbox.payhere.lk/pay/checkout');
  assert.equal(checkout.fields.amount, '123.45');
  assert.equal(checkout.fields.currency, 'LKR');
  assert.equal(checkout.fields.merchant_id, '123456');
  assert.equal(checkout.fields.order_id, 'order-1');
  assert.equal(checkout.fields.hash, digest('123456order-1123.45LKR' + digest('synthetic-merchant-secret')));
  assert.equal(checkout.fields.notify_url, 'https://example.test/notify');
  assert.equal(JSON.stringify(checkout).includes(config().merchantSecret), false);
  assert.equal(JSON.stringify(checkout).includes(config().appSecret), false);
  const production = createPayHereAdapter({ ...config(), environment: 'production' });
  assert.equal(production.createCheckout({ ...attempt(), environment: 'production' }, customer).action, 'https://www.payhere.lk/pay/checkout');
});

test('checkout fails closed for absent readiness, invalid endpoints and incompatible scope', () => {
  for (const fields of [{ ready: false }, { environment: 'preview' }])
    assert.throws(() => createPayHereAdapter({ ...config(), ...fields }), errorCode('PAYMENT_NOT_CONFIGURED'));
  for (const returnUrl of ['http://example.test', 'https://user:password@example.test', 'https://example.test/#fragment'])
    assert.throws(() => createPayHereAdapter({ ...config(), returnUrl }), errorCode('INVALID_CONFIGURATION'));
  for (const fields of [{ currency: 'USD' }, { environment: 'production' }, { merchantId: 'other' }, { method: 'bank_transfer' }, { provider: 'other' }])
    assert.throws(() => createPayHereAdapter(config()).createCheckout({ ...attempt(), ...fields }, customer), errorCode('PAYMENT_SCOPE_MISMATCH'));
  assert.throws(() => createPayHereAdapter(config()).createCheckout(attempt(), { ...customer, email: 'invalid' }), errorCode('INVALID_CUSTOMER'));
});

test('callback requires each signed field exactly once and validates signature', () => {
  const adapter = createPayHereAdapter(config());
  for (const key of ['merchant_id', 'order_id', 'payment_id', 'payhere_amount', 'payhere_currency', 'status_code', 'md5sig']) {
    const missing = notification(); missing.delete(key);
    assert.throws(() => adapter.verifyNotification(missing, attempt()), errorCode('INVALID_NOTIFICATION'));
    const duplicate = notification(); duplicate.append(key, duplicate.get(key));
    assert.throws(() => adapter.verifyNotification(duplicate, attempt()), errorCode('INVALID_NOTIFICATION'));
  }
  const forged = notification(); forged.set('md5sig', '0'.repeat(32));
  assert.throws(() => adapter.verifyNotification(forged, attempt()), errorCode('INVALID_SIGNATURE'));
  const lowercase = notification(); lowercase.set('md5sig', lowercase.get('md5sig').toLowerCase());
  assert.equal(adapter.verifyNotification(lowercase, attempt()).evidence, 'checksum_only');
  assert.throws(() => adapter.verifyNotification({}, attempt()), errorCode('INVALID_NOTIFICATION'));
});

test('callback rejects scope mismatches and malformed amount/status/reference values', () => {
  const adapter = createPayHereAdapter(config());
  for (const fields of [{ merchant_id: 'another' }, { order_id: 'other' }, { payhere_currency: 'USD' }, { payhere_amount: '123.46' }])
    assert.throws(() => adapter.verifyNotification(notification(fields), attempt()), errorCode('PAYMENT_SCOPE_MISMATCH'));
  for (const payhere_amount of ['1e2', '123.450', '0123.45', '-123.45'])
    assert.throws(() => adapter.verifyNotification(notification({ payhere_amount }), attempt()), errorCode('INVALID_PROVIDER_AMOUNT'));
  for (const fields of [{ status_code: '1' }, { payment_id: 'not-a-number' }])
    assert.throws(() => adapter.verifyNotification(notification(fields), attempt()), errorCode('INVALID_NOTIFICATION'));
});

test('unsigned payment reference is only checksum evidence and needs matching retrieval', async () => {
  const { adapter, calls } = harness();
  const form = notification(); form.set('payment_id', '999'); // checksum is still valid
  const verified = adapter.verifyNotification(form, attempt());
  assert.equal(verified.evidence, 'checksum_only');
  assert.equal(Object.isFrozen(verified), true);
  await assert.rejects(adapter.retrieveSettlement(verified, attempt()), errorCode('SETTLEMENT_NOT_VERIFIED'));
  assert.equal(calls.length, 2);
});

test('successful authenticated retrieval binds exact reference/order/money and scoped endpoint', async () => {
  const { adapter, calls } = harness();
  const verified = adapter.verifyNotification(notification(), attempt());
  const settlement = await adapter.retrieveSettlement(verified, attempt());
  assert.equal(settlement.paymentId, '9007199254740993');
  assert.equal(settlement.amountMinor, '12345');
  assert.equal(settlement.merchantId, '123456');
  assert.equal(settlement.environment, 'sandbox');
  assert.equal(settlement.evidence, 'authenticated_retrieval');
  assert.equal(Object.isFrozen(settlement), true);
  assert.equal(calls[0].url, 'https://sandbox.payhere.lk/merchant/v1/oauth/token');
  assert.equal(calls[0].options.body, 'grant_type=client_credentials');
  assert.equal(calls[0].options.headers.Authorization, 'Basic ' + Buffer.from('synthetic-app:synthetic-app-secret').toString('base64'));
  assert.equal(calls[1].url, 'https://sandbox.payhere.lk/merchant/v1/payment/search?order_id=order-1');
  assert.equal(calls[1].options.headers.Authorization, 'Bearer synthetic-token');
  for (const { options } of calls) { assert.equal(options.redirect, 'error'); assert.ok(options.signal instanceof AbortSignal); }
});

test('retrieval denies fabricated/cross-adapter notifications and non-success callbacks before I/O', async () => {
  const { adapter, calls } = harness();
  const valid = adapter.verifyNotification(notification(), attempt());
  for (const candidate of [{ ...valid }, createPayHereAdapter(config()).verifyNotification(notification(), attempt())])
    await assert.rejects(adapter.retrieveSettlement(candidate, attempt()), errorCode('UNVERIFIED_NOTIFICATION'));
  for (const status_code of ['0', '-1', '-2', '-3']) {
    const candidate = adapter.verifyNotification(notification({ status_code }), attempt());
    await assert.rejects(adapter.retrieveSettlement(candidate, attempt()), errorCode('UNVERIFIED_NOTIFICATION'));
  }
  for (const fields of [{ attemptId: 'another' }, { orderId: 'another' }, { amountMinor: '12346' }])
    await assert.rejects(adapter.retrieveSettlement(valid, { ...attempt(), ...fields }), errorCode('UNVERIFIED_NOTIFICATION'));
  assert.equal(calls.length, 0);
});

test('retrieval rejects missing/ambiguous references, different orders and refunded states', async () => {
  await rejectsSettlement([]);
  await rejectsSettlement([payment(), payment()]);
  await rejectsSettlement([payment({ payment_id: '999' })]);
  for (const fields of [{ order_id: 'another' }, { currency: 'USD' }, { amount: '123.46' },
    { status: 'REFUNDED' }, { status: 'PARTIALLY_REFUNDED' }, { status: 'PENDING' }, { status: 'FAILED' }])
    await rejectsSettlement([payment(fields)]);
  // Multiple distinct real payments may be found: only the exact callback ID is bound.
  const { adapter } = harness([payment({ payment_id: '999' }), payment()]);
  assert.equal((await adapter.retrieveSettlement(adapter.verifyNotification(notification(), attempt()), attempt())).paymentId, '9007199254740993');
});

test('retrieval validates gross amount and LKR conversion detail, never net-only evidence', async () => {
  for (const fields of [{ gross: '120.00' }, { currency: 'USD' }, { exchange_from: 'USD' },
    { exchange_to: 'USD' }, { exchange_rate: '0.99' }])
    await rejectsSettlement([payment({ amount_detail: { ...payment().amount_detail, ...fields } })]);
  await rejectsSettlement([payment({ amount_detail: null })]);
  // A fee-reduced net value cannot silently substitute for the bound amount.
  await rejectsSettlement([payment({ amount: '120.00' })]);
});

test('numeric provider money/IDs preserve JSON lexemes beyond floating point precision', async () => {
  let calls = 0;
  const adapter = createPayHereAdapter(config(), { fetch: async () => ++calls === 1
    ? response({ token_type: 'bearer', access_token: 'synthetic-token' })
    : new Response('{"status":1,"data":[{"payment_id":9007199254740993,"order_id":"order-1","status":"RECEIVED","currency":"LKR","amount":123.45,"amount_detail":{"currency":"LKR","exchange_from":"LKR","exchange_to":"LKR","exchange_rate":1.00,"gross":123.45}}]}') });
  const result = await adapter.retrieveSettlement(adapter.verifyNotification(notification(), attempt()), attempt());
  assert.equal(result.paymentId, '9007199254740993');
  assert.equal(result.amountMinor, '12345');
});

test('network errors, redirects, failed responses, invalid tokens and malformed payloads fail closed', async () => {
  const fetchers = [async () => { throw new Error('network/redirect'); },
    async () => new Response('private provider error', { status: 503 }),
    async () => new Response('redirect', { status: 302 }),
    async () => new Response('{bad-json'),
    async () => response({ token_type: 'Basic', access_token: 'token' })];
  for (let index = 0; index < fetchers.length; index++) {
    const adapter = createPayHereAdapter(config(), { fetch: fetchers[index] });
    await assert.rejects(adapter.retrieveSettlement(adapter.verifyNotification(notification(), attempt()), attempt()),
      errorCode(index < 3 ? 'PROVIDER_UNAVAILABLE' : 'INVALID_PROVIDER_RESPONSE'));
  }
  const { adapter } = harness([], { token_type: 'Bearer', access_token: 'token\r\ninjected' });
  await assert.rejects(adapter.retrieveSettlement(adapter.verifyNotification(notification(), attempt()), attempt()), errorCode('INVALID_PAYMENT_INPUT'));
});

test('provider response byte limit cancels oversized streams', async () => {
  let cancelled = false;
  const adapter = createPayHereAdapter(config(), { fetch: async () => new Response(new ReadableStream({
    start(controller) { controller.enqueue(new Uint8Array(262145)); },
    cancel() { cancelled = true; },
  })) });
  await assert.rejects(adapter.retrieveSettlement(adapter.verifyNotification(notification(), attempt()), attempt()), errorCode('INVALID_PROVIDER_RESPONSE'));
  assert.equal(cancelled, true);
});

test('configuration and attempt are stable while caller changes them across asynchronous I/O', async () => {
  const mutableConfig = config(); const mutableAttempt = attempt();
  let release; const gate = new Promise(resolve => { release = resolve; }); let calls = 0;
  const adapter = createPayHereAdapter(mutableConfig, { fetch: async (url, options) => {
    if (++calls === 1) { await gate; return response({ token_type: 'Bearer', access_token: 'synthetic-token' }); }
    assert.equal(url, 'https://sandbox.payhere.lk/merchant/v1/payment/search?order_id=order-1');
    assert.equal(options.headers.Authorization, 'Bearer synthetic-token');
    return response({ status: 1, data: [payment()] });
  } });
  const verified = adapter.verifyNotification(notification(), mutableAttempt);
  const pending = adapter.retrieveSettlement(verified, mutableAttempt);
  mutableConfig.environment = 'production'; mutableConfig.merchantId = 'attacker'; mutableConfig.merchantSecret = 'attacker';
  mutableAttempt.orderId = 'attacker'; mutableAttempt.amountMinor = '999'; mutableAttempt.attemptId = 'attacker';
  release();
  const result = await pending;
  assert.equal(result.orderId, 'order-1'); assert.equal(result.amountMinor, '12345');
  assert.equal(result.environment, 'sandbox'); assert.equal(result.merchantId, '123456');
});
