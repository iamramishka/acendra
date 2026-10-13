import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorkerRuntime} from './pdf_worker_runtime.mjs';
const env=name=>({SUPABASE_URL:'https://example.supabase.co',SUPABASE_SERVICE_ROLE_KEY:'synthetic',PDF_WORKER_PYTHON:'/trusted/python',PDF_WORKER_FONT:'/trusted/font.ttf'})[name];
test('runtime refuses missing configuration and unsafe service URLs',()=>{
 for(const url of ['http://example.com','https://user:password@example.com','https://example.com/path','https://example.com/?token=unsafe'])assert.throws(()=>createWorkerRuntime({env:name=>name==='SUPABASE_URL'?url:env(name)}));
 assert.throws(()=>createWorkerRuntime({env:()=>undefined}));
});
test('worker RPC uses private authenticated bounded transport',async()=>{
 let seen;const runtime=createWorkerRuntime({env,fetch:async(url,options)=>{seen={url,options};return Response.json(null);}});
 assert.equal(await runtime.rpc('csa148_claim_pdf_job'),null);
 assert.equal(seen.options.redirect,'error');assert.ok(seen.options.signal);assert.equal(seen.options.headers.Authorization,'Bearer synthetic');
});
test('oversized RPC bodies fail closed before buffering',async()=>{
 let cancelled=false;const response=new Response(new ReadableStream({start(c){c.enqueue(new Uint8Array(16385));},cancel(){cancelled=true;}}));
 await assert.rejects(createWorkerRuntime({env,fetch:async()=>response}).rpc('csa148_claim_pdf_job'));
 assert.equal(cancelled,true);
});
test('storage writes are immutable and redirects forbidden',async()=>{
 let options;const runtime=createWorkerRuntime({env,fetch:async(url,input)=>{options=input;return new Response(null,{status:409});}});
 assert.deepEqual(await runtime.storage.upload({path:'derivatives/synthetic.pdf',bytes:new Uint8Array([1])}),{created:false});
 assert.equal(options.headers['x-upsert'],'false');assert.equal(options.redirect,'error');
});
