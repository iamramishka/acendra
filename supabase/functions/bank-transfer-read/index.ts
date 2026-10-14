import { createHandler } from './handler.mjs';
// Operational acceptance remains required; no environment flag enables reads.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name) }));
