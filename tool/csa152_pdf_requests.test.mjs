import test from 'node:test';
import assert from 'node:assert/strict';
import * as handler from '../supabase/functions/pdf-content/handler.mjs';
import * as authorization from '../supabase/functions/_shared/pdf/authorization.mjs';

const modules = [handler, authorization];
const check = (name, body) => test(`CSA-152: ${name}`, body);
const actor = '11111111-1111-4111-8111-111111111111';
const session = '22222222-2222-4222-8222-222222222222';
const lesson = '33333333-3333-4333-8333-333333333333';
const resource = '44444444-4444-4444-8444-444444444444';
const other = '55555555-5555-4555-8555-555555555555';
const secret = 'NEVER_DISCLOSE_PRIVATE_SOURCE';
// Synthetic token, accepted/rejected only by the explicitly stubbed Auth boundary.
const token = (claims = {}) => 'Bearer x.' + Buffer.from(JSON.stringify({
  sub: actor, session_id: session, role: 'authenticated', aal: 'aal1', ...claims,
})).toString('base64url') + '.x';
const ready = { state: 'ready', lesson_id: lesson, resource_id: resource, bucket: 'course-pdfs',
  object_path: `derivatives/${actor}/v1/${resource}/${session}.pdf`, size_bytes: 10,
  checksum_sha256: 'a'.repeat(64) };
