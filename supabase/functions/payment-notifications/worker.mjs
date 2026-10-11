import { createHash } from 'node:crypto';

const templates = Object.freeze({
 payment_verified: ['Purchase confirmed', 'Your payment has been verified. Check your account for current course access.'],
 bank_transfer_approved: ['Bank transfer approved', 'Your bank transfer has been verified. Check your account for current course access.'],
 bank_transfer_rejected: ['Bank transfer needs attention', 'Your bank transfer submission was rejected. Check your order status for the next step.'],
 enrollment_revoked: ['Course access changed', 'Your course access has changed. Check your account for current access.'],
 enrollment_changed: ['Course access updated', 'Your course access has been updated. Check your account for current access.'],
});

// Trusted server-only collaborators. deliver must support the stable event
// idempotency key and confirm acceptance; unknown delivery outcomes are retries.
// Production wiring requires an approved provider; no environment opt-in.
export function createWorker({ store, resolveRecipient, deliver, enabled = false } = {}) {
 return async () => {
  if (enabled !== true) return { disabled: true };
  if (!store?.claim || !store?.complete || !resolveRecipient || !deliver) throw new Error('NOTIFICATION_CONFIGURATION_REQUIRED');
  // One event per invocation keeps later events from waiting through another
  // delivery's timeout. The transport must respect the provided abort signal.
  const rows = await store.claim(1);
  if (!Array.isArray(rows) || rows.length > 1) throw new Error('INVALID_NOTIFICATION_BATCH');
  const result = { sent: 0, failed: 0, stale: 0 };
  for (const row of rows) {
   let sent = false;
   try {
    const template = templates[row.notification_type];
    if (!template || typeof row.event_key !== 'string' || row.event_key.length > 500 || !row.recipient_user_id) throw new Error('INVALID_NOTIFICATION');
    const to = await resolveRecipient(row.recipient_user_id);
    if (typeof to !== 'string' || to.length > 254 || !/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(to)) throw new Error('INVALID_RECIPIENT');
    let text = template[1];
    const reason = row.safe_payload?.public_rejection_reason;
    if (row.notification_type === 'bank_transfer_rejected' && typeof reason === 'string' && reason.length <= 1000 && !/[\x00-\x1f\x7f]/.test(reason)) text += `\n\n${reason}`;
    // Explicit fixed templates, plain text and no object spread prevent private
    // reviewer notes, storage paths or arbitrary HTML entering email.
    const response = await deliver({ to, subject: template[0], text,
     idempotencyKey: createHash('sha256').update(`acendra-notice:${row.event_key}`).digest('hex'), signal: AbortSignal.timeout(30000) });
    sent = response?.accepted === true;
   } catch {
    // Provider details and recipient data never enter stored diagnostics.
    sent = false;
   }
   const acknowledged = await store.complete(row.id, row.lease_token, sent);
   if (!acknowledged) result.stale++;
   else if (sent) result.sent++;
   else result.failed++;
  }
  return result;
 };
}
