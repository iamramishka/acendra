import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHandler } from './handler.mjs';
import { reportingEnabled } from '../_shared/reporting-activation.mjs';

const actor = '10000000-0000-4000-8000-000000000001';
const session = '10000000-0000-4000-8000-000000000002';
const course = '10000000-0000-4000-8000-000000000003';
const row = '10000000-0000-4000-8000-000000000004';
const key = '10000000-0000-4000-8000-000000000005';
const stamp = '2026-10-20T01:02:03.123456Z';
const origin = 'https://courses.synthetic.test';
const env = name => ({ SUPABASE_URL: 'https://backend.synthetic.test', SUPABASE_ANON_KEY: 'public-test', SUPABASE_SERVICE_ROLE_KEY: 'private-test', ACENDRA_ADMIN_ALLOWED_ORIGINS: origin })[name];
const token = claims => `x.${Buffer.from(JSON.stringify({ sub: actor, session_id: session, role: 'authenticated', aal: 'aal2', ...claims })).toString('base64url')}.x`;
const req = (body = { action: 'get', course_id: course }, options = {}) => new Request('https://edge.synthetic.test', {
  method: 'POST', headers: { Origin: origin, Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json', ...options.headers },
  body: JSON.stringify(body), ...Object.fromEntries(Object.entries(options).filter(([k]) => k !== 'headers')),
});
const metadata = { title: 'Real course', slug: 'real-course', category_id: null, short_description: 'Summary', description: 'Details', price_minor: '12345', currency_code: 'LKR' };
const command = (action, payload = {}) => ({ action, course_id: course, request_id: key, expected_updated_at: stamp, payload });
function backend({ rpcStatus = 200, rpcResult = { course_id: course, updated_at: stamp }, claims, user = { id: actor }, authStatus = 200 } = {}) {
  const calls = [];
  return { calls, handler: createHandler({ env, enabled: true, fetch: async (url, opts) => {
    calls.push({ url, opts });
    if (url.endsWith('/auth/v1/user')) return Response.json(user, { status: authStatus });
    return Response.json(rpcResult, { status: rpcStatus });
  } }), claims };
}

test('default denies operations before Auth or database access', async () => {
  const h = createHandler({ env, fetch: () => { throw Error('must not call'); } });
  const r = await h(req(command('update', metadata)));
  assert.equal(r.status, 503);
  assert.equal((await r.json()).error.code, 'COURSE_MANAGEMENT_UNAVAILABLE');
});
test('verified actor/session and raw microsecond revision reach service-only RPC', async () => {
  const b = backend();
  const r = await b.handler(req(command('update', metadata)));
  assert.equal(r.status, 200);
  assert.equal(b.calls.length, 2);
  assert.ok(b.calls[1].url.endsWith('/rpc/csa268_manage_course'));
  assert.deepEqual(JSON.parse(b.calls[1].opts.body), { p_actor: actor, p_session_id: session, p_aal: 'aal2', p_action: 'update', p_course: course, p_expected: stamp, p_request_id: key, p_payload: metadata });
  assert.equal(b.calls[1].opts.headers.Authorization, 'Bearer private-test');
  assert.equal(r.headers.get('Cache-Control'), 'no-store');
  assert.equal(r.headers.get('Access-Control-Allow-Origin'), origin);
});
test('archive uses the reviewed retention RPC with current actor and original revision', async () => {
  const b = backend();
  const r = await b.handler(req(command('archive')));
  assert.equal(r.status, 200);
  assert.ok(b.calls[1].url.endsWith('/rpc/csa268_archive_course'));
  assert.deepEqual(JSON.parse(b.calls[1].opts.body), {
    p_actor: actor, p_session_id: session, p_aal: 'aal2', p_course: course,
    p_expected: stamp, p_request_id: key,
  });
});
test('archive rejects supplied retention overrides before privileged access', async () => {
  const b = backend();
  assert.equal((await b.handler(req(command('archive', { delete_history: true })))).status, 400);
  assert.equal(b.calls.length, 0);
});
for (const action of ['get', 'curriculum']) test(`${action} is a bounded authorized read`, async () => {
  const b = backend({ rpcResult: action === 'get' ? { course: { id: course }, categories: [] } : { sections: [], updated_at: stamp } });
  assert.equal((await b.handler(req({ action, course_id: course }))).status, 200);
  const args = JSON.parse(b.calls[1].opts.body);
  assert.equal(args.p_request_id, null);
  assert.equal(args.p_expected, null);
});
const commands = [
  ['create', metadata],
  ['upsert_section', { id: row, title: 'Section', position: 0, is_published: false }],
  ['delete_section', { id: row }],
  ['upsert_lesson', { id: row, section_id: row, title: 'Lesson', description: '', lesson_type: 'image', position: 0, is_preview: false, is_published: false, duration_seconds: null }],
  ['delete_lesson', { id: row }],
  ['reorder_sections', { ids: [row] }],
  ['reorder_lessons', { section_id: row, ids: [row] }],
];
for (const [action, payload] of commands) test(`${action} forwards only the reviewed command contract`, async () => {
  const b = backend();
  const body = command(action, payload);
  if (action === 'create') delete body.expected_updated_at;
  assert.equal((await b.handler(req(body))).status, 200);
  assert.equal(JSON.parse(b.calls[1].opts.body).p_action, action);
});
const invalid = [
  { ...command('update', metadata), actor },
  { ...command('update', metadata), course_id: 'course-123' },
  { ...command('update', metadata), request_id: null },
  { ...command('update', metadata), expected_updated_at: undefined },
  { ...command('update', metadata), expected_updated_at: 'yesterday' },
  command('update', { ...metadata, status: 'published' }),
  command('update', { ...metadata, price_minor: '1.23' }),
  command('update', { ...metadata, price_minor: '-1' }),
  command('update', { ...metadata, price_minor: '9223372036854775808' }),
  command('update', { ...metadata, currency_code: 'USD' }),
  command('update', { ...metadata, title: ' ' }),
  command('update', { ...metadata, title: 'x'.repeat(201) }),
  command('update', { ...metadata, slug: '../private' }),
  command('update', { ...metadata, description: 'x'.repeat(40001) }),
  command('upsert_section', { id: row, title: 'Section', position: -1, is_published: false }),
  command('upsert_section', { id: row, title: 'Section', position: 0.1, is_published: false }),
  command('delete_lesson', { id: row, course_id: actor }),
  command('reorder_sections', { ids: [row, row] }),
  command('reorder_lessons', { section_id: row, ids: ['not-uuid'] }),
  command('upsert_lesson', { id: row, section_id: row, title: 'Lesson', description: '', lesson_type: 'quiz', position: 0, is_preview: false, is_published: false, duration_seconds: null }),
  command('publish', {}),
];
for (const [i, body] of invalid.entries()) test(`invalid command ${i + 1} fails before privileged access`, async () => {
  const b = backend();
  assert.equal((await b.handler(req(body))).status, 400);
  assert.equal(b.calls.length, 0);
});
for (const [claims, status] of [[{ sub: course }, 401], [{ session_id: 'bad' }, 401], [{ role: 'service_role' }, 401], [{ aal: 'bad' }, 401]]) test(`unverified claims rejected: ${JSON.stringify(claims)}`, async () => {
  const b = backend();
  assert.equal((await b.handler(req(undefined, { headers: { Authorization: `Bearer ${token(claims)}` } }))).status, status);
  assert.equal(b.calls.length, 1);
});
test('Auth rejection prevents privileged request', async () => {
  const b = backend({ authStatus: 401 });
  assert.equal((await b.handler(req())).status, 401);
  assert.equal(b.calls.length, 1);
});
test('foreign and empty origins rejected before Auth', async () => {
  const b = backend();
  for (const value of ['https://foreign.test', '']) assert.equal((await b.handler(req(undefined, { headers: { Origin: value } }))).status, 403);
  assert.equal(b.calls.length, 0);
});
test('valid preflight supports only expected headers', async () => {
  const b = backend();
  const r = await b.handler(new Request('https://edge.test', { method: 'OPTIONS', headers: { Origin: origin, 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'authorization,content-type,apikey,x-client-info' } }));
  assert.equal(r.status, 204);
  assert.equal(b.calls.length, 0);
});
for (const [sqlcode, status, code] of [['42501', 403, 'ADMIN_PERMISSION_REQUIRED'], ['40001', 409, 'COURSE_CONFLICT'], ['23503', 409, 'CONTENT_IN_USE'], ['23505', 409, 'COURSE_CONFLICT'], ['55000', 409, 'UNPUBLISH_FIRST'], ['22023', 400, 'INVALID_REQUEST'], ['P0002', 404, 'COURSE_NOT_FOUND'], ['XX000', 503, 'SERVICE_UNAVAILABLE']]) test(`safe error ${sqlcode}`, async () => {
  const b = backend({ rpcStatus: 400, rpcResult: { code: sqlcode, message: 'PRIVATE DATA' } });
  const r = await b.handler(req(command('update', metadata)));
  assert.equal(r.status, status);
  const text = await r.text();
  assert.ok(!text.includes('PRIVATE'));
  assert.equal(JSON.parse(text).error.code, code);
});
test('oversized request is bounded', async () => {
  const b = backend();
  const r = await b.handler(req({ action: 'get', course_id: course, padding: 'x'.repeat(70000) }));
  assert.equal(r.status, 413);
  assert.equal(b.calls.length, 0);
});

test('release switches require explicit opt-in and valid exact origins', async () => {
  for (const flag of ['ACENDRA_COURSE_MANAGEMENT_ENABLED', 'ACENDRA_COURSE_PUBLICATION_ENABLED']) {
    for (const [value, origins, expected] of [[undefined, origin, false], ['false', origin, false], ['TRUE', origin, false], ['true', '', false], ['true', '*', false], ['true', `${origin}/path`, false], ['true', origin, true]]) {
      assert.equal(reportingEnabled(name => name === flag ? value : name === 'ACENDRA_ADMIN_ALLOWED_ORIGINS' ? origins : undefined, flag), expected);
    }
  }
  const own = await readFile(new URL('./index.ts', import.meta.url), 'utf8');
  const publish = await readFile(new URL('../admin-publish-course/index.ts', import.meta.url), 'utf8');
  assert.match(own, /serverReleaseEnabled\(env, 'ACENDRA_COURSE_MANAGEMENT_ENABLED'\)/);
  assert.match(publish, /serverReleaseEnabled\(env, 'ACENDRA_COURSE_PUBLICATION_ENABLED'\)/);
});
test('Auth and RPC share one deadline', async () => {
  const b = backend();
  assert.equal((await b.handler(req(command('update', metadata)))).status, 200);
  assert.equal(b.calls[0].opts.signal, b.calls[1].opts.signal);
  assert.equal(b.calls[0].opts.redirect, 'error');
  assert.equal(b.calls[1].opts.redirect, 'error');
});
test('malformed successful RPC response fails closed', async () => {
  for (const rpcResult of [null, [], { course_id: actor, updated_at: stamp }, { course_id: course, updated_at: 'invalid' }]) {
    const b = backend({ rpcResult });
    assert.equal((await b.handler(req(command('update', metadata)))).status, 503);
  }
});
