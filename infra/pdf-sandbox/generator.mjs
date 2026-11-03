import { createHash } from 'node:crypto';

const MAX_BYTES = 50 * 1024 * 1024;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const POLICIES = new Set(['14000000-0000-4000-8000-000000000001', '14000000-0000-4000-8000-000000000002']);
const INPUT = '/vercel/sandbox/pdf-job/input';
const OUTPUT = '/vercel/sandbox/pdf-job/output';
const failure = () => Error('PDF_GENERATION_FAILED');

function trustedIdentity(source, identity) {
  const fields = ['display_name', 'license_id', 'source_sha256', 'policy_id'];
  if (!(source instanceof Uint8Array) || source.byteLength < 1 || source.byteLength > MAX_BYTES ||
      !identity || Object.keys(identity).length !== fields.length || fields.some(key => !Object.hasOwn(identity, key)) ||
      typeof identity.display_name !== 'string' || !identity.display_name.trim() || identity.display_name.length > 200 ||
      /[\x00-\x1f\x7f]/.test(identity.display_name) || !UUID.test(identity.license_id) ||
      !POLICIES.has(identity.policy_id) ||
      identity.source_sha256 !== createHash('sha256').update(source).digest('hex')) throw failure();
  return Object.fromEntries(fields.map(key => [key, identity[key]]));
}

async function boundedPdf(stream, signal) {
  if (!stream || typeof stream[Symbol.asyncIterator] !== 'function') throw failure();
  const chunks = [];
  let total = 0;
  const abort = () => stream.destroy?.(failure());
  signal.addEventListener('abort', abort, { once: true });
  try {
    signal.throwIfAborted();
    for await (const chunk of stream) {
      if (!(chunk instanceof Uint8Array)) throw failure();
      total += chunk.byteLength;
      if (total > MAX_BYTES) throw failure();
      chunks.push(Buffer.from(chunk));
    }
  } finally {
    signal.removeEventListener('abort', abort);
    stream.destroy?.();
  }
  const output = Buffer.concat(chunks, total);
  if (output.length < 5 || output.subarray(0, 5).toString('ascii') !== '%PDF-') throw failure();
  return output;
}

// Trusted controller configuration only. No browser or queue-selected runtime.
export function createSandboxGenerator({ image, create, region = 'iad1' } = {}) {
  if (typeof image !== 'string' || image.length > 512 ||
      !/^[a-z0-9][a-z0-9./_-]*@sha256:[a-f0-9]{64}$/.test(image) ||
      typeof create !== 'function' || !/^[a-z]{3}[1-9]$/.test(region)) throw Error('PDF_SANDBOX_CONFIGURATION_REQUIRED');
  return async (source, identity, { signal: cancellation } = {}) => {
    let sandbox;
    let result;
    let failed = false;
    const signal = AbortSignal.any([AbortSignal.timeout(100000), ...(cancellation ? [cancellation] : [])]);
    try {
      const metadata = trustedIdentity(source, identity);
      signal.throwIfAborted();
      sandbox = await create({ image, region, persistent: false, networkPolicy: 'deny-all',
        ports: [], mounts: {}, env: {}, resources: { vcpus: 1 }, timeout: 90000,
        signal: AbortSignal.any([signal, AbortSignal.timeout(20000)]) });
      // Refuse unsafe returned metadata before any private document is uploaded.
      if (sandbox.persistent !== false || sandbox.currentSession().networkPolicy !== 'deny-all' ||
          typeof sandbox.image !== 'string' || !sandbox.image.endsWith(image.slice(image.indexOf('@sha256:')))) throw failure();
      await sandbox.mkDir(INPUT, { signal });
      await sandbox.mkDir(OUTPUT, { signal });
      const command = async (mode, timeoutMs) => {
        const response = await sandbox.runCommand({ cmd: '/opt/acendra/launch', args: [mode],
          env: {}, sudo: false, timeoutMs, signal });
        if (response.exitCode !== 0) throw failure();
      };
      await command('--check', 10000);
      await sandbox.writeFiles([
        { path: `${INPUT}/source.pdf`, content: source, mode: 0o600 },
        { path: `${INPUT}/identity.json`, content: Buffer.from(JSON.stringify(metadata)), mode: 0o600 },
      ], { signal });
      await command('--generate', 65000);
      result = await boundedPdf(await sandbox.readFile({ path: `${OUTPUT}/derivative.pdf` }, { signal }), signal);
    } catch {
      failed = true;
    } finally {
      if (sandbox) {
        try {
          // Cleanup has its own deadline even if the job deadline has expired.
          const stopped = await sandbox.stop({ signal: AbortSignal.timeout(10000) });
          if (stopped?.snapshot || stopped?.status !== 'stopped') failed = true;
        } catch { failed = true; }
      }
    }
    if (failed || !result) throw failure();
    return result;
  };
}
