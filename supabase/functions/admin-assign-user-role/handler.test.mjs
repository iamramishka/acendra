import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from './handler.mjs';

const actor = '06100000-0000-0000-0000-000000000001';
const target = '06100000-0000-0000-0000-000000000002';
const payload = { student_id: target, role_code: 'finance_admin', action: 'grant', reason: 'Approved reviewer', request_id: '06100000-0000-0000-0000-000000000010' };
const token = (claims = {}) => `header.${Buffer.from(JSON.stringify({ sub: actor, role: 'authenticated', aal: 'aal2', session_id: '06100000-0000-0000-0000-000000000099', ...claims })).toString('base64url')}.signature`;
const env = name => ({ SUPABASE_URL: 'http://local', SUPABASE_ANON_KEY: 'public-fixture', SUPABASE_SERVICE_ROLE_KEY: 'private-fixture' })[name];
const incoming = (body = payload, bearer = token()) => new Request('http://local/function', {
  method: 'POST', headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body),
});
const roleResult = { user_id: target, role_code: payload.role_code, action: payload.action, status: 'active', operation_status: 'active', replayed: false, grant_id: '06100000-0000-0000-0000-000000000022', audit_id: '06100000-0000-0000-0000-000000000023' };
const json = (body, status = 200) => new Response(JSON.stringify(body), { status });

test('rejects malformed inputs and actor injection before privileged requests', async () => {
  const handler = createHandler({ env, fetch: () => assert.fail('No request allowed') });
  for (const body of [{ ...payload, actor_id: actor }, { ...payload, aal: 'aal2' }, { ...payload, reason: ' ' }, { ...payload, request_id: 'invalid' }, { ...payload, role_code: 'owner' }]) {
    assert.equal((await handler(incoming(body))).status, 400);
  }
});

test('forged/expired token rejected by Auth before claims are trusted', async () => {
  let calls = 0;
  const handler = createHandler({ env, fetch: async () => { calls++; return json({ message: 'private details' }, 401); } });
  const result = await handler(incoming());
  assert.equal(result.status, 401);
  assert.equal(calls, 1);
  assert.ok(!(await result.text()).includes('private'));
});

test('MFA and verified subject mismatch fail closed', async () => {
  const handler = createHandler({ env, fetch: async () => json({ id: actor }) });
  assert.equal((await handler(incoming(payload, token({ aal: 'aal1' })))).status, 403);
  assert.equal((await handler(incoming(payload, token({ sub: target })))).status, 401);
  assert.equal((await handler(incoming(payload, token({ role: 'service_role' })))).status, 401);
  assert.equal((await handler(incoming(payload, token({ session_id: null })))).status, 401);
});

test('only verified actor and verified assurance reach the restricted RPC', async () => {
  const calls = [];
  const handler = createHandler({ env, fetch: async (url, options) => {
    calls.push({ url, options });
    return url.endsWith('/user') ? json({ id: actor }) : json(roleResult);
  } });
  const result = await handler(incoming());
  assert.equal(result.status, 200);
  assert.equal(calls.length, 2);
  const request = JSON.parse(calls[1].options.body);
  assert.equal(calls[1].url, 'http://local/rest/v1/rpc/csa073_change_role');
  assert.equal(request.p_session_id, '06100000-0000-0000-0000-000000000099');
  assert.equal(request.p_actor, actor);
  assert.equal(request.p_aal, 'aal2');
  assert.equal(request.p_request_id, payload.request_id);
  assert.ok(!(await result.text()).includes('private-fixture'));
});

test('SQL failures and transport errors never expose privileged details', async () => {
  const handler = createHandler({ env, fetch: async url => url.endsWith('/user') ? json({ id: actor }) : json({ code: '42501', message: 'private-fixture' }, 403) });
  const denied = await handler(incoming());
  assert.equal(denied.status, 403);
  assert.ok(!(await denied.text()).includes('private-fixture'));
  const offline = createHandler({ env, fetch: async () => { throw new Error('private-fixture'); } });
  assert.equal((await offline(incoming())).status, 503);
});

