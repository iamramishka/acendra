import { createHandler } from './handler.mjs';
// Approval of course-media limits, trusted inspection and operational readiness remains required.
// No runtime flag enables this endpoint and no default policy/inspector is supplied.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name) }));
