import { createHandler } from './handler.mjs';
// Deploy together with the directory migration; authorization is rechecked in SQL.
Deno.serve(createHandler({ env: name => Deno.env.get(name) }));