test('approved browser preflight permits only the required method and headers without authentication', async () => {
  const handler = createHandler({ env, fetch: () => assert.fail('Preflight must not perform privileged requests') });
  const preflight = (origin = 'http://127.0.0.1:8080', method = 'POST', headers = 'Authorization, Content-Type, apikey, x-client-info') => new Request('http://local/function', {
    method: 'OPTIONS', headers: { Origin: origin, 'Access-Control-Request-Method': method, 'Access-Control-Request-Headers': headers },
  });
  const result = await handler(preflight());
  assert.equal(result.status, 204);
  assert.equal(await result.text(), '');
  assert.equal(result.headers.get('Access-Control-Allow-Origin'), 'http://127.0.0.1:8080');
  assert.equal(result.headers.get('Access-Control-Allow-Methods'), 'POST');
  assert.equal(result.headers.get('Access-Control-Allow-Headers'), 'Authorization, Content-Type, apikey, x-client-info');
  assert.equal(result.headers.get('Vary'), 'Origin');
  assert.equal(result.headers.get('Access-Control-Allow-Credentials'), null);
  assert.equal((await handler(preflight(undefined, 'DELETE'))).status, 405);
  assert.equal((await handler(preflight(undefined, undefined, 'X-Injected-Actor'))).status, 403);
});

test('supplied origins require exact allowlist matches; configured origins replace local defaults', async () => {
  const configuredEnv = name => name === 'ACENDRA_ADMIN_ALLOWED_ORIGINS'
    ? 'https://admin.example.test, https://staff.example.test' : env(name);
  const handler = createHandler({ env: configuredEnv, fetch: () => assert.fail('Denied origins must not make requests') });
  for (const origin of ['https://evil.test', 'https://admin.example.test.evil.test', 'null', 'http://127.0.0.1:8080']) {
    const request = incoming();
    request.headers.set('Origin', origin);
    const result = await handler(request);
    assert.equal(result.status, 403);
    assert.equal(result.headers.get('Access-Control-Allow-Origin'), null);
  }
  const result = await handler(new Request('http://local/function', { method: 'OPTIONS', headers: {
    Origin: 'https://staff.example.test', 'Access-Control-Request-Method': 'POST',
  } }));
  assert.equal(result.status, 204);
  assert.equal(result.headers.get('Access-Control-Allow-Origin'), 'https://staff.example.test');
});

test('approved browser receives CORS on success and failures while server calls require no Origin', async () => {
  const browserRequest = (body = payload, bearer = token()) => {
    const request = incoming(body, bearer);
    request.headers.set('Origin', 'http://127.0.0.1:8080');
    return request;
  };
  const success = createHandler({ env, fetch: async url => url.endsWith('/user') ? json({ id: actor }) : json(roleResult) });
  const denied = createHandler({ env, fetch: async () => json({}, 401) });
  const offline = createHandler({ env, fetch: async () => { throw new Error('private-fixture'); } });
  for (const [handler, request, status] of [
    [success, browserRequest(), 200],
    [success, browserRequest({ ...payload, actor_id: actor }), 400],
    [denied, browserRequest(), 401],
    [success, browserRequest(payload, token({ aal: 'aal1' })), 403],
    [offline, browserRequest(), 503],
  ]) {
    const result = await handler(request);
    assert.equal(result.status, status);
    assert.equal(result.headers.get('Access-Control-Allow-Origin'), 'http://127.0.0.1:8080');
    assert.equal(result.headers.get('Vary'), 'Origin');
  }
  const server = await success(incoming());
  assert.equal(server.status, 200);
  assert.equal(server.headers.get('Access-Control-Allow-Origin'), null);
  assert.equal((await success(new Request('http://local/function', { method: 'OPTIONS' }))).status, 403);
});
