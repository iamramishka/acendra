import { createHandler } from './handler.mjs';
// Reviewed activation and deployment remain separate from development integration.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name), enabled: false }));
