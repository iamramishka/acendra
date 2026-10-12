import {createHandler} from './handler.mjs';
// Readiness gate: no environment flag can enable this deployment.
Deno.serve(createHandler({env:name=>Deno.env.get(name)}));
