import { createStagingPaymentHandler } from '../_shared/payments/staging-entrypoints.mjs';
// Reviewed exact-project sandbox-only wiring; every other environment is closed.
Deno.serve(createStagingPaymentHandler('initialize', { env: (name: string) => Deno.env.get(name) }));
