import { createStagingPaymentHandler } from '../_shared/payments/staging-entrypoints.mjs';
// Sandbox callbacks still require checksum plus authenticated settlement retrieval.
Deno.serve(createStagingPaymentHandler('webhook', { env: (name: string) => Deno.env.get(name) }));
