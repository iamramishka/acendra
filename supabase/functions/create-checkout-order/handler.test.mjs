import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from './handler.mjs';

const actor = '09800000-0000-0000-0000-000000000001';
const session = '09800000-0000-0000-0000-000000000002';
const course = '09800000-0000-0000-0000-000000000003';
const order = '09800000-0000-0000-0000-000000000004';
const bank = '09800000-0000-0000-0000-000000000005';
const payload = { course_id: course, payment_method: 'online' };
const token = (claims = {}) => `x.${Buffer.from(JSON.stringify({ sub: actor, role: 'authenticated', session_id: session, aal: 'aal1', ...claims })).toString('base64url')}.x`;
const settings = { SUPABASE_URL: 'https://synthetic.invalid', SUPABASE_ANON_KEY: 'synthetic-public', SUPABASE_SERVICE_ROLE_KEY: 'synthetic-private' };
const request = (body = payload, headers = {}, method = 'POST') => new Request('https://checkout.invalid', {
  method, headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json', 'Idempotency-Key': 'synthetic-key:1', ...headers },
  ...(method === 'POST' ? { body: typeof body === 'string' ? body : JSON.stringify(body) } : {}),
});
function fixture({ auth = { id: actor }, rpc = { replayed: false, data: { order_id: order, amount_minor: 25000, currency_code: 'LKR' } }, environment = {}, authStatus = 200, rpcStatus = 200 } = {}) {
  const calls = [];
  const handler = createHandler({ env: key => ({ ...settings, ...environment })[key], fetch: async (url, options) => {
    calls.push({ url, options });
    return calls.length === 1 ? Response.json(auth, { status: authStatus }) : Response.json(rpc, { status: rpcStatus });
  } });
  return { handler, calls };
}
async function error(response, status, code) {
  assert.equal(response.status, status);
  const content = await response.json();
  assert.deepEqual(content.error, { code });
  assert.equal(content.meta.contract_version, 'v1');
  assert.match(content.meta.request_id, /^[0-9a-f-]{36}$/);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  return content;
}

test('verified Auth identity and exact token supply session provenance to service RPC', async () => {
  const { handler, calls } = fixture();
  const response = await handler(request());
  assert.equal(response.status, 201);
  const content = await response.json();
  assert.deepEqual(content.data, { order_id: order, amount_minor: 25000, currency_code: 'LKR' });
  assert.equal(calls.length, 2);
  assert.equal(calls[0].url, 'https://synthetic.invalid/auth/v1/user');
  assert.equal(calls[0].options.headers.Authorization, `Bearer ${token()}`);
  assert.equal(calls[0].options.headers.apikey, 'synthetic-public');
  assert.equal(calls[1].url, 'https://synthetic.invalid/rest/v1/rpc/csa098_create_checkout_order');
  assert.equal(calls[1].options.headers.Authorization, 'Bearer synthetic-private');
  assert.equal(calls[1].options.headers.apikey, 'synthetic-private');
  assert.equal(calls[1].options.method, 'POST');
  assert.deepEqual(JSON.parse(calls[1].options.body), { p_actor: actor, p_session_id: session, p_aal: 'aal1', p_key: 'synthetic-key:1', p_course: course, p_method: 'online', p_bank_version: null });
  for (const call of calls) assert.ok(call.options.signal instanceof AbortSignal);
  assert.ok(!JSON.stringify(content).includes('synthetic-private'));
});

