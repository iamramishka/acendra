// Trusted backend module only. MD5 is required by PayHere's wire protocol.
import { createHash, timingSafeEqual } from 'node:crypto';

export class PaymentAdapterError extends Error {
  constructor(code) { super(code); this.name = 'PaymentAdapterError'; this.code = code; }
}
const deny = (code) => { throw new PaymentAdapterError(code); };
const text = (value, max = 500) => {
  if (typeof value !== 'string' || !value.trim() || value.length > max || /[\x00-\x1f\x7f]/.test(value)) deny('INVALID_PAYMENT_INPUT');
  return value;
};
const md5 = (value) => createHash('md5').update(value, 'utf8').digest('hex').toUpperCase();
const minor = (value) => {
  if (typeof value !== 'string' || !/^(0|[1-9][0-9]{0,18})$/.test(value)) deny('INVALID_AMOUNT');
  const result = BigInt(value);
  if (result <= 0n || result > 9223372036854775807n) deny('INVALID_AMOUNT');
  return result;
};
export const formatLkr = (value) => {
  const amount = minor(value);
  return `${amount / 100n}.${(amount % 100n).toString().padStart(2, '0')}`;
};
const decimalMinor = (value) => {
  if (typeof value !== 'string' || !/^(0|[1-9][0-9]{0,16})(\.[0-9]{1,2})?$/.test(value)) deny('INVALID_PROVIDER_AMOUNT');
  const [whole, fraction = ''] = value.split('.');
  return minor((BigInt(whole) * 100n + BigInt(fraction.padEnd(2, '0'))).toString());
};
const httpsUrl = (value) => {
  let url;
  try { url = new URL(text(value, 2000)); } catch { deny('INVALID_CONFIGURATION'); }
  if (url.protocol !== 'https:' || url.username || url.password || url.hash) deny('INVALID_CONFIGURATION');
  return url.href;
};

// Preserve JSON numeric lexemes before parsing: money/reference IDs never pass
// through binary floating point, including IDs beyond Number.MAX_SAFE_INTEGER.
const exactJson = (body) => {
  try {
    return JSON.parse(body.replace(/"(?:[^"\\]|\\.)*"|-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/g,
      (token) => token.startsWith('"') ? token : JSON.stringify(token)));
  } catch { deny('INVALID_PROVIDER_RESPONSE'); }
};

