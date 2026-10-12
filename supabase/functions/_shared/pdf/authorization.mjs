// Trusted backend adapter. Claims are used only after Auth validates this exact token;
// current session, entitlement, publication and resource ownership remain SQL checks.
export class PdfAuthorizationError extends Error {
  constructor(code) { super(code); this.name = 'PdfAuthorizationError'; this.code = code; }
}
const deny = code => { throw new PdfAuthorizationError(code); };
const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
const safeCodes = new Set(['AUTH_REQUIRED', 'ACCESS_DENIED', 'PDF_NOT_FOUND']);
const defaultEnv = name => globalThis.Deno?.env?.get(name);
async function boundedJson(response) {
  const declared = response.headers.get('content-length');
  if (declared !== null && (!/^\d+$/.test(declared) || Number(declared) > 65536)) deny('SERVICE_UNAVAILABLE');
  if (!response.body) deny('SERVICE_UNAVAILABLE');
  const reader = response.body.getReader();
  const chunks = []; let length = 0;
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > 65536) { await reader.cancel(); deny('SERVICE_UNAVAILABLE'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(length); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  const result = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  if (!result || typeof result !== 'object' || Array.isArray(result)) deny('SERVICE_UNAVAILABLE');
  return result;
}
function claimsOf(authorization) {
  if (typeof authorization !== 'string' || authorization.length > 16384 || !/^Bearer [A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(authorization)) deny('AUTH_REQUIRED');
  try {
    const payload = authorization.slice(7).split('.')[1];
    const text = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
    const bytes = Uint8Array.from(text, char => char.charCodeAt(0));
    const claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    if (!claims || typeof claims !== 'object' || Array.isArray(claims)) deny('AUTH_REQUIRED');
    return claims;
  } catch { deny('AUTH_REQUIRED'); }
}
function configuration(env) {
  const url = env('SUPABASE_URL'), publicKey = env('SUPABASE_ANON_KEY'), serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
  let parsed;
  try { parsed = new URL(url); } catch { deny('SERVICE_UNAVAILABLE'); }
  const loopback = parsed.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(parsed.hostname);
  if ((!loopback && parsed.protocol !== 'https:') || parsed.username || parsed.password || parsed.search || parsed.hash || !['', '/'].includes(parsed.pathname) ||
      ![publicKey, serviceKey].every(key => typeof key === 'string' && key.length > 0 && key.length <= 16384 && !/[\x00-\x20\x7f]/.test(key))) deny('SERVICE_UNAVAILABLE');
  return { url: parsed.origin, publicKey, serviceKey };
}
function derivativePath(path) {
  if (typeof path !== 'string' || path.length > 1024) return false;
  const parts = path.split('/');
  if (parts.length !== 5 || parts[0] !== 'derivatives' || !uuid(parts[1]) || !uuid(parts[3]) || !/\.pdf$/.test(parts[4]) || !uuid(parts[4].slice(0, -4))) return false;
  return /^v[1-9][0-9]{0,9}$/.test(parts[2]) && Number(parts[2].slice(1)) <= 2147483647;
}
function validateResult(result, lessonId, resourceId) {
  if (result.lesson_id !== lessonId) deny('SERVICE_UNAVAILABLE');
  if (result.state === 'preparing' && resourceId === null && result.resource_id === null) return { state: 'preparing', lesson_id: lessonId, resource_id: null };
  if (result.state !== 'ready' || !uuid(result.resource_id) || (resourceId !== null && result.resource_id !== resourceId) ||
      result.bucket !== 'course-pdfs' || !derivativePath(result.object_path) ||
      !Number.isSafeInteger(result.size_bytes) || result.size_bytes <= 0 || result.size_bytes > 50 * 1024 * 1024 ||
      typeof result.checksum_sha256 !== 'string' || !/^[0-9a-f]{64}$/.test(result.checksum_sha256)) deny('SERVICE_UNAVAILABLE');
  return { state: 'ready', lesson_id: lessonId, resource_id: result.resource_id, bucket: result.bucket,
    object_path: result.object_path, size_bytes: result.size_bytes, checksum_sha256: result.checksum_sha256 };
}
export function createAuthorizer({ env = defaultEnv, fetch: request = globalThis.fetch } = {}) {
  return async function authorize({ authorization, lessonId, resourceId = null } = {}) {
    try {
      if (!uuid(lessonId) || (resourceId !== null && !uuid(resourceId))) deny('PDF_NOT_FOUND');
      lessonId = lessonId.toLowerCase();
      resourceId = resourceId === null ? null : resourceId.toLowerCase();
      const claims = claimsOf(authorization);
      const { url, publicKey, serviceKey } = configuration(env);
      const authResponse = await request(`${url}/auth/v1/user`, { headers: { Authorization: authorization, apikey: publicKey }, redirect: 'error', signal: AbortSignal.timeout(15000) });
      if ([401, 403].includes(authResponse.status)) deny('AUTH_REQUIRED');
      if (authResponse.status !== 200) deny('SERVICE_UNAVAILABLE');
      const user = await boundedJson(authResponse);
      if (!uuid(user.id) || user.is_anonymous === true || claims.sub !== user.id || claims.role !== 'authenticated' || !uuid(claims.session_id) || !['aal1', 'aal2'].includes(claims.aal)) deny('AUTH_REQUIRED');
      const response = await request(`${url}/rest/v1/rpc/csa140_resolve_pdf`, { method: 'POST',
        headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({ p_actor: user.id, p_session_id: claims.session_id, p_aal: claims.aal, p_lesson: lessonId, p_resource: resourceId }),
        redirect: 'error', signal: AbortSignal.timeout(15000) });
      const result = await boundedJson(response);
      if (response.status !== 200) {
        if (response.status >= 400 && response.status < 500) {
          const code = safeCodes.has(result.message) ? result.message : result.code;
          if (safeCodes.has(code)) deny(code);
          if (result.code === '42501') deny('ACCESS_DENIED');
          if (result.code === 'P0002') deny('PDF_NOT_FOUND');
        }
        deny('SERVICE_UNAVAILABLE');
      }
      return validateResult(result, lessonId, resourceId);
    } catch (error) {
      if (error instanceof PdfAuthorizationError) throw error;
      deny('SERVICE_UNAVAILABLE');
    }
  };
}
