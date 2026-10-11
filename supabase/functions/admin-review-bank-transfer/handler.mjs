const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
const text = (value, limit) => typeof value === 'string' && value.trim().length > 0 && value.length <= limit && !/[\x00-\x1f\x7f]/.test(value);
const exactKeys = (value, names) => value && typeof value === 'object' && !Array.isArray(value) && Object.keys(value).length === names.length && names.every(name => Object.hasOwn(value, name));
const creditKeys = ['bank_credit_confirmed', 'destination_account_id', 'bank_transaction_id', 'amount_minor', 'currency', 'settled_at', 'source', 'order_reference'];
const validCredit = value => {
  if (!exactKeys(value, creditKeys) || value.bank_credit_confirmed !== true || !uuid(value.destination_account_id) ||
      !text(value.bank_transaction_id, 200) || !text(value.order_reference, 100) || value.currency !== 'LKR' ||
      !['bank_portal', 'bank_statement', 'authenticated_bank_feed'].includes(value.source) ||
      typeof value.amount_minor !== 'string' || !/^[1-9][0-9]{0,18}$/.test(value.amount_minor) ||
      BigInt(value.amount_minor) > 9223372036854775807n || typeof value.settled_at !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/.test(value.settled_at)) return false;
  const [year, month, day, hour, minute, second] = value.settled_at.slice(0, 19).split(/[-T:]/).map(Number);
  if (month < 1 || month > 12 || day < 1 || day > new Date(Date.UTC(year, month, 0)).getUTCDate() ||
      hour > 23 || minute > 59 || second > 59) return false;
  const settled = Date.parse(value.settled_at);
  return Number.isFinite(settled) && settled <= Date.now();
};

