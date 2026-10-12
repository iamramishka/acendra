import { createHandler } from './handler.mjs';
// Reviewed production activation remains a separate release gate.
Deno.serve(createHandler({ env: name => Deno.env.get(name) }));
