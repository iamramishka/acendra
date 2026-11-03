import { timingSafeEqual } from 'node:crypto';

const response = (status, body) => Response.json(body, {
  status, headers: { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' },
});

// Private, body-free control plane seam. This does not install a public route.
export function createWorkerHandler({ enabled = false, secret, run } = {}) {
  if (enabled && (typeof secret !== 'string' || !/^[A-Za-z0-9_-]{32,128}$/.test(secret) ||
      typeof run !== 'function')) throw Error('PDF_CONTROLLER_CONFIGURATION_REQUIRED');
  let active = false;
  return async request => {
    if (!enabled) return response(503, { error: 'PDF_WORKER_DISABLED' });
    if (request.method !== 'POST') return response(405, { error: 'METHOD_NOT_ALLOWED' });
    const expected = Buffer.from(`Bearer ${secret}`);
    const actual = Buffer.from(request.headers.get('authorization') ?? '');
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) return response(401, { error: 'AUTH_REQUIRED' });
    if (request.body !== null) return response(400, { error: 'INVALID_REQUEST' });
    // Per-instance guard only. A durable global admission gate remains required
    // before deploying concurrent controllers; it belongs to the queue contract.
    if (active) return response(409, { error: 'PDF_WORKER_BUSY' });
    active = true;
    try {
      const result = await run();
      if (!['idle', 'completed'].includes(result?.state)) throw Error();
      return response(200, { state: result.state });
    } catch {
      return response(503, { error: 'PDF_JOB_FAILED' });
    } finally { active = false; }
  };
}
