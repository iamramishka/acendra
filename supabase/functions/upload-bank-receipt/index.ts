import { createHandler } from './handler.mjs';
// Receipt inspection technology and resource limits require separate approval.
// No environment flag enables uploads; no default inspector is supplied.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name) }));