async function boundedJson(body, limit) {
  const reader = body?.getReader();
  if (!reader) throw new Error('INVALID_REQUEST');
  const chunks = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > limit) { await reader.cancel(); throw new Error('BODY_TOO_LARGE'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
}

export function createHandler({ env, fetch: request = globalThis.fetch, bankReviewEnabled = false }) {
  // Snapshot trusted service/origin configuration before asynchronous request reads.
  const config = Object.freeze({
    url: env('SUPABASE_URL'), publicKey: env('SUPABASE_ANON_KEY'), serviceKey: env('SUPABASE_SERVICE_ROLE_KEY'),
    allowedOrigins: env('ACENDRA_ADMIN_ALLOWED_ORIGINS') ?? 'http://127.0.0.1:8080',
  });
  const allowed = new Set(config.allowedOrigins.split(',').map(value => value.trim()).filter(Boolean));
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const requestId = crypto.randomUUID();
    const respond = (status, code, data, replayed) => new Response(JSON.stringify({
      ...(code ? { error: { code } } : { data }),
      meta: { contract_version: 'bank-review-v1-proposal', request_id: requestId, ...(typeof replayed === 'boolean' ? { replayed } : {}) },
    }), { status, headers: {
      'Content-Type': 'application/json', 'Cache-Control': 'no-store', Vary: 'Origin',
      ...(origin && allowed.has(origin) ? { 'Access-Control-Allow-Origin': origin } : {}),
    } });
    // No environment setting enables release. Only explicit synthetic test injection.
    if (bankReviewEnabled !== true) return respond(503, 'BANK_REVIEW_UNAVAILABLE');
    if (origin !== null && !allowed.has(origin)) return respond(403, 'ORIGIN_FORBIDDEN');
    if (incoming.method === 'OPTIONS') {
      const headers = (incoming.headers.get('Access-Control-Request-Headers') ?? '').split(',').map(value => value.trim().toLowerCase()).filter(Boolean);
      if (!origin || incoming.headers.get('Access-Control-Request-Method') !== 'POST' ||
          headers.some(value => !['authorization', 'content-type', 'apikey', 'x-client-info', 'idempotency-key'].includes(value))) {
        return respond(403, 'PREFLIGHT_FORBIDDEN');
      }
      return new Response(null, { status: 204, headers: {
        'Access-Control-Allow-Origin': origin, Vary: 'Origin', 'Cache-Control': 'no-store',
        'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info, Idempotency-Key',
      } });
    }
    if (incoming.method !== 'POST') return respond(405, 'METHOD_NOT_ALLOWED');
    const authorization = incoming.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ') || authorization.length > 16384) return respond(401, 'AUTH_REQUIRED');
    const key = incoming.headers.get('Idempotency-Key');
    if (!key || !/^[A-Za-z0-9._:-]{1,128}$/.test(key)) return respond(400, 'INVALID_IDEMPOTENCY_KEY');
    if (!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type') ?? '')) return respond(415, 'UNSUPPORTED_MEDIA_TYPE');
    let body;
    try { body = await boundedJson(incoming.body, 8192); }
    catch (error) { return respond(error.message === 'BODY_TOO_LARGE' ? 413 : 400, 'INVALID_REQUEST'); }
    const names = body?.decision === 'approve' ? ['submission_id', 'decision', 'verified_credit'] : ['submission_id', 'decision', 'rejection_reason'];
    if (body && Object.hasOwn(body, 'private_notes')) names.push('private_notes');
    if (!exactKeys(body, names) || !uuid(body.submission_id) || !['approve', 'reject'].includes(body.decision) ||
        (Object.hasOwn(body, 'private_notes') && !text(body.private_notes, 2000)) ||
        (body.decision === 'approve' ? !validCredit(body.verified_credit) : !text(body.rejection_reason, 1000))) {
      return respond(400, 'INVALID_REQUEST');
    }
    if (!config.url || !config.publicKey || !config.serviceKey) return respond(503, 'SERVICE_UNAVAILABLE');
    try {
      const userResult = await request(`${config.url}/auth/v1/user`, {
        headers: { Authorization: authorization, apikey: config.publicKey }, signal: AbortSignal.timeout(15000), redirect: 'error',
      });
      if (!userResult.ok) return respond(401, 'AUTH_REQUIRED');
      const user = await boundedJson(userResult.body, 32768);
      const parts = authorization.slice(7).split('.');
      if (parts.length !== 3) return respond(401, 'AUTH_REQUIRED');
      let claims;
      try {
        // Decode only after Auth verifies this exact bearer token.
        const payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        const bytes = Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, '=')), value => value.charCodeAt(0));
        claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
      } catch { return respond(401, 'AUTH_REQUIRED'); }
      if (!claims || typeof claims !== 'object' || Array.isArray(claims) || !uuid(user.id) || user.is_anonymous === true ||
          claims.sub !== user.id || claims.role !== 'authenticated' || !uuid(claims.session_id)) return respond(401, 'AUTH_REQUIRED');
      if (claims.aal !== 'aal2') return respond(403, 'MFA_REQUIRED');
      // SQL rechecks live account/session/roles, independence, evidence and state
      // under locks. Token metadata never supplies finance privileges.
      const mutation = await request(`${config.url}/rest/v1/rpc/csa112_review_bank_transfer`, {
        method: 'POST', headers: { Authorization: `Bearer ${config.serviceKey}`, apikey: config.serviceKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          p_actor: user.id, p_session_id: claims.session_id, p_aal: claims.aal, p_key: key,
          p_submission: body.submission_id, p_decision: body.decision,
          p_verified_credit: body.decision === 'approve' ? body.verified_credit : null,
          p_public_reason: body.decision === 'reject' ? body.rejection_reason : null,
          p_private_notes: body.private_notes ?? null,
        }), signal: AbortSignal.timeout(15000), redirect: 'error',
      });
      const result = await boundedJson(mutation.body, 16384);
      if (!mutation.ok) {
        const errors = {
          '42501': [403, 'ADMIN_PERMISSION_REQUIRED'], '22023': [409, 'BANK_REVIEW_CONFLICT'],
          '23505': [409, 'BANK_REVIEW_CONFLICT'], '55000': [409, 'BANK_SUBMISSION_ALREADY_FINALIZED'],
          P0002: [404, 'BANK_SUBMISSION_NOT_FOUND'],
        };
        const [status, code] = errors[result?.code] ?? [503, 'SERVICE_UNAVAILABLE'];
        return respond(status, code);
      }
      const expected = body.decision === 'approve' ? ['approved', 'paid'] : ['rejected', 'pending_payment'];
      if (!result || typeof result.replayed !== 'boolean' || result.submission_id !== body.submission_id ||
          !uuid(result.order_id) || result.status !== expected[0] || result.order_status !== expected[1]) {
        return respond(503, 'SERVICE_UNAVAILABLE');
      }
      // Only safe allowlisted status fields leave the privileged boundary.
      return respond(200, undefined, {
        submission_id: result.submission_id, submission_status: result.status, order_status: result.order_status,
      }, result.replayed);
    } catch { return respond(503, 'SERVICE_UNAVAILABLE'); }
  };
}
