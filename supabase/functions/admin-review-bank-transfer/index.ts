import { createHandler } from './handler.mjs';
// Receipt inspection limits and bank operational release gates remain pending.
// No environment flag can enable this deployed endpoint.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name) }));
