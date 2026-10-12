import { createHandler } from './handler.mjs';
import { createStorage } from './storage.mjs';
import { createAuthorizer } from '../_shared/pdf/authorization.mjs';
const env = (name: string) => Deno.env.get(name);
// Activation requires approved private storage, worker orchestration and runtime gates.
Deno.serve(createHandler({ authorize: createAuthorizer({ env }), storage: createStorage({ env }), env, enabled: false }));
