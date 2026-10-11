import { boundedBytes, digest, receiptType, snapshotInspector, inspectReceipt, ReceiptError } from './validation.mjs';

const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
export function createHandler({ env, fetch: request = globalThis.fetch, receiptUploadsEnabled = false, inspector }) {
  const inspection = snapshotInspector(inspector);
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const allowed = new Set((env('ACENDRA_CHECKOUT_ALLOWED_ORIGINS') ?? 'http://127.0.0.1:8080').split(',').map(value => value.trim()).filter(Boolean));
    const requestId = crypto.randomUUID();
    const respond = (status, code, data) => new Response(JSON.stringify({
      ...(code ? { error: { code } } : { data }), meta: { contract_version: 'v1', request_id: requestId },
    }), { status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', Vary: 'Origin',
      ...(origin && allowed.has(origin) ? { 'Access-Control-Allow-Origin': origin } : {}) } });
    if (origin !== null && !allowed.has(origin)) return respond(403, 'ORIGIN_FORBIDDEN');
    if (incoming.method === 'OPTIONS') {
      const headers = (incoming.headers.get('Access-Control-Request-Headers') ?? '').split(',').map(value => value.trim().toLowerCase()).filter(Boolean);
      if (!origin || incoming.headers.get('Access-Control-Request-Method') !== 'POST' ||
          headers.some(value => !['authorization','content-type','apikey','x-client-info','idempotency-key','x-order-id','x-receipt-name'].includes(value))) return respond(403, 'PREFLIGHT_FORBIDDEN');
      return new Response(null, { status: 204, headers: { 'Access-Control-Allow-Origin': origin, Vary: 'Origin', 'Cache-Control': 'no-store',
        'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info, Idempotency-Key, X-Order-Id, X-Receipt-Name' } });
    }
    if (incoming.method !== 'POST') return respond(405, 'METHOD_NOT_ALLOWED');
    const authorization = incoming.headers.get('Authorization');
    const key = incoming.headers.get('Idempotency-Key');
    const order = incoming.headers.get('X-Order-Id')?.toLowerCase();
    const name = incoming.headers.get('X-Receipt-Name');
    const mime = incoming.headers.get('Content-Type');
    if (!authorization?.startsWith('Bearer ') || authorization.length > 16384) return respond(401, 'AUTH_REQUIRED');
    if (!key || !/^[A-Za-z0-9._:-]{1,128}$/.test(key) || !uuid(order)) return respond(400, 'INVALID_REQUEST');
    if (receiptUploadsEnabled !== true || !inspection) return respond(503, 'RECEIPT_UPLOAD_UNAVAILABLE');
    const url = env('SUPABASE_URL'), publicKey = env('SUPABASE_ANON_KEY'), serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !publicKey || !serviceKey) return respond(503, 'SERVICE_UNAVAILABLE');
    const serviceHeaders = { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey };
    const options = { redirect: 'error', signal: AbortSignal.timeout(15000) };
    try {
      const bytes = await boundedBytes(incoming.body);
      const extension = receiptType(name, mime, bytes);
      const sha256 = digest(bytes);
      const auth = await request(`${url}/auth/v1/user`, { ...options, headers: { Authorization: authorization, apikey: publicKey } });
      if (!auth.ok) return respond(401, 'AUTH_REQUIRED');
      const user = await auth.json();
      const parts = authorization.slice(7).split('.');
      if (parts.length !== 3) return respond(401, 'AUTH_REQUIRED');
      let claims;
      try {
        const payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, '=')), value => value.charCodeAt(0))));
      } catch { return respond(401, 'AUTH_REQUIRED'); }
      if (!claims || typeof claims !== 'object' || Array.isArray(claims) || !uuid(user?.id) || user.is_anonymous === true ||
          claims.sub !== user.id || claims.role !== 'authenticated' || !uuid(claims.session_id) || !['aal1','aal2'].includes(claims.aal)) return respond(401, 'AUTH_REQUIRED');
      await inspectReceipt(inspection, bytes, mime, sha256);
      const identity = { p_actor: user.id, p_session_id: claims.session_id, p_aal: claims.aal };
      const rpc = async (functionName, args) => request(`${url}/rest/v1/rpc/${functionName}`, {
        method: 'POST', headers: { ...serviceHeaders, 'Content-Type': 'application/json' }, body: JSON.stringify(args),
        redirect: 'error', signal: AbortSignal.timeout(15000),
      });
      const sqlError = async response => {
        const result = await response.json();
        const errors = { '42501': [403, 'FORBIDDEN'], '22023': [409, 'RECEIPT_CONFLICT'], '23505': [409, 'RECEIPT_CONFLICT'], P0002: [404, 'ORDER_NOT_FOUND'], '55000': [409, 'ORDER_NOT_PAYABLE'] };
        const [status, code] = errors[result?.code] ?? [503, 'SERVICE_UNAVAILABLE'];
        return respond(status, code);
      };
      const preparation = await rpc('csa108_prepare_receipt', { ...identity, p_key: key, p_order: order, p_digest: sha256,
        p_size: bytes.byteLength, p_mime: mime, p_extension: extension });
      if (!preparation.ok) return await sqlError(preparation);
      const reserved = await preparation.json();
      const expectedPath = `${user.id}/${order}/${reserved?.submission_id}/${reserved?.upload_id}.${extension}`;
      if (!reserved || !uuid(reserved.upload_id) || !uuid(reserved.submission_id) || reserved.receipt_asset_id !== reserved.upload_id ||
          reserved.bucket !== 'bank-receipts' || reserved.object_path !== expectedPath ||
          typeof reserved.replayed !== 'boolean' || typeof reserved.finalized !== 'boolean') return respond(503, 'SERVICE_UNAVAILABLE');
      const objectUrl = `${url}/storage/v1/object/bank-receipts/${expectedPath}`;
      if (!reserved.finalized) {
        const upload = await request(objectUrl, { method: 'POST', headers: { ...serviceHeaders, 'Content-Type': mime, 'x-upsert': 'false' },
          body: bytes, redirect: 'error', signal: AbortSignal.timeout(15000) });
        if (!upload.ok && upload.status !== 409) {
          let collision = false;
          if (upload.status === 400) {
            // Legacy Storage reports a duplicate as HTTP 400. Parse only a bounded error.
            const reader = upload.body?.getReader();
            if (reader) {
              let length = 0;
              const chunks = [];
              try {
                while (true) {
                  const { done, value } = await reader.read();
                  if (done) break;
                  length += value.byteLength;
                  if (length > 4096) { await reader.cancel(); break; }
                  chunks.push(value);
                }
                if (length <= 4096) {
                  const errorBytes = new Uint8Array(length);
                  let offset = 0;
                  for (const chunk of chunks) { errorBytes.set(chunk, offset); offset += chunk.byteLength; }
                  const details = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(errorBytes));
                  collision = details?.error === 'Duplicate' || details?.code === 'ResourceAlreadyExists' ||
                    details?.statusCode === '409' || details?.statusCode === 409;
                }
              } catch { collision = false; }
              finally { reader.releaseLock(); }
            }
          }
          if (!collision) return respond(503, 'SERVICE_UNAVAILABLE');
        }
      }
      const stored = await request(objectUrl, { method: 'GET', headers: serviceHeaders, redirect: 'error', signal: AbortSignal.timeout(15000) });
      if (!stored.ok) return respond(503, 'SERVICE_UNAVAILABLE');
      const actual = await boundedBytes(stored.body);
      if (stored.headers.get('Content-Type') !== mime || actual.byteLength !== bytes.byteLength || digest(actual) !== sha256) return respond(409, 'RECEIPT_CONFLICT');
      receiptType(name, mime, actual);
      const reference = await inspectReceipt(inspection, actual, mime, sha256);
      const finalization = await rpc('csa109_finalize_receipt', { ...identity, p_upload_id: reserved.upload_id, p_digest: sha256,
        p_size: actual.byteLength, p_mime: mime, p_inspection_reference: reference });
      if (!finalization.ok) return await sqlError(finalization);
      const result = await finalization.json();
      if (!result || result.order_id !== order || result.submission_id !== reserved.submission_id || result.status !== 'submitted' ||
          typeof result.replayed !== 'boolean') return respond(503, 'SERVICE_UNAVAILABLE');
      return respond(result.replayed ? 200 : 201, undefined, { order_id: result.order_id, submission_id: result.submission_id,
        status: 'submitted', ...(result.replayed ? {} : { order_status: 'pending_verification' }) });
    } catch (error) {
      if (error instanceof ReceiptError) {
        const status = error.code === 'RECEIPT_TOO_LARGE' ? 413 : error.code === 'INSPECTION_FAILED' ? 422 : 400;
        return respond(status, error.code);
      }
      return respond(503, 'SERVICE_UNAVAILABLE');
    }
  };
}


