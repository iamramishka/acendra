const uuid = x => typeof x === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(x);
const exact = (x, keys) => x && typeof x === 'object' && !Array.isArray(x) && Object.keys(x).every(k => keys.includes(k)) && keys.every(k => Object.hasOwn(x, k));
const text = (x, max, required = false) => typeof x === 'string' && [...x].length <= max && (!required || /\S/u.test(x));
const position = x => Number.isInteger(x) && x >= 0 && x <= 1000000;
const ids = x => Array.isArray(x) && x.length <= 1000 && x.every(uuid) && new Set(x.map(v => v.toLowerCase())).size === x.length;
const timestamp = x => typeof x === 'string' && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/.test(x) && Number.isFinite(Date.parse(x));
const reads = new Set(['get', 'curriculum']);
function validPayload(action, p) {
  switch (action) {
    case 'get': case 'curriculum': case 'archive': return exact(p, []);
    case 'create': case 'update':
      return exact(p, ['title', 'slug', 'category_id', 'short_description', 'description', 'price_minor', 'currency_code']) &&
        text(p.title, 200, true) && typeof p.slug === 'string' && p.slug.length <= 200 && /^[a-z0-9]+(-[a-z0-9]+)*$/.test(p.slug) &&
        (p.category_id === null || uuid(p.category_id)) && text(p.short_description, 2000) && text(p.description, 40000) &&
        typeof p.price_minor === 'string' && /^(0|[1-9][0-9]{0,18})$/.test(p.price_minor) && BigInt(p.price_minor) <= 9223372036854775807n && p.currency_code === 'LKR';
    case 'upsert_section': return exact(p, ['id', 'title', 'position', 'is_published']) && uuid(p.id) && text(p.title, 200, true) && position(p.position) && typeof p.is_published === 'boolean';
    case 'delete_section': case 'delete_lesson': return exact(p, ['id']) && uuid(p.id);
    case 'upsert_lesson': return exact(p, ['id', 'section_id', 'title', 'description', 'lesson_type', 'position', 'is_preview', 'is_published', 'duration_seconds']) &&
      uuid(p.id) && uuid(p.section_id) && text(p.title, 200, true) && text(p.description, 2000) && ['video', 'pdf', 'text', 'image'].includes(p.lesson_type) &&
      position(p.position) && typeof p.is_preview === 'boolean' && typeof p.is_published === 'boolean' &&
      (p.duration_seconds === null || (Number.isInteger(p.duration_seconds) && p.duration_seconds >= 0 && p.duration_seconds <= 2147483647));
    case 'reorder_sections': return exact(p, ['ids']) && ids(p.ids);
    case 'reorder_lessons': return exact(p, ['section_id', 'ids']) && uuid(p.section_id) && ids(p.ids);
    default: return false;
  }
}
async function readJson(stream, limit) {
  const reader = stream?.getReader(); if (!reader) throw Error('INVALID');
  let size = 0; const parts = [];
  try { for (;;) { const { value, done } = await reader.read(); if (done) break; size += value.length; if (size > limit) { await reader.cancel(); throw Error('LARGE'); } parts.push(value); } } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size); let at = 0;
  for (const part of parts) { bytes.set(part, at); at += part.length; }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
}
export function createHandler({ env, fetch: request = globalThis.fetch, enabled = false }) {
  const origins = new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS') ?? '').split(',').map(x => x.trim()).filter(Boolean));
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const reply = (status, code, data) => Response.json(code ? { error: { code } } : { data }, { status, headers: {
      'Cache-Control': 'no-store', Vary: 'Origin', ...(origin && origins.has(origin) ? { 'Access-Control-Allow-Origin': origin } : {}),
    } });
    if (enabled !== true) return reply(503, 'COURSE_MANAGEMENT_UNAVAILABLE');
    if (origin !== null && !origins.has(origin)) return reply(403, 'ORIGIN_FORBIDDEN');
    if (incoming.method === 'OPTIONS') {
      const headers = (incoming.headers.get('Access-Control-Request-Headers') ?? '').split(',').map(x => x.trim().toLowerCase()).filter(Boolean);
      if (!origin || incoming.headers.get('Access-Control-Request-Method') !== 'POST' || headers.some(x => !['authorization', 'content-type', 'apikey', 'x-client-info'].includes(x))) return reply(403, 'PREFLIGHT_FORBIDDEN');
      return new Response(null, { status: 204, headers: { 'Cache-Control': 'no-store', Vary: 'Origin', 'Access-Control-Allow-Origin': origin, 'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info' } });
    }
    if (incoming.method !== 'POST') return reply(405, 'METHOD_NOT_ALLOWED');
    const authorization = incoming.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ') || authorization.length > 16384) return reply(401, 'AUTH_REQUIRED');
    if (!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type') ?? '')) return reply(415, 'UNSUPPORTED_MEDIA_TYPE');
    let body;
    try { body = await readJson(incoming.body, 65536); } catch (e) { return reply(e.message === 'LARGE' ? 413 : 400, 'INVALID_REQUEST'); }
    if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).some(k => !['action', 'course_id', 'expected_updated_at', 'request_id', 'payload'].includes(k)) ||
      !uuid(body.course_id) || !validPayload(body.action, body.payload ?? {}) ||
      (!reads.has(body.action) && (!uuid(body.request_id) || (body.action !== 'create' && !timestamp(body.expected_updated_at)))) ||
      (reads.has(body.action) && (body.request_id != null || body.expected_updated_at != null))) return reply(400, 'INVALID_REQUEST');
    const url = env('SUPABASE_URL'), publicKey = env('SUPABASE_ANON_KEY'), serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !publicKey || !serviceKey) return reply(503, 'SERVICE_UNAVAILABLE');
    const signal = AbortSignal.timeout(15000);
    try {
      const auth = await request(`${url}/auth/v1/user`, { headers: { Authorization: authorization, apikey: publicKey }, redirect: 'error', signal });
      if (!auth.ok) return reply(401, 'AUTH_REQUIRED');
      const user = await readJson(auth.body, 32768), parts = authorization.slice(7).split('.');
      if (parts.length !== 3) return reply(401, 'AUTH_REQUIRED');
      let claims;
      try { const b64 = parts[1].replaceAll('-', '+').replaceAll('_', '/'); claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(Uint8Array.from(atob(b64.padEnd(Math.ceil(b64.length / 4) * 4, '=')), c => c.charCodeAt(0)))); } catch { return reply(401, 'AUTH_REQUIRED'); }
      if (!uuid(user.id) || user.is_anonymous === true || claims?.sub !== user.id || claims?.role !== 'authenticated' || !uuid(claims?.session_id) || !['aal1', 'aal2'].includes(claims.aal)) return reply(401, 'AUTH_REQUIRED');
      const args = { p_actor: user.id, p_session_id: claims.session_id, p_aal: claims.aal, p_course: body.course_id.toLowerCase(), p_expected: body.expected_updated_at ?? null, p_request_id: body.request_id ?? null };
      const rpcName = body.action === 'archive' ? 'csa268_archive_course' : 'csa268_manage_course';
      if (body.action !== 'archive') Object.assign(args, { p_action: body.action, p_payload: body.payload ?? {} });
      const rpc = await request(`${url}/rest/v1/rpc/${rpcName}`, { method: 'POST', headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey, 'Content-Type': 'application/json' }, redirect: 'error', signal,
        body: JSON.stringify(args),
      });
      // 1,000 bounded lesson descriptions may contain four-byte Unicode text.
      const result = await readJson(rpc.body, 16 * 1024 * 1024);
      if (!rpc.ok) {
        const errors = { '42501': [403, 'ADMIN_PERMISSION_REQUIRED'], '40001': [409, 'COURSE_CONFLICT'], '23505': [409, 'COURSE_CONFLICT'], '23503': [409, 'CONTENT_IN_USE'], '23514': [409, 'COURSE_NOT_READY'], '55000': [409, 'UNPUBLISH_FIRST'], '22023': [400, 'INVALID_REQUEST'], 'P0002': [404, 'COURSE_NOT_FOUND'] };
        const [status, code] = errors[result?.code] ?? [503, 'SERVICE_UNAVAILABLE']; return reply(status, code);
      }
      if (!result || typeof result !== 'object' || Array.isArray(result) ||
        (reads.has(body.action) ? (body.action === 'get' ? result.course?.id !== body.course_id.toLowerCase() || !Array.isArray(result.categories) : !Array.isArray(result.sections) || !timestamp(result.updated_at)) : result.course_id !== body.course_id.toLowerCase() || !timestamp(result.updated_at))) return reply(503, 'SERVICE_UNAVAILABLE');
      return reply(200, null, result);
    } catch { return reply(503, 'SERVICE_UNAVAILABLE'); }
  };
}