export function createPayHereAdapter(config, { fetch: fetcher = globalThis.fetch } = {}) {
  if (!config || !['sandbox', 'production'].includes(config.environment) || config.ready !== true) deny('PAYMENT_NOT_CONFIGURED');
  const merchant = text(config.merchantId, 100);
  const secret = text(config.merchantSecret, 500);
  const appId = text(config.appId, 500);
  const appSecret = text(config.appSecret, 500);
  if (!/^[\x21-\x7e]+$/.test(appId + appSecret) || appId.includes(':')) deny('INVALID_CONFIGURATION');
  const urls = { return_url: httpsUrl(config.returnUrl), cancel_url: httpsUrl(config.cancelUrl), notify_url: httpsUrl(config.notifyUrl) };
  const origin = config.environment === 'sandbox' ? 'https://sandbox.payhere.lk' : 'https://www.payhere.lk';
  const verified = new WeakSet();
  const terms = (attempt) => {
    if (!attempt || attempt.provider !== 'payhere' || attempt.method !== 'online' || attempt.environment !== config.environment || attempt.merchantId !== merchant || attempt.currency !== 'LKR') deny('PAYMENT_SCOPE_MISMATCH');
    text(attempt.attemptId, 100); text(attempt.orderId, 100);
    return formatLkr(attempt.amountMinor);
  };
  const request = async (url, options) => {
    try {
      const response = await fetcher(url, { ...options, redirect: 'error', signal: AbortSignal.timeout(10000) });
      if (!response.ok) deny('PROVIDER_UNAVAILABLE');
      // Stream bound avoids buffering unbounded provider/error payloads.
      const reader = response.body?.getReader();
      if (!reader) deny('INVALID_PROVIDER_RESPONSE');
      let length = 0; const chunks = [];
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          length += value.byteLength;
          if (length > 262144) { await reader.cancel(); deny('INVALID_PROVIDER_RESPONSE'); }
          chunks.push(value);
        }
      } finally { reader.releaseLock(); }
      const bytes = new Uint8Array(length); let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
      return exactJson(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    } catch (error) {
      if (error instanceof PaymentAdapterError) throw error;
      deny('PROVIDER_UNAVAILABLE');
    }
  };
  return Object.freeze({
    createCheckout(attempt, customer) {
      const amount = terms(attempt);
      const details = {};
      for (const key of ['first_name', 'last_name', 'email', 'phone', 'address', 'city', 'country']) details[key] = text(customer?.[key], 200);
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(details.email) || !/^\+?[0-9 ()-]{7,30}$/.test(details.phone)) deny('INVALID_CUSTOMER');
      return { action: `${origin}/pay/checkout`, fields: {
        ...details, ...urls, merchant_id: merchant, order_id: attempt.orderId,
        items: text(attempt.title, 200), currency: 'LKR', amount,
        hash: md5(merchant + attempt.orderId + amount + 'LKR' + md5(secret)),
      } };
    },
    verifyNotification(form, attempt) {
      terms(attempt);
      if (!(form instanceof URLSearchParams)) deny('INVALID_NOTIFICATION');
      const values = {};
      for (const key of ['merchant_id', 'order_id', 'payment_id', 'payhere_amount', 'payhere_currency', 'status_code', 'md5sig']) {
        if (form.getAll(key).length !== 1) deny('INVALID_NOTIFICATION');
        values[key] = text(form.get(key));
      }
      if (values.merchant_id !== merchant || values.order_id !== attempt.orderId || values.payhere_currency !== 'LKR' || decimalMinor(values.payhere_amount) !== minor(attempt.amountMinor)) deny('PAYMENT_SCOPE_MISMATCH');
      if (!['2', '0', '-1', '-2', '-3'].includes(values.status_code) || !/^[0-9]{1,100}$/.test(values.payment_id) || !/^[A-Fa-f0-9]{32}$/.test(values.md5sig)) deny('INVALID_NOTIFICATION');
      const expected = md5(merchant + values.order_id + values.payhere_amount + 'LKR' + values.status_code + md5(secret));
      if (!timingSafeEqual(new TextEncoder().encode(expected), new TextEncoder().encode(values.md5sig.toUpperCase()))) deny('INVALID_SIGNATURE');
      const result = Object.freeze({ attemptId: attempt.attemptId, orderId: attempt.orderId, amountMinor: attempt.amountMinor, currency: 'LKR', merchantId: merchant, environment: config.environment, provider: 'payhere', paymentId: values.payment_id, statusCode: values.status_code, evidence: 'checksum_only' });
      verified.add(result);
      return result;
    },
    async retrieveSettlement(notification, attempt) {
      terms(attempt);
      if (!verified.has(notification) || notification.statusCode !== '2' || notification.attemptId !== attempt.attemptId || notification.orderId !== attempt.orderId || notification.amountMinor !== attempt.amountMinor) deny('UNVERIFIED_NOTIFICATION');
      const token = await request(`${origin}/merchant/v1/oauth/token`, { method: 'POST', headers: { Authorization: `Basic ${btoa(appId + ':' + appSecret)}`, 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'grant_type=client_credentials' });
      if (!token || token.token_type?.toLowerCase() !== 'bearer') deny('INVALID_PROVIDER_RESPONSE');
      const accessToken = text(token.access_token, 2000);
      const data = await request(`${origin}/merchant/v1/payment/search?order_id=${encodeURIComponent(attempt.orderId)}`, { method: 'GET', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' } });
      if (data?.status !== '1' || !Array.isArray(data.data)) deny('SETTLEMENT_NOT_VERIFIED');
      const matches = data.data.filter((row) => row?.payment_id === notification.paymentId);
      if (matches.length !== 1) deny('SETTLEMENT_NOT_VERIFIED');
      const row = matches[0];
      if (row.order_id !== attempt.orderId || row.status !== 'RECEIVED' || row.currency !== 'LKR' || decimalMinor(row.amount) !== minor(attempt.amountMinor)) deny('SETTLEMENT_NOT_VERIFIED');
      const detail = row.amount_detail;
      if (!detail || detail.currency !== 'LKR' || detail.exchange_from !== 'LKR' || detail.exchange_to !== 'LKR' ||
          !['1', '1.0', '1.00'].includes(detail.exchange_rate) || decimalMinor(detail.gross) !== minor(attempt.amountMinor)) deny('SETTLEMENT_NOT_VERIFIED');
      return Object.freeze({ provider: 'payhere', merchantId: merchant, environment: config.environment, attemptId: attempt.attemptId, orderId: attempt.orderId, paymentId: notification.paymentId, amountMinor: attempt.amountMinor, currency: 'LKR', evidence: 'authenticated_retrieval', retrievedAt: new Date().toISOString() });
    },
  });
}
