import { createStagingPaymentHandler } from '../_shared/payments/staging-entrypoints.mjs';

Deno.serve(createStagingPaymentHandler('order', { env: (name: string) => Deno.env.get(name) }));