function harness({ authStatus = 200, user = { id: actor }, result = ready, rpcStatus = 200 } = {}) {
  const network = [], storage = [];
  const authorize = modules[1].createAuthorizer({
    env: name => ({ SUPABASE_URL: 'https://db.invalid', SUPABASE_ANON_KEY: 'synthetic-public',
      SUPABASE_SERVICE_ROLE_KEY: 'synthetic-service' })[name],
    fetch: async (url, options) => {
      network.push({ url, options });
      return url.endsWith('/user') ? Response.json(user, { status: authStatus }) :
        Response.json(result, { status: rpcStatus });
    },
  });
  const handler = modules[0].createHandler({ enabled: true, authorize, env: () => '',
    storage: { open: async input => {
      storage.push(input);
      const bytes = new TextEncoder().encode('0123456789').slice(input.start, input.end + 1);
      const full = bytes.length === 10;
      return new Response(bytes, { status: full ? 200 : 206, headers: {
        'Content-Type': 'application/pdf', 'Content-Length': String(bytes.length),
        ...(full ? {} : { 'Content-Range': `bytes ${input.start}-${input.end}/10` }),
      } });
    } },
  });
  return { handler, network, storage, setResolver(value, status) { result = value; rpcStatus = status; } };
}
function request({ authorization = token(), method = 'GET', range, query = '', descriptor = false,
  resourceId = resource, headers = {} } = {}) {
  return new Request(`https://api.invalid/pdf-content?lesson_id=${lesson}` +
    (descriptor ? '' : `&resource_id=${resourceId}`) + query, { method, headers: {
      ...(authorization === null ? {} : { Authorization: authorization }),
      ...(range ? { Range: range } : {}), ...headers,
    } });
}
async function denied(h, req, status) {
  const response = await h.handler(req);
  assert.equal(response.status, status);
  assert.equal(h.storage.length, 0);
  assert.equal(response.headers.get('location'), null);
  assert.equal(response.headers.get('content-range'), null);
  assert.equal(response.headers.get('content-length'), null);
  assert.equal(response.headers.get('cache-control'), 'private, no-store');
  assert.doesNotMatch(await response.text(), /NEVER_DISCLOSE|course-pdfs|derivatives\/|originals\/|signed_url|synthetic-service/);
}
for (const authorization of [null, '', 'Bearer broken', 'Basic user', 'Bearer a.b.c']) {
  check(`missing or malformed bearer ${JSON.stringify(authorization)} cannot read`, async () => {
    const h = harness(); await denied(h, request({ authorization }), 401);
    assert.equal(h.network.length, 0);
  });
}
for (const method of ['GET', 'HEAD']) for (const range of [undefined, 'bytes=0-1', 'bytes=99-', 'bytes=0-1,3-4']) {
  check(`Auth rejects forged/revoked token before ${method} range ${range}`, async () => {
    const h = harness({ authStatus: 401 });
    await denied(h, request({ method, range, headers: { 'If-None-Match': '*', 'If-Modified-Since': 'Mon, 12 Oct 2026 00:00:00 GMT' } }), 401);
    assert.equal(h.network.length, 1);
  });
}
for (const claims of [{ sub: other }, { session_id: null }, { role: 'service_role' }, { aal: 'aal3' }]) {
  check(`verified identity rejects mismatching claims ${JSON.stringify(claims)}`, async () => {
    const h = harness(); await denied(h, request({ authorization: token(claims) }), 401);
    assert.equal(h.network.length, 1);
  });
}
check('anonymous Auth user cannot request PDF', async () => {
  const h = harness({ user: { id: actor, is_anonymous: true } }); await denied(h, request(), 401);
  assert.equal(h.network.length, 1);
});
for (const query of [`&course_id=${other}`, `&user_id=${other}`, '&object_path=originals/secret.pdf',
  '&signed_url=https://evil.invalid', `&lesson_id=${other}`, `&resource_id=${other}`]) {
  check(`client cannot substitute ownership or path using ${query}`, async () => {
    const h = harness(); await denied(h, request({ query }), 400); assert.equal(h.network.length, 0);
  });
}
for (const result of [{ ...ready, lesson_id: other }, { ...ready, resource_id: other },
  { ...ready, bucket: 'originals' }, { ...ready, object_path: `originals/${secret}.pdf` }]) {
  check(`unbound or original resolver result denied: ${JSON.stringify(result)}`, async () => {
    const h = harness({ result }); await denied(h, request(), 503); assert.equal(h.network.length, 2);
  });
}
for (const method of ['GET', 'HEAD']) {
  check(`trusted SQL denial remains closed for ${method}, including invalid range`, async () => {
    const h = harness({ rpcStatus: 403, result: { message: 'ACCESS_DENIED', details: secret } });
    await denied(h, request({ method, range: 'bytes=99-' }), 403); assert.equal(h.network.length, 2);
  });
}
check('preparing descriptor never opens original and strips private fields', async () => {
  const h = harness({ result: { state: 'preparing', lesson_id: lesson, resource_id: null, object_path: secret } });
  const response = await h.handler(request({ descriptor: true }));
  assert.equal(response.status, 202); assert.equal(h.storage.length, 0);
  assert.deepEqual(await response.json(), { data: { lesson_id: lesson, mode: 'proxied_stream', state: 'preparing', resource_id: null } });
});
check('preparing response to byte request fails closed without original fallback', async () => {
  const h = harness({ result: { state: 'preparing', lesson_id: lesson, resource_id: null, object_path: secret } });
  await denied(h, request(), 503);
});
check('success control binds Auth identity and requested resource to trusted resolver', async () => {
  const h = harness(); const response = await h.handler(request({ range: 'bytes=2-4' }));
  assert.equal(response.status, 206); assert.equal(await response.text(), '234');
  assert.deepEqual(JSON.parse(h.network[1].options.body), {
    p_actor: actor, p_session_id: session, p_aal: 'aal1', p_lesson: lesson, p_resource: resource,
  });
  assert.equal(h.storage.length, 1); assert.equal(h.storage[0].object_path, ready.object_path);
});
check('each subsequent range rechecks current authorization after an earlier success', async () => {
  const h = harness(); assert.equal((await h.handler(request({ method: 'HEAD' }))).status, 200);
  h.setResolver({ message: 'ACCESS_DENIED', details: secret }, 403);
  await denied(h, request({ range: 'bytes=0-1' }), 403);
  assert.equal(h.network.length, 4);
});
