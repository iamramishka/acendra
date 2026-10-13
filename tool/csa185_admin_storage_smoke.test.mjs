import assert from 'node:assert/strict';
import test from 'node:test';
import { runAdminStorageSmoke } from './csa185_admin_storage_smoke.mjs';

test('admin Storage acceptance refuses a non-task-owned endpoint before reading credentials', async () => {
  let networkCalls = 0;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = () => { networkCalls++; throw new Error('Unexpected network'); };
  try {
    await assert.rejects(runAdminStorageSmoke({ layout: { portBase: 58000 }, base: 'https://example.invalid' }),
      { message: 'Admin Storage smoke failed at task-owned local credentials; private diagnostics suppressed.' });
    assert.equal(networkCalls, 0);
  } finally { globalThis.fetch = originalFetch; }
});

test('admin Storage acceptance refuses a different loopback stack', async () => {
  await assert.rejects(runAdminStorageSmoke({ layout: { portBase: 58000 }, base: 'http://127.0.0.1:58010' }),
    { message: 'Admin Storage smoke failed at task-owned local credentials; private diagnostics suppressed.' });
});
