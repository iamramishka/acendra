import { createHandler } from '../admin-create-media-upload/handler.mjs';
import { inspectionRuntime } from '../admin-create-media-upload/inspection.mjs';
const env = (name: string) => Deno.env.get(name);
// Missing configuration or unavailable inspection fails closed.
Deno.serve(createHandler({ env, mode: 'finalize', ...inspectionRuntime(env) }));
