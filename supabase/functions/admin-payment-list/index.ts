import { createHandler } from './handler.mjs';
import { reportingEnabled } from '../_shared/reporting-activation.mjs';
const env = (name: string) => Deno.env.get(name);
Deno.serve(createHandler({ env, enabled: reportingEnabled(env, 'ACENDRA_ADMIN_PAYMENT_LIST_ENABLED') }));
