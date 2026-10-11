
const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
const fields = new Set(['title','slug','category_id','short_description','description','request_id']);

export function createHandler({ env, fetch: request = globalThis.fetch }) {
  function response(status, error, data, requestId, origin) {
    return new Response(JSON.stringify(error ? { error: { code: error }, request_id: requestId } : { data, request_id: requestId }), {
      status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', Vary: 'Origin',
        ...(origin ? { 'Access-Control-Allow-Origin': origin } : {}),
      },
    });
  }
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const allowedOrigins = new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS') ?? 'http://127.0.0.1:8080')
      .split(',').map(value => value.trim()).filter(Boolean));
    if (origin !== null && !allowedOrigins.has(origin)) return response(403, 'ORIGIN_FORBIDDEN');
    const respond = (status, error, data, requestId) => response(status, error, data, requestId, origin);
    if (incoming.method === 'OPTIONS') {
      if (!origin) return respond(403, 'ORIGIN_FORBIDDEN');
      if (incoming.headers.get('Access-Control-Request-Method') !== 'POST') return respond(405, 'METHOD_NOT_ALLOWED');
      const requestedHeaders = (incoming.headers.get('Access-Control-Request-Headers') ?? '')
        .split(',').map(value => value.trim().toLowerCase()).filter(Boolean);
      if (requestedHeaders.some(value => !['authorization', 'content-type', 'apikey', 'x-client-info'].includes(value))) {
        return respond(403, 'HEADERS_FORBIDDEN');
      }
      return new Response(null, { status: 204, headers: {
        'Access-Control-Allow-Origin': origin, Vary: 'Origin', 'Cache-Control': 'no-store',
        'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info',
      } });
    }
    if (incoming.method !== 'POST') return respond(405, 'METHOD_NOT_ALLOWED');
    const authorization = incoming.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ') || authorization.length > 16384) return respond(401, 'UNAUTHENTICATED');
    let body;
    try { body = await incoming.json(); } catch { return respond(400, 'INVALID_REQUEST'); }
    if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).some(key => !fields.has(key))
      || !uuid(body.request_id) || typeof body.title !== 'string' || !/\S/u.test(body.title)
      || [...body.title].length > 200 || typeof body.slug !== 'string' || body.slug.length > 200
      || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(body.slug)
      || (body.category_id != null && !uuid(body.category_id))
      || ['short_description','description'].some(key => body[key] != null && typeof body[key] !== 'string')
      || new TextEncoder().encode(JSON.stringify(body)).length > 65536) return respond(400, 'INVALID_REQUEST');
    const requestId = body.request_id;
    const url = env('SUPABASE_URL');
    const publicKey = env('SUPABASE_ANON_KEY');
    const serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !publicKey || !serviceKey) return respond(503, 'SERVICE_UNAVAILABLE', undefined, requestId);
    try {
      // Auth validates this exact token's signature/session; never trust decoded
      // claims before this call succeeds. Actor is the returned verified user.
      const userResult = await request(`${url}/auth/v1/user`, {
        headers: { Authorization: authorization, apikey: publicKey }, signal: AbortSignal.timeout(15000),
      });
      if (!userResult.ok) return respond(401, 'UNAUTHENTICATED', undefined, requestId);
      const user = await userResult.json();
      const token = authorization.slice(7);
      const parts = token.split('.');
      if (parts.length !== 3) return respond(401, 'UNAUTHENTICATED', undefined, requestId);
      let claims;
      try {
        const payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        claims = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, '=')), c => c.charCodeAt(0))));
      } catch { return respond(401, 'UNAUTHENTICATED', undefined, requestId); }
      if (!uuid(user.id) || !uuid(claims.session_id) || claims.sub !== user.id || claims.role !== 'authenticated' || user.is_anonymous === true) {
        return respond(401, 'UNAUTHENTICATED', undefined, requestId);
      }
      if (!['aal1','aal2'].includes(claims.aal)) return respond(401, 'UNAUTHENTICATED', undefined, requestId);
      const mutation = await request(`${url}/rest/v1/rpc/csa089_create_course`, {
        method: 'POST', headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({ p_actor: user.id,p_session_id: claims.session_id,p_aal: claims.aal,p_request_id: requestId,
          p_payload: Object.fromEntries(Object.entries(body).filter(([key]) => key !== 'request_id')) }),
        signal: AbortSignal.timeout(15000),
      });
      const result = await mutation.json();
      if (!mutation.ok) {
        const errors = { '42501': [403,'FORBIDDEN'], '22023': [409,'INVALID_OPERATION'], '23503': [404,'CATEGORY_NOT_FOUND'], '23505': [409,'COURSE_CONFLICT'] };
        const [status, code] = errors[result.code] || [500, 'OPERATION_FAILED'];
        return respond(status, code, undefined, requestId);
      }
      return respond(200, undefined, result, requestId);
    } catch { return respond(503, 'SERVICE_UNAVAILABLE', undefined, requestId); }
  };
}
