import { createPayHereAdapter, PaymentAdapterError } from '../_shared/payments/payhere.mjs';

const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
const contactKeys = ['first_name', 'last_name', 'phone', 'address', 'city', 'country'];
const contact = value => value && typeof value === 'object' && !Array.isArray(value) &&
  Object.keys(value).length === 6 && Object.keys(value).every(key => contactKeys.includes(key)) &&
  contactKeys.every(key => typeof value[key] === 'string' && value[key].trim() &&
    value[key].length <= 200 && !/[\x00-\x1f\x7f]/.test(value[key])) &&
  /^\+?[0-9 ()-]{7,30}$/.test(value.phone);

export function createHandler({ env, fetch: request = globalThis.fetch, onlineCheckoutEnabled = false, paymentConfig }) {
  const config = Object.freeze({ ...paymentConfig });
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const allowed = new Set((env('ACENDRA_CHECKOUT_ALLOWED_ORIGINS') ?? 'http://127.0.0.1:8080')
      .split(',').map(value => value.trim()).filter(Boolean));
    const requestId = crypto.randomUUID();
    const respond = (status, code, data) => new Response(JSON.stringify({
      ...(code ? { error: { code } } : { data }),
      meta: { contract_version: 'v1', request_id: requestId },
    }), {
      status,
      headers: {
        'Content-Type': 'application/json', 'Cache-Control': 'no-store', Vary: 'Origin',
        ...(origin && allowed.has(origin) ? { 'Access-Control-Allow-Origin': origin } : {}),
      },
    });
    if (origin !== null && !allowed.has(origin)) return respond(403, 'ORIGIN_FORBIDDEN');
    if (incoming.method === 'OPTIONS') {
      const headers = (incoming.headers.get('Access-Control-Request-Headers') ?? '')
        .split(',').map(value => value.trim().toLowerCase()).filter(Boolean);
      if (!origin || incoming.headers.get('Access-Control-Request-Method') !== 'POST' ||
          headers.some(value => !['authorization', 'content-type', 'apikey', 'x-client-info', 'idempotency-key'].includes(value))) {
        return respond(403, 'PREFLIGHT_FORBIDDEN');
      }
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': origin, Vary: 'Origin', 'Cache-Control': 'no-store',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info, Idempotency-Key',
        },
      });
    }
    if (incoming.method !== 'POST') return respond(405, 'METHOD_NOT_ALLOWED');
    const authorization = incoming.headers.get('Authorization');
    const key = incoming.headers.get('Idempotency-Key');
    if (!authorization?.startsWith('Bearer ') || authorization.length > 16384) return respond(401, 'AUTH_REQUIRED');
    if (!key || !/^[A-Za-z0-9._:-]{1,128}$/.test(key)) return respond(400, 'INVALID_IDEMPOTENCY_KEY');
    if (!/^application\/json(?:\s*;|$)/i.test(incoming.headers.get('Content-Type') ?? '')) return respond(400, 'INVALID_REQUEST');

    let body;
    try {
      const reader = incoming.body?.getReader();
      if (!reader) return respond(400, 'INVALID_REQUEST');
      const chunks = [];
      let size = 0;
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          size += value.byteLength;
          if (size > 4096) {
            await reader.cancel();
            return respond(413, 'INVALID_REQUEST');
          }
          chunks.push(value);
        }
      } finally {
        reader.releaseLock();
      }
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) {
        bytes.set(chunk, offset);
        offset += chunk.length;
      }
      body = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    } catch {
      return respond(400, 'INVALID_REQUEST');
    }
    if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).length !== 2 ||
        Object.keys(body).some(key => !['order_id', 'customer'].includes(key)) || !uuid(body.order_id) || !contact(body.customer)) {
      return respond(400, 'INVALID_REQUEST');
    }
    // Only synthetic collaborators opt in. Deployment has no environment bypass.
    if (onlineCheckoutEnabled !== true) return respond(503, 'ONLINE_CHECKOUT_UNAVAILABLE');
    const url = env('SUPABASE_URL');
    const publicKey = env('SUPABASE_ANON_KEY');
    const serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !publicKey || !serviceKey) return respond(503, 'SERVICE_UNAVAILABLE');

    try {
      // Validate trusted provider configuration before creating an attempt.
      const adapter = createPayHereAdapter(config);
      const result = await request(`${url}/auth/v1/user`, {
        headers: { Authorization: authorization, apikey: publicKey },
        redirect: 'error',
        signal: AbortSignal.timeout(15000),
      });
      if (!result.ok) return respond(401, 'AUTH_REQUIRED');
      const user = await result.json();
      const parts = authorization.slice(7).split('.');
      if (parts.length !== 3) return respond(401, 'AUTH_REQUIRED');
      let claims;
      try {
        // Decode claims only after Auth verifies this exact bearer token.
        const payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        const bytes = Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, '=')), value => value.charCodeAt(0));
        claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
      } catch {
        return respond(401, 'AUTH_REQUIRED');
      }
      if (!claims || typeof claims !== 'object' || Array.isArray(claims) || !uuid(user.id) ||
          user.is_anonymous === true || claims.sub !== user.id || claims.role !== 'authenticated' ||
          !uuid(claims.session_id) || !['aal1', 'aal2'].includes(claims.aal) || typeof user.email !== 'string') {
        return respond(401, 'AUTH_REQUIRED');
      }
      const customer = { ...body.customer, email: user.email };
      // Adapter validates email as well; no malformed customer creates an attempt.
      adapter.createCheckout({
        attemptId: 'validation', orderId: 'validation', method: 'online', provider: 'payhere',
        merchantId: config.merchantId, environment: config.environment, currency: 'LKR',
        amountMinor: '1', title: 'validation',
      }, customer);
      const mutation = await request(`${url}/rest/v1/rpc/csa101_initialize_checkout`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          p_actor: user.id, p_session_id: claims.session_id, p_aal: claims.aal, p_key: key,
          p_order: body.order_id, p_merchant: config.merchantId, p_environment: config.environment,
        }),
        redirect: 'error',
        signal: AbortSignal.timeout(15000),
      });
      const stored = await mutation.json();
      if (!mutation.ok) {
        const errors = {
          '42501': [403, 'FORBIDDEN'], '22023': [409, 'CHECKOUT_CONFLICT'],
          P0002: [404, 'ORDER_NOT_FOUND'], '55000': [409, 'ORDER_NOT_PAYABLE'],
        };
        const [status, code] = errors[stored?.code] ?? [503, 'SERVICE_UNAVAILABLE'];
        return respond(status, code);
      }
      if (!stored || typeof stored.replayed !== 'boolean' || stored.order_id !== body.order_id ||
          !uuid(stored.attempt?.attemptId) || stored.attempt.orderId !== stored.attempt.attemptId) {
        return respond(503, 'SERVICE_UNAVAILABLE');
      }
      const checkout = adapter.createCheckout(stored.attempt, customer);
      return respond(stored.replayed ? 200 : 201, undefined, {
        order_id: stored.order_id, attempt_id: stored.attempt.attemptId, status: 'pending_payment', checkout,
      });
    } catch (error) {
      if (error instanceof PaymentAdapterError && ['INVALID_CUSTOMER', 'INVALID_PAYMENT_INPUT'].includes(error.code)) {
        return respond(400, 'INVALID_CUSTOMER');
      }
      return respond(503, 'SERVICE_UNAVAILABLE');
    }
  };
}