for (const field of ['amount_minor', 'price_minor', 'currency_code', 'buyer_id', 'status', 'p_actor', 'session_id', 'bank_version_id']) {
  test(`client cannot override ${field}`, async () => {
    const { handler, calls } = fixture();
    await error(await handler(request({ ...payload, [field]: 'forged' })), 400, 'INVALID_REQUEST');
    assert.equal(calls.length, 0);
  });
}
for (const body of [null, [], {}, { ...payload, course_id: 'invalid' }, { ...payload, payment_method: 'cash' }, '{', 'null']) {
  test(`invalid checkout structure ${JSON.stringify(body)}`, async () => {
    const { handler, calls } = fixture();
    await error(await handler(request(body)), 400, 'INVALID_REQUEST');
    assert.equal(calls.length, 0);
  });
}
for (const key of ['', 'space key', 'x'.repeat(129), 'key/invalid']) {
  test(`invalid idempotency key ${key.slice(0, 12)}`, async () => {
    const { handler, calls } = fixture();
    await error(await handler(request(payload, { 'Idempotency-Key': key })), 400, 'INVALID_IDEMPOTENCY_KEY');
    assert.equal(calls.length, 0);
  });
}
test('RPC replay returns the stored response with HTTP 200', async () => {
  const original = { order_id: order, amount_minor: 25000, status: 'created' };
  const { handler, calls } = fixture({ rpc: { replayed: true, data: original } });
  const response = await handler(request());
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).data, original);
  assert.equal(JSON.parse(calls[1].options.body).p_key, 'synthetic-key:1');
});
for (const [code, status, publicCode] of [['42501', 403, 'FORBIDDEN'], ['22023', 409, 'ORDER_CONFLICT'], ['P0002', 404, 'COURSE_NOT_FOUND'], ['23505', 409, 'ALREADY_ENROLLED'], ['55000', 503, 'BANK_CHECKOUT_UNAVAILABLE'], ['XX000', 500, 'ORDER_CREATION_FAILED']]) {
  test(`database ${code} is sanitized`, async () => {
    const { handler } = fixture({ rpc: { code, message: 'sensitive database detail', hint: 'private-bank' }, rpcStatus: 400 });
    const content = await error(await handler(request()), status, publicCode);
    assert.ok(!JSON.stringify(content).includes('sensitive'));
    assert.ok(!JSON.stringify(content).includes('private-bank'));
  });
}
test('Auth rejection does not reach RPC', async () => {
  const { handler, calls } = fixture({ authStatus: 401 });
  await error(await handler(request()), 401, 'AUTH_REQUIRED');
  assert.equal(calls.length, 1);
});
for (const jwt of ['broken', 'x.%%%.x', 'x.bnVsbA.x', 'x.W10.x', 'x.ZmFsc2U.x', token({ sub: course }), token({ role: 'service_role' }), token({ session_id: 'invalid' }), token({ aal: 'aal3' })]) {
  test(`invalid verified-token claims ${jwt.slice(0, 20)}`, async () => {
    const { handler, calls } = fixture();
    await error(await handler(request(payload, { Authorization: `Bearer ${jwt}` })), 401, 'AUTH_REQUIRED');
    assert.equal(calls.length, 1);
  });
}
for (const auth of [{ id: actor, is_anonymous: true }, { id: 'invalid' }, { id: course }]) {
  test(`Auth principal is rejected ${JSON.stringify(auth)}`, async () => {
    const { handler, calls } = fixture({ auth });
    await error(await handler(request()), 401, 'AUTH_REQUIRED');
    assert.equal(calls.length, 1);
  });
}
test('aal2 comes from verified token and is forwarded for current-session recheck', async () => {
  const { handler, calls } = fixture();
  assert.equal((await handler(request(payload, { Authorization: `Bearer ${token({ aal: 'aal2' })}` }))).status, 201);
  assert.equal(JSON.parse(calls[1].options.body).p_aal, 'aal2');
});
for (const authorization of ['', 'Basic forged', `Bearer ${'x'.repeat(16385)}`]) {
  test(`missing or oversized bearer rejected before network ${authorization.slice(0, 10)}`, async () => {
    const { handler, calls } = fixture();
    await error(await handler(request(payload, { Authorization: authorization })), 401, 'AUTH_REQUIRED');
    assert.equal(calls.length, 0);
  });
}
test('bank destination is trusted environment configuration', async () => {
  const { handler, calls } = fixture({ environment: { ACENDRA_CHECKOUT_BANK_VERSION_ID: bank } });
  assert.equal((await handler(request({ ...payload, payment_method: 'bank_transfer' }))).status, 201);
  assert.equal(JSON.parse(calls[1].options.body).p_bank_version, bank);
});
for (const bankVersion of [undefined, 'invalid']) {
  test(`bank checkout fails closed without valid configuration ${bankVersion}`, async () => {
    const { handler, calls } = fixture({ environment: { ACENDRA_CHECKOUT_BANK_VERSION_ID: bankVersion } });
    await error(await handler(request({ ...payload, payment_method: 'bank_transfer' })), 503, 'BANK_CHECKOUT_UNAVAILABLE');
    assert.equal(calls.length, 1);
  });
}
for (const key of Object.keys(settings)) {
  test(`missing ${key} disables service`, async () => {
    const { handler, calls } = fixture({ environment: { [key]: undefined } });
    await error(await handler(request()), 503, 'SERVICE_UNAVAILABLE');
    assert.equal(calls.length, 0);
  });
}
test('unapproved origin is forbidden before any network access', async () => {
  const { handler, calls } = fixture();
  const response = await handler(request(payload, { Origin: 'https://evil.invalid' }));
  await error(response, 403, 'ORIGIN_FORBIDDEN');
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), null);
  assert.equal(calls.length, 0);
});
test('allowed origin gets exact CORS and safe preflight', async () => {
  const { handler, calls } = fixture();
  const response = await handler(request(undefined, { Origin: 'http://127.0.0.1:8080', 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'Authorization, Content-Type, Idempotency-Key' }, 'OPTIONS'));
  assert.equal(response.status, 204);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), 'http://127.0.0.1:8080');
  assert.equal(calls.length, 0);
});
for (const headers of [{}, { Origin: 'http://127.0.0.1:8080', 'Access-Control-Request-Method': 'GET' }, { Origin: 'http://127.0.0.1:8080', 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'x-forged' }]) {
  test(`invalid preflight ${JSON.stringify(headers)}`, async () => {
    const { handler, calls } = fixture();
    await error(await handler(request(undefined, headers, 'OPTIONS')), 403, 'PREFLIGHT_FORBIDDEN');
    assert.equal(calls.length, 0);
  });
}
test('unsupported HTTP method and non-JSON body rejected', async () => {
  const { handler, calls } = fixture();
  await error(await handler(request(undefined, {}, 'GET')), 405, 'METHOD_NOT_ALLOWED');
  await error(await handler(request(payload, { 'Content-Type': 'text/plain' })), 400, 'INVALID_REQUEST');
  assert.equal(calls.length, 0);
});
test('streaming body size limit applies without Content-Length and cancels reader', async () => {
  const { handler, calls } = fixture();
  let cancelled = false;
  const stream = new ReadableStream({ start(controller) { controller.enqueue(new Uint8Array(4097)); }, cancel() { cancelled = true; } });
  const incoming = new Request('https://checkout.invalid', { method: 'POST', headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json', 'Idempotency-Key': 'bounded' }, body: stream, duplex: 'half' });
  await error(await handler(incoming), 413, 'INVALID_REQUEST');
  assert.equal(cancelled, true);
  assert.equal(calls.length, 0);
});
test('invalid UTF-8 fails before network calls', async () => {
  const { handler, calls } = fixture();
  const incoming = request();
  const malformed = new Request(incoming.url, { method: 'POST', headers: incoming.headers, body: new Uint8Array([0xff]) });
  await error(await handler(malformed), 400, 'INVALID_REQUEST');
  assert.equal(calls.length, 0);
});
for (const failurePhase of ['auth', 'rpc']) {
  for (const failure of ['exception', 'timeout', 'invalid-json']) {
    test(`${failurePhase} ${failure} fails closed and hides diagnostics`, async () => {
      let calls = 0;
      const handler = createHandler({ env: key => settings[key], fetch: async () => {
        calls++;
        if (failurePhase === 'rpc' && calls === 1) return Response.json({ id: actor });
        if (failure === 'invalid-json') return new Response('private upstream details');
        if (failure === 'timeout') throw new DOMException('private upstream timeout', 'TimeoutError');
        throw new Error('private credentials');
      } });
      const content = await error(await handler(request()), 503, 'SERVICE_UNAVAILABLE');
      assert.equal(calls, failurePhase === 'auth' ? 1 : 2);
      assert.ok(!JSON.stringify(content).includes('private'));
    });
  }
}
for (const rpc of [null, {}, { replayed: 'true', data: { order_id: order } }, { replayed: false, data: { order_id: 'bad' } }]) {
  test(`malformed RPC success fails closed ${JSON.stringify(rpc)}`, async () => {
    const { handler } = fixture({ rpc });
    await error(await handler(request()), 503, 'SERVICE_UNAVAILABLE');
  });
}
