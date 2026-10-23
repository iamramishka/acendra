import test from 'node:test';
import assert from 'node:assert/strict';
import { pdfBrowserRuntimeStatus } from './pdf_browser_runtime.mjs';

test('Supabase CI without Flutter skips the PDF browser check', () => {
  const result = pdfBrowserRuntimeStatus({platform: 'linux', env: {CI: 'true'},
    probe: () => ({error: Object.assign(new Error('not found'), {code: 'ENOENT'})})});
  assert.equal(result.skip, true);
  assert.match(result.reason, /Flutter.*not installed/);
});

test('an installed but broken Flutter SDK fails instead of silently skipping', () => {
  assert.throws(() => pdfBrowserRuntimeStatus({platform: 'linux', env: {CI: 'true'},
    probe: () => ({status: 1, stderr: 'SDK failure'})}), /Flutter runtime.*unusable/);
});

test('usable Flutter CI runs the real browser suite', () => {
  let probes = 0;
  const result = pdfBrowserRuntimeStatus({platform: 'linux', env: {CI: 'true'},
    probe: () => {probes++; return {status: 0};}});
  assert.equal(result.skip, false);
  assert.equal(probes, 1);
});

test('permission and timeout errors cannot be reported as an absent SDK', () => {
  for (const code of ['EACCES', 'ETIMEDOUT']) {
    assert.throws(() => pdfBrowserRuntimeStatus({platform: 'linux', env: {CI: 'true'},
      probe: () => ({error: Object.assign(new Error(code), {code})})}), /Flutter runtime.*unusable/);
  }
});

test('non-hosted runs do not probe or launch a Flutter process', () => {
  for (const options of [{platform: 'win32', env: {CI: 'true'}}, {platform: 'linux', env: {}}]) {
    const result = pdfBrowserRuntimeStatus({...options, probe: () => {throw new Error('unexpected probe');}});
    assert.equal(result.skip, true);
  }
});
