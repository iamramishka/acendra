import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {createHandler} from './handler.mjs';
const course='26700000-0000-0000-0000-000000000001',asset='26700000-0000-0000-0000-000000000002';
const bytes=new Uint8Array([137,80,78,71,13,10,26,10]);
const record={course_id:course,asset_id:asset,bucket:'course-media',path:course+'/thumbnails/'+asset+'.png',mime:'image/png',size:8,sha256:createHash('sha256').update(bytes).digest('hex')};
const env=k=>({SUPABASE_URL:'https://backend.invalid',SUPABASE_ANON_KEY:'public',SUPABASE_SERVICE_ROLE_KEY:'secret'})[k];
const req=()=>new Request('https://function.invalid?course_id='+course);

test('SDK binary preview negotiates octet stream only for verified sessions',async()=>{
 const actor='26700000-0000-0000-0000-000000000003';
 const claims={sub:actor,role:'authenticated',session_id:asset,aal:'aal1'};
 const token='x.'+Buffer.from(JSON.stringify(claims)).toString('base64url')+'.x';
 const h=createHandler({env,fetch:async url=>url.includes('/auth/')?Response.json({id:actor}):
 url.includes('/rpc/')?Response.json(record):new Response(bytes)});
 const r=await h(new Request(req(),{headers:{Authorization:'Bearer '+token,Accept:'application/octet-stream'}}));
 assert.equal(r.status,200);assert.equal(r.headers.get('Content-Type'),'application/octet-stream');
 assert.deepEqual(new Uint8Array(await r.arrayBuffer()),bytes);
 const publicResponse=await h(new Request(req(),{headers:{Accept:'application/octet-stream'}}));
 assert.equal(publicResponse.headers.get('Content-Type'),'image/png');
});
test('published artwork is proxied as bounded digest-verified bytes without exposing paths',async()=>{
 let calls=0;const h=createHandler({env,fetch:async(url,opts)=>{
 calls++;if(url.includes('/rpc/')){assert.equal(JSON.parse(opts.body).p_course,course);return Response.json(record);}
 return new Response(bytes,{headers:{'Content-Type':'image/png'}});
 }});
 const r=await h(req());assert.equal(r.status,200);assert.equal(r.headers.get('Cache-Control'),'no-store');
 assert.equal(r.headers.get('X-Content-Type-Options'),'nosniff');assert.deepEqual(new Uint8Array(await r.arrayBuffer()),bytes);assert.equal(calls,3);
});
test('draft missing pending rejected and revoked artwork produce safe missing response',async()=>{
 const h=createHandler({env,fetch:async()=>Response.json(null)});assert.equal((await h(req())).status,404);
});
for(const [name,override] of [['private lesson path',{path:course+'/lesson/'+asset+'.png'}],['wrong course',{course_id:asset}],['pdf',{mime:'application/pdf'}],['oversize',{size:5242881}],['digest',{sha256:'a'.repeat(64)}]]){
 test('cannot deliver '+name,async()=>{
 const h=createHandler({env,fetch:async url=>url.includes('/rpc/')?Response.json({...record,...override}):new Response(bytes)});
 assert.ok([404,503].includes((await h(req())).status));
 });
}
test('storage errors and truncated bytes cannot be served',async()=>{
 for(const stored of [new Response('',{status:503}),new Response(new Uint8Array([1]))]){
 const h=createHandler({env,fetch:async url=>url.includes('/rpc/')?Response.json(record):stored});
 assert.equal((await h(req())).status,503);
 }
});
test('invalid or anonymous bearer cannot become draft authority',async()=>{
 let calls=0;const h=createHandler({env,fetch:async()=>{calls++;return Response.json({},{status:401});}});
 const r=new Request(req(),{headers:{Authorization:'Bearer forged'}});assert.equal((await h(r)).status,401);assert.equal(calls,1);
});
test('strict query never accepts object paths or signed URL input',async()=>{
 let calls=0;const h=createHandler({env,fetch:async()=>{calls++;throw Error();}});
 assert.equal((await h(new Request('https://f.invalid?course_id='+course+'&path=secret'))).status,400);assert.equal(calls,0);
});

test('replacement or unpublish during storage IO prevents stale artwork response',async()=>{
 let resolves=0;const h=createHandler({env,fetch:async url=>url.includes('/rpc/')?
 Response.json(++resolves===1?record:null):new Response(bytes)});
 assert.equal((await h(req())).status,404);
});
test('oversized streaming storage response is canceled',async()=>{
 let canceled=false;const h=createHandler({env,fetch:async url=>url.includes('/rpc/')?
 Response.json(record):new Response(new ReadableStream({start(c){c.enqueue(new Uint8Array(9));},cancel(){canceled=true;}}))});
 assert.equal((await h(req())).status,503);assert.equal(canceled,true);
});
