import { createHandler } from './handler.mjs';
// Provider acceptance is blocked. No environment variable enables this endpoint.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name) }));
