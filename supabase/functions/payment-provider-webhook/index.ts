import { createHandler } from './handler.mjs';
// CSA-100 real sandbox acceptance unavailable. No environment flag can enable
// this deployed endpoint; enablement needs a separately reviewed release change.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name) }));
