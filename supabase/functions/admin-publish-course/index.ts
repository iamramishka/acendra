import { createHandler } from './handler.mjs';
import { reportingEnabled as serverReleaseEnabled } from '../_shared/reporting-activation.mjs';
const env = (name: string) => Deno.env.get(name);
// Configuration enables transport only; SQL still enforces MFA and readiness.
Deno.serve(createHandler({ env, enabled: serverReleaseEnabled(env, 'ACENDRA_COURSE_PUBLICATION_ENABLED') }));
