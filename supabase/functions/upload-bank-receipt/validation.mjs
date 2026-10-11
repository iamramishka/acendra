import { createHash } from 'node:crypto';

export const MAX_RECEIPT_BYTES = 5242880;
export class ReceiptError extends Error {
  constructor(code) { super(code); this.code = code; }
}
export const digest = bytes => createHash('sha256').update(bytes).digest('hex');
export async function boundedBytes(body) {
  const reader = body?.getReader();
  if (!reader) throw new ReceiptError('INVALID_RECEIPT');
  const chunks = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > MAX_RECEIPT_BYTES) {
        await reader.cancel();
        throw new ReceiptError('RECEIPT_TOO_LARGE');
      }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  if (size === 0) throw new ReceiptError('INVALID_RECEIPT');
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  return bytes;
}

export function receiptType(name, mime, bytes) {
  if (typeof name !== 'string' || !/^[A-Za-z0-9][A-Za-z0-9._-]{0,99}\.(?:jpe?g|png|pdf)$/i.test(name)) {
    throw new ReceiptError('INVALID_RECEIPT');
  }
  const extension = name.split('.').at(-1).toLowerCase();
  const expected = { jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', pdf: 'application/pdf' }[extension];
  if (mime !== expected) throw new ReceiptError('INVALID_RECEIPT');
  const prefix = { 'image/jpeg': [255,216,255], 'image/png': [137,80,78,71,13,10,26,10], 'application/pdf': [37,80,68,70,45] }[mime];
  if (!prefix.every((value, index) => bytes[index] === value)) throw new ReceiptError('INVALID_RECEIPT');
  // Signature is only a format filter. Trusted parsing/scanning is mandatory below.
  return extension;
}

export function snapshotInspector(inspector) {
  if (!inspector || typeof inspector.inspect !== 'function' ||
      typeof inspector.policyReference !== 'string' || !/^[A-Za-z0-9._:-]{1,128}$/.test(inspector.policyReference) ||
      !Number.isInteger(inspector.timeoutMs) || inspector.timeoutMs < 1 || inspector.timeoutMs > 30000) return undefined;
  return Object.freeze({ inspect: inspector.inspect, policyReference: inspector.policyReference, timeoutMs: inspector.timeoutMs });
}

export async function inspectReceipt(inspector, bytes, mime, sha256) {
  let timer;
  try {
    const output = await Promise.race([
      Promise.resolve().then(() => inspector.inspect({ bytes: bytes.slice(), mime, size: bytes.byteLength, sha256 })),
      new Promise((_, reject) => { timer = setTimeout(() => reject(new ReceiptError('INSPECTION_FAILED')), inspector.timeoutMs); }),
    ]);
    if (!output || output.safe !== true || output.parseable !== true || output.encrypted !== false ||
        output.withinResourceLimits !== true || output.sha256 !== sha256 || output.size !== bytes.byteLength ||
        output.mime !== mime || output.policyReference !== inspector.policyReference) throw new ReceiptError('INSPECTION_FAILED');
    return inspector.policyReference;
  } catch { throw new ReceiptError('INSPECTION_FAILED'); }
  finally { clearTimeout(timer); }
}
