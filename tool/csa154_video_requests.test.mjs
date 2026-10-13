import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from '../supabase/functions/authorize-video/handler.mjs';

const actor = '11111111-1111-1111-1111-111111111111';
const lesson = '22222222-2222-2222-2222-222222222222';
const session = '33333333-3333-3333-3333-333333333333';
const privateSentinel = 'PRIVATE_PROVIDER_DIAGNOSTIC_PLAYBACK_ID';
const now = 1_000;
const claims = { sub: actor, role: 'authenticated', session_id: session, aal: 'aal1', exp: 1_400 };
const bearer = overrides => 'Bearer ' + [
  Buffer.from('{}').toString('base64url'),
  Buffer.from(JSON.stringify({ ...claims, ...overrides })).toString('base64url'),
  'syntheticSignature',
].join('.');
const incoming = ({ authorization = bearer(), body = { lesson_id: lesson } } = {}) => new Request('https://test.invalid/authorize-video', {
  method: 'POST', headers: { ...(authorization === null ? {} : { Authorization: authorization }), 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});
function harness({ identity = { id: actor, is_anonymous: false }, authStatus = 200,
  rpcStatus = 403, rpcBody = { code: '42501', message: privateSentinel, details: privateSentinel }, enabled = true, clock = () => now } = {}) {
  const calls = [];
  let signatures = 0;
  const handler = createHandler({
    enabled, clock, env: key => ({ SUPABASE_URL: 'http://localhost:54321', SUPABASE_ANON_KEY: 'synthetic-public-key', SUPABASE_SERVICE_ROLE_KEY: 'synthetic-backend-key' })[key],
    sign: async () => { signatures++; return privateSentinel; },
    fetch: async (url, options) => {
      calls.push({ url, options });
      if (url.endsWith('/auth/v1/user')) return Response.json(identity, { status: authStatus });
      assert.ok(url.endsWith('/rest/v1/rpc/csa136_authorize_video'), 'only trusted authorization RPC may follow Auth verification');
      return Response.json(rpcBody, { status: rpcStatus });
    },
  });
  return { handler, calls, signatures: () => signatures };
}
async function denied(h, request, status, code) {
  const response = await h.handler(request);
  assert.equal(response.status, status);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  const body = await response.text();
  assert.deepEqual(JSON.parse(body), { error: { code } });
  assert.ok(!body.includes(privateSentinel));
  assert.ok(!body.includes('synthetic-backend-key'));
  assert.equal(h.signatures(), 0, 'denial must never mint a playback token');
}
const check = (name, fn) => test('CSA-154 ' + name, fn);

check('disabled provider denies before network and signing', async () => {
  const h = harness({ enabled: false });
  await denied(h, incoming(), 503, 'VIDEO_UNAVAILABLE');
  assert.equal(h.calls.length, 0);
});
for (const authorization of [null, 'Basic credentials', 'Bearer malformed']) {
  check('missing or malformed bearer ' + String(authorization), async () => {
    const h = harness();
    await denied(h, incoming({ authorization }), 401, 'AUTH_REQUIRED');
    assert.equal(h.calls.length, 0);
  });
}
check('provider rejects token even when decoded claims look valid', async () => {
  const h = harness({ authStatus: 401, identity: { message: privateSentinel } });
  await denied(h, incoming(), 401, 'AUTH_REQUIRED');
  assert.equal(h.calls.length, 1);
});
check('anonymous Auth user denied before entitlement RPC', async () => {
  const h = harness({ identity: { id: actor, is_anonymous: true } });
  await denied(h, incoming(), 401, 'AUTH_REQUIRED');
  assert.equal(h.calls.length, 1);
});
for (const [name, overrides] of [
  ['different verified owner', { sub: session }], ['missing session', { session_id: null }],
  ['non-user role', { role: 'service_role' }], ['expired token', { exp: now }],
]) check(name + ' denied before entitlement RPC', async () => {
  const h = harness();
  await denied(h, incoming({ authorization: bearer(overrides) }), 401, 'AUTH_REQUIRED');
  assert.equal(h.calls.length, 1);
});
for (const field of ['user_id', 'course_id', 'playback_id', 'expires_at', 'entitlement_id']) {
  check('caller cannot supply authority field ' + field, async () => {
    const h = harness();
    await denied(h, incoming({ body: { lesson_id: lesson, [field]: privateSentinel } }), 400, 'INVALID_REQUEST');
    assert.equal(h.calls.length, 0);
  });
}
check('trusted entitlement denial hides diagnostics and does not sign', async () => {
  const h = harness();
  await denied(h, incoming(), 403, 'ACCESS_DENIED');
  assert.equal(h.calls.length, 2);
  const rpc = h.calls[1].options;
  assert.deepEqual(JSON.parse(rpc.body), { p_actor: actor, p_session_id: session, p_aal: 'aal1', p_lesson: lesson, p_token_exp: claims.exp });
  assert.equal(rpc.redirect, 'error');
  assert.equal(h.calls[0].options.headers.Authorization, bearer());
});
check('RPC failure hides private diagnostics and does not sign', async () => {
  const h = harness({ rpcStatus: 500, rpcBody: { code: 'XX000', message: privateSentinel } });
  await denied(h, incoming(), 503, 'VIDEO_UNAVAILABLE');
});
for (const [name, overrides] of [
  ['wrong lesson', { lesson_id: session }], ['expired grant', { expires_at: now }],
  ['beyond session lifetime', { expires_at: 1_401 }], ['beyond maximum token lifetime', { expires_at: 1_301 }],
  ['unsafe provider identifier', { playback_id: '../' + privateSentinel }],
]) check('invalid trusted grant ' + name + ' cannot mint token', async () => {
  const h = harness({ rpcStatus: 200, rpcBody: { lesson_id: lesson, playback_id: 'SyntheticSignedPlayback', expires_at: 1_200, ...overrides } });
  await denied(h, incoming(), 503, 'VIDEO_UNAVAILABLE');
});
check('grant expires during Auth/RPC round trip before signing', async () => {
  let reads = 0;
  const h = harness({ clock: () => ++reads === 1 ? now : 1_200, rpcStatus: 200,
    rpcBody: { lesson_id: lesson, playback_id: 'SyntheticSignedPlayback', expires_at: 1_200 } });
  await denied(h, incoming(), 503, 'VIDEO_UNAVAILABLE');
});
