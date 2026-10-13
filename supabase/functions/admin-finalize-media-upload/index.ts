import { createHandler } from '../admin-create-media-upload/handler.mjs';
// Finalization remains closed until trusted deployment code supplies approved policy and inspector.
Deno.serve(createHandler({ env: (name: string) => Deno.env.get(name), mode: 'finalize' }));
