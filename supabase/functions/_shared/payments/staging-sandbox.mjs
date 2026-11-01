import { createPayHereAdapter } from './payhere.mjs';

export const STAGING_SUPABASE_URL = 'https://worrsweluwjmppwsygre.supabase.co';
export const STAGING_APP_ORIGIN = 'https://acendra.vercel.app';

// Deliberately no generic merchant credentials or production configuration.
// Trusted deployer must explicitly provide sandbox-scoped server credentials.
export function stagingSandboxConfiguration(env) {
  if (env('APP_ENV') !== 'staging' || env('PAYHERE_ENVIRONMENT') !== 'sandbox' ||
      env('SUPABASE_URL') !== STAGING_SUPABASE_URL ||
      env('ACENDRA_CHECKOUT_ALLOWED_ORIGINS') !== STAGING_APP_ORIGIN) return undefined;
  const config = Object.freeze({
    ready: true, environment: 'sandbox',
    merchantId: env('PAYHERE_SANDBOX_MERCHANT_ID'),
    merchantSecret: env('PAYHERE_SANDBOX_MERCHANT_SECRET'),
    appId: env('PAYHERE_SANDBOX_APP_ID'), appSecret: env('PAYHERE_SANDBOX_APP_SECRET'),
    // These authenticated pages read order status; redirects cannot settle a
    // payment. initialize-checkout binds the application order locator.
    returnUrl: `${STAGING_APP_ORIGIN}/payments/return`,
    cancelUrl: `${STAGING_APP_ORIGIN}/payments/cancel`,
    notifyUrl: `${STAGING_SUPABASE_URL}/functions/v1/payment-provider-webhook`,
  });
  try { createPayHereAdapter(config); return config; } catch { return undefined; }
}
