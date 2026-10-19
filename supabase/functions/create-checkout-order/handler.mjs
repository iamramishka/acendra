const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);

export function createHandler({ env, fetch: request = globalThis.fetch, onlineCheckoutEnabled = false }) {
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const allowed = new Set((env('ACENDRA_CHECKOUT_ALLOWED_ORIGINS') ?? 'http://127.0.0.1:8080').split(',').map(value => value.trim()).filter(Boolean));
    const requestId = crypto.randomUUID();
    const respond = (status, code, data) => new Response(JSON.stringify(code ? { error: { code }, meta: { contract_version: 'v1', request_id: requestId } } : { data, meta: { contract_version: 'v1', request_id: requestId } }), {
      status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', Vary: 'Origin', ...(origin && allowed.has(origin) ? { 'Access-Control-Allow-Origin': origin } : {}) },
    });
    if (origin !== null && !allowed.has(origin)) return respond(403, 'ORIGIN_FORBIDDEN');
    if (incoming.method === 'OPTIONS') {
      const headers = (incoming.headers.get('Access-Control-Request-Headers') ?? '').split(',').map(value => value.trim().toLowerCase()).filter(Boolean);
      if (!origin || incoming.headers.get('Access-Control-Request-Method') !== 'POST' || headers.some(value => !['authorization','content-type','apikey','x-client-info','idempotency-key'].includes(value))) return respond(403, 'PREFLIGHT_FORBIDDEN');
      return new Response(null, { status: 204, headers: { 'Access-Control-Allow-Origin': origin, Vary: 'Origin', 'Cache-Control': 'no-store', 'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info, Idempotency-Key' } });
    }
    if (incoming.method !== 'POST') return respond(405, 'METHOD_NOT_ALLOWED');
    const authorization = incoming.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ') || authorization.length > 16384) return respond(401, 'AUTH_REQUIRED');
    const key = incoming.headers.get('Idempotency-Key');
    if (!key || !/^[A-Za-z0-9._:-]{1,128}$/.test(key)) return respond(400, 'INVALID_IDEMPOTENCY_KEY');
    if (!incoming.headers.get('Content-Type')?.toLowerCase().startsWith('application/json')) return respond(400, 'INVALID_REQUEST');
    let body;
    try {
      // Read a bounded body before parsing, including requests without Content-Length.
      const reader = incoming.body?.getReader();
      if (!reader) return respond(400, 'INVALID_REQUEST');
      const chunks = []; let size = 0;
      while (true) {
        const { done, value } = await reader.read(); if (done) break;
        size += value.byteLength;
        if (size > 4096) { await reader.cancel(); return respond(413, 'INVALID_REQUEST'); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(size); let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
      body = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    } catch { return respond(400, 'INVALID_REQUEST'); }
    if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).some(name => !['course_id','payment_method'].includes(name)) || !uuid(body.course_id) || !['online','bank_transfer'].includes(body.payment_method)) return respond(400, 'INVALID_REQUEST');
    // Owner deferred provider acceptance. The deployed entry point does not opt in.
    if (body.payment_method === 'online' && onlineCheckoutEnabled !== true) return respond(503, 'ONLINE_CHECKOUT_UNAVAILABLE');
    const url = env('SUPABASE_URL'), publicKey = env('SUPABASE_ANON_KEY'), serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !publicKey || !serviceKey) return respond(503, 'SERVICE_UNAVAILABLE');
    try {
      const userResult = await request(`${url}/auth/v1/user`, { headers: { Authorization: authorization, apikey: publicKey }, signal: AbortSignal.timeout(15000) });
      if (!userResult.ok) return respond(401, 'AUTH_REQUIRED');
      const user = await userResult.json();
      // Decode only after Auth has verified the exact token; RPC rechecks the session.
      const parts = authorization.slice(7).split('.');
      if (parts.length !== 3) return respond(401, 'AUTH_REQUIRED');
      let claims;
      try {
        const payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        claims = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, '=')), value => value.charCodeAt(0))));
      } catch { return respond(401, 'AUTH_REQUIRED'); }
      if (!claims || typeof claims !== 'object' || Array.isArray(claims)) return respond(401, 'AUTH_REQUIRED');
      if (!uuid(user.id) || user.is_anonymous === true || claims.sub !== user.id || claims.role !== 'authenticated' || !uuid(claims.session_id) || !['aal1','aal2'].includes(claims.aal)) return respond(401, 'AUTH_REQUIRED');
      const bankVersion = body.payment_method === 'bank_transfer' ? env('ACENDRA_CHECKOUT_BANK_VERSION_ID') : null;
      if (body.payment_method === 'bank_transfer' && !uuid(bankVersion)) return respond(503, 'BANK_CHECKOUT_UNAVAILABLE');
      const mutation = await request(`${url}/rest/v1/rpc/csa265_create_checkout_order`, {
        method: 'POST', headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({ p_actor: user.id, p_session_id: claims.session_id, p_aal: claims.aal, p_key: key, p_course: body.course_id, p_method: body.payment_method, p_bank_version: bankVersion }), signal: AbortSignal.timeout(15000),
      });
      const result = await mutation.json();
      if (!mutation.ok) {
        const errors = { '42501': [403,'FORBIDDEN'], '22023': [409,'ORDER_CONFLICT'], 'P0002': [404,'COURSE_NOT_FOUND'], '23505': [409,'ALREADY_ENROLLED'], '55000': [503,'BANK_CHECKOUT_UNAVAILABLE'] };
        const [status, code] = errors[result.code] ?? [500,'ORDER_CREATION_FAILED']; return respond(status, code);
      }
      if (!result || typeof result.replayed !== 'boolean' || !uuid(result.data?.order_id)) return respond(503, 'SERVICE_UNAVAILABLE');
      return respond(result.replayed ? 200 : 201, undefined, result.data);
    } catch { return respond(503, 'SERVICE_UNAVAILABLE'); }
  };
}
