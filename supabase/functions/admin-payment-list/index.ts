import { createHandler } from './handler.mjs';
// Hard-disabled until a separate reviewed, owner-approved activation release.
Deno.serve(createHandler({ env: name => Deno.env.get(name), enabled: false }));
