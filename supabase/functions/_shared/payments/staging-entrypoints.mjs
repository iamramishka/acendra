import { stagingSandboxConfiguration } from './staging-sandbox.mjs';
import { createHandler as orderHandler } from '../../create-checkout-order/handler.mjs';
import { createHandler as initializeHandler } from '../../initialize-checkout/handler.mjs';
import { createHandler as webhookHandler } from '../../payment-provider-webhook/handler.mjs';

// Same reviewed gate supplies every deployed payment entry point. Optional
// transport is a test seam; deployed indexes use the trusted global fetch.
export function createStagingPaymentHandler(kind, { env, fetch } = {}) {
  const config = stagingSandboxConfiguration(env);
  const shared = { env, ...(fetch ? { fetch } : {}) };
  switch (kind) {
    case 'order': return orderHandler({ ...shared, onlineCheckoutEnabled: config !== undefined });
    case 'initialize': return initializeHandler({ ...shared, onlineCheckoutEnabled: config !== undefined, paymentConfig: config });
    case 'webhook': return webhookHandler({ ...shared, onlinePaymentsEnabled: config !== undefined, providerConfig: config });
    default: throw new Error('UNKNOWN_PAYMENT_ENTRYPOINT');
  }
}
