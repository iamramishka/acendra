import test from 'node:test';
import assert from 'node:assert/strict';
import { createWorker } from '../supabase/functions/payment-notifications/worker.mjs';

// The durable SQL lease/retry behavior is exercised by csa201's database test.
// These injected collaborators exercise delivery/acknowledgement loss only.
const notice = {
  id: 'synthetic-notice', event_key: 'payment_verified:synthetic-order',
  recipient_user_id: 'synthetic-buyer', notification_type: 'payment_verified',
  safe_payload: { order_id: 'synthetic-order' },
};

test('CSA201 accepted email with lost database acknowledgement retries with stable provider key', async () => {
  const deliveries = [];
  const acknowledgements = [];
  let invocation = 0;
  const worker = createWorker({
    enabled: true,
    store: {
      claim: async () => [{ ...notice, lease_token: `lease-${++invocation}` }],
      complete: async (...args) => {
        acknowledgements.push(args);
        if (invocation === 1) throw new Error('SYNTHETIC_ACKNOWLEDGEMENT_LOST');
        return true;
      },
    },
    resolveRecipient: async () => 'buyer@example.test',
    deliver: async mail => { deliveries.push(mail); return { accepted: true }; },
  });
  await assert.rejects(worker(), /SYNTHETIC_ACKNOWLEDGEMENT_LOST/);
  assert.deepEqual(await worker(), { sent: 1, failed: 0, stale: 0 });
  assert.equal(deliveries.length, 2);
  assert.match(deliveries[0].idempotencyKey, /^[a-f0-9]{64}$/);
  assert.equal(deliveries[0].idempotencyKey, deliveries[1].idempotencyKey);
  assert.deepEqual(acknowledgements, [
    ['synthetic-notice', 'lease-1', true], ['synthetic-notice', 'lease-2', true],
  ]);
});

test('CSA201 uncertain provider result retries without declaring email sent', async () => {
  const keys = [], acknowledgements = [];
  let attempt = 0;
  const worker = createWorker({
    enabled: true,
    store: {
      claim: async () => [{ ...notice, lease_token: `lease-${++attempt}` }],
      complete: async (...args) => { acknowledgements.push(args); return true; },
    },
    resolveRecipient: async () => 'buyer@example.test',
    deliver: async mail => {
      keys.push(mail.idempotencyKey);
      if (attempt === 1) throw new Error('SYNTHETIC_RESPONSE_LOST');
      return { accepted: true };
    },
  });
  assert.deepEqual(await worker(), { sent: 0, failed: 1, stale: 0 });
  assert.deepEqual(await worker(), { sent: 1, failed: 0, stale: 0 });
  assert.equal(keys[0], keys[1]);
  assert.deepEqual(acknowledgements.map(args => args[2]), [false, true]);
});
