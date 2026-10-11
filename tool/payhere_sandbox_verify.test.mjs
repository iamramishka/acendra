import test from 'node:test';
import assert from 'node:assert/strict';
import { verifySandbox } from './payhere_sandbox_verify.mjs';

test('sandbox probe requires separate retrieval credentials before making requests', async () => {
  for (const env of [{}, { PAYHERE_SANDBOX_MERCHANT_ID: 'synthetic', PAYHERE_SANDBOX_MERCHANT_SECRET: 'synthetic' }]) {
    await assert.rejects(verifySandbox(env), { code: 'SANDBOX_CONFIGURATION_REQUIRED' });
  }
});
