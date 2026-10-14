import test from 'node:test';
import assert from 'node:assert/strict';
import { createWorker } from '../supabase/functions/payment-notifications/worker.mjs';

const notice = {
  id: 'synthetic-hosted-notice', event_key: 'payment_verified:synthetic-order-a',
  recipient_user_id: 'synthetic-buyer', notification_type: 'payment_verified',
  safe_payload: { order_id: 'synthetic-order-a' },
};

test('CSA201 late provider success after timeout cannot overwrite a reclaimed successful lease', async () => {
  const deliveries = [], acknowledgements = [];
  let releaseLateDelivery;
  const lateDelivery = new Promise(resolve => { releaseLateDelivery = resolve; });
  let lease = 0;
  const worker = createWorker({
    enabled: true, deliveryTimeoutMs: 10,
    store: {
      claim: async () => [{ ...notice, lease_token: `lease-${++lease}` }],
      complete: async (...args) => { acknowledgements.push(args); return true; },
    },
    resolveRecipient: async () => 'buyer@example.test',
    deliver: mail => {
      deliveries.push(mail);
      return deliveries.length === 1 ? lateDelivery : Promise.resolve({ accepted: true });
    },
  });
  try {
    assert.deepEqual(await worker(), { sent: 0, failed: 1, stale: 0 });
    assert.equal(deliveries[0].signal.aborted, true);
    assert.deepEqual(await worker(), { sent: 1, failed: 0, stale: 0 });
    assert.equal(deliveries[0].idempotencyKey, deliveries[1].idempotencyKey);
    releaseLateDelivery({ accepted: true });
    await lateDelivery;
    await new Promise(resolve => setImmediate(resolve));
    assert.deepEqual(acknowledgements, [
      [notice.id, 'lease-1', false], [notice.id, 'lease-2', true],
    ]);
  } finally { releaseLateDelivery({ accepted: true }); }
});

test('CSA201 separate recovered payment events never share a provider idempotency key', async () => {
  const keys = [], completions = [];
  const rows = [notice, { ...notice, id: 'synthetic-notice-b',
    event_key: 'payment_verified:synthetic-order-b', safe_payload: { order_id: 'synthetic-order-b' } }];
  const worker = createWorker({
    enabled: true,
    store: {
      claim: async limit => { assert.equal(limit, 1); return [{ ...rows.shift(), lease_token: 'synthetic-lease' }]; },
      complete: async (...args) => { completions.push(args); return true; },
    },
    resolveRecipient: async () => 'buyer@example.test',
    deliver: async mail => { keys.push(mail.idempotencyKey); return { accepted: true }; },
  });
  assert.deepEqual(await worker(), { sent: 1, failed: 0, stale: 0 });
  assert.deepEqual(await worker(), { sent: 1, failed: 0, stale: 0 });
  assert.notEqual(keys[0], keys[1]);
  for (const key of keys) assert.match(key, /^[a-f0-9]{64}$/);
  assert.deepEqual(completions.map(args => args[0]), [notice.id, 'synthetic-notice-b']);
});
