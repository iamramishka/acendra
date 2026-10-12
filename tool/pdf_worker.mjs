// Local trusted worker seam. Live queue/storage credentials belong to its caller.
// generate must be deterministic for the same source and immutable identity:
// retry recovery accepts existing objects only when their bytes match exactly.
import { createHash } from 'node:crypto';
const MAX_BYTES = 50 * 1024 * 1024;
const UUID = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
const uuid = value => typeof value === 'string' && new RegExp(`^${UUID}$`).test(value);
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
export class PdfJobError extends Error {
  constructor() { super('PDF_JOB_FAILED'); this.name = 'PdfJobError'; this.code = 'PDF_JOB_FAILED'; }
}
const fail = () => { throw new PdfJobError(); };
function validatedJob(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) fail();
  const job = { ...raw };
  const source = typeof job.source_path === 'string' && job.source_path.match(new RegExp(`^originals/(${UUID})/v([1-9][0-9]{0,9})\\.pdf$`));
  const target = typeof job.object_path === 'string' && job.object_path.match(new RegExp(`^derivatives/(${UUID})/v([1-9][0-9]{0,9})/(${UUID})/(${UUID})\\.pdf$`));
  if (!uuid(job.resource_id) || !uuid(job.lease_token) || !uuid(job.license_id) || job.bucket !== 'course-pdfs' ||
      !source || !target || source[1] !== target[1] || source[2] !== target[2] || target[3] !== job.license_id ||
      Number(source[2]) > 2147483647 || !Number.isSafeInteger(job.size_bytes) || job.size_bytes <= 0 || job.size_bytes > MAX_BYTES ||
      typeof job.source_digest !== 'string' || !/^[0-9a-f]{64}$/.test(job.source_digest) ||
      typeof job.display_name !== 'string' || job.display_name.length > 200 || !job.display_name.trim() || /[\x00-\x1f\x7f]/.test(job.display_name)) fail();
  return Object.freeze(job);
}
async function bytesOf(value, maximum) {
  if (value instanceof Uint8Array) {
    if (!value.byteLength || value.byteLength > maximum) fail();
    return Uint8Array.from(value);
  }
  if (!(value instanceof Response) || value.status !== 200 || !value.body) fail();
  const declared = value.headers.get('content-length');
  if (declared !== null && (!/^\d+$/.test(declared) || Number(declared) > maximum)) { await value.body.cancel(); fail(); }
  const reader = value.body.getReader(); let length = 0; const chunks = [];
  try {
    while (true) {
      const {value: chunk, done} = await reader.read();
      if (done) break;
      length += chunk.byteLength;
      if (length > maximum) { await reader.cancel(); fail(); }
      chunks.push(chunk);
    }
  } finally { reader.releaseLock(); }
  if (!length || (declared !== null && Number(declared) !== length)) fail();
  const result = new Uint8Array(length); let offset = 0;
  for (const chunk of chunks) { result.set(chunk, offset); offset += chunk.byteLength; }
  return result;
}
export async function runPdfJob({ rpc, storage, generate } = {}) {
  try {
    if (typeof rpc !== 'function' || typeof generate !== 'function' || typeof storage?.download !== 'function' || typeof storage?.upload !== 'function' || typeof storage?.exists !== 'function') fail();
    const raw = await rpc('csa148_claim_pdf_job', {});
    if (raw === null) return {state: 'idle'};
    const job = validatedJob(raw);
    const source = await bytesOf(await storage.download({bucket: job.bucket, path: job.source_path}), job.size_bytes);
    if (source.byteLength !== job.size_bytes || digest(source) !== job.source_digest) fail();
    const output = await bytesOf(await generate(source, {display_name: job.display_name, license_id: job.license_id, source_sha256: job.source_digest}), MAX_BYTES);
    const outputDigest = digest(output);
    const target = {bucket: job.bucket, path: job.object_path};
    const uploaded = await storage.upload({...target, bytes: output, upsert: false});
    if (uploaded?.created !== true) {
      if (uploaded?.created !== false || await storage.exists(target) !== true) fail();
      const existing = await bytesOf(await storage.download(target), output.byteLength);
      if (existing.byteLength !== output.byteLength || digest(existing) !== outputDigest) fail();
    }
    const completed = await rpc('csa148_complete_pdf_job', {p_resource: job.resource_id, p_lease: job.lease_token, p_digest: outputDigest, p_size: output.byteLength});
    if (completed !== true) fail();
    return {state: 'completed', resource_id: job.resource_id};
  } catch { fail(); }
}
