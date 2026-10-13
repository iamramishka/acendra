import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from './handler.mjs';
const actor='17500000-0000-0000-0000-000000000001';
const target='17500000-0000-0000-0000-000000000002';
const body={student_id:target,role_code:'finance_admin',action:'grant',reason:'Synthetic authorized handoff',request_id:'17500000-0000-0000-0000-000000000003'};
const claims={sub:actor,role:'authenticated',aal:'aal2',session_id:'17500000-0000-0000-0000-000000000004'};
const env=name=>({SUPABASE_URL:'http://local',SUPABASE_ANON_KEY:'public-fixture',SUPABASE_SERVICE_ROLE_KEY:'private-fixture'})[name];
const incoming=(payload=JSON.stringify(body),c=claims)=>new Request('http://local/function',{method:'POST',headers:{Authorization:`Bearer h.${Buffer.from(JSON.stringify(c)).toString('base64url')}.s`,'Content-Type':'application/json'},body:payload});
const reply=data=>Response.json(data);
test('role request is byte bounded including chunked bodies before Auth or RPC',async()=>{
 const handler=createHandler({env,fetch:()=>assert.fail('oversized request must not authenticate or mutate')});
 const response=await handler(incoming(' '.repeat(100000)+JSON.stringify(body)));
 assert.equal(response.status,400);
});
test('malformed Auth identity and null verified claims are authentication failures without RPC',async()=>{
 for(const [user,c] of [[null,claims],[[],claims],[{id:actor},null]]){
  let calls=0;
  const handler=createHandler({env,fetch:async()=>{calls++;return reply(user);}});
  const response=await handler(incoming(undefined,c));
  assert.equal(response.status,401);assert.equal(calls,1);
 }
});
test('successful role RPC output omits undeclared private data',async()=>{
 const data={user_id:target,role_code:'finance_admin',action:'grant',status:'active',operation_status:'active',replayed:false,grant_id:'17500000-0000-0000-0000-000000000005',audit_id:'17500000-0000-0000-0000-000000000006'};
 const handler=createHandler({env,fetch:async(url,options)=>{
  assert.equal(options.redirect,'error','credentials cannot follow redirects');
  return reply(url.endsWith('/user')?{id:actor}:{...data,secret:'private-fixture',internal_notes:{personal:'sensitive'}});
 }});
 const response=await handler(incoming());assert.equal(response.status,200);
 assert.deepEqual((await response.json()).data,data);
});
test('invalid success envelopes never become role operation confirmations',async()=>{
 for(const data of [null,[],{error:'private-fixture'},'private-fixture']){
  const handler=createHandler({env,fetch:async url=>reply(url.endsWith('/user')?{id:actor}:data)});
  const response=await handler(incoming());assert.equal(response.status,503);
  assert.ok(!(await response.text()).includes('private-fixture'));
 }
});


test('role result must confirm the requested subject, role and operation',async()=>{
 const valid={user_id:target,role_code:body.role_code,action:body.action,status:'active',operation_status:'active',replayed:false,grant_id:'17500000-0000-0000-0000-000000000005',audit_id:'17500000-0000-0000-0000-000000000006'};
 for(const patch of [{user_id:actor},{role_code:'super_admin'},{action:'revoke'},{replayed:'false'},{grant_id:null},{audit_id:{notes:'private-fixture'}},{operation_status:'revoked'}]){
  const handler=createHandler({env,fetch:async url=>reply(url.endsWith('/user')?{id:actor}:{...valid,...patch})});
  const response=await handler(incoming());assert.equal(response.status,503);
  assert.ok(!(await response.text()).includes('private-fixture'));
 }
});

test('byte limit cancels chunked request readers rather than trusting Content-Length',async()=>{
 let cancelled=false;
 const stream=new ReadableStream({start(controller){controller.enqueue(new TextEncoder().encode(' '.repeat(8193)));},cancel(){cancelled=true;}});
 const req=new Request('http://local/function',{method:'POST',headers:{Authorization:'Bearer h.p.s','Content-Type':'application/json','Content-Length':'1'},body:stream,duplex:'half'});
 const handler=createHandler({env,fetch:()=>assert.fail('oversized stream cannot reach Auth')});
 assert.equal((await handler(req)).status,400);assert.equal(cancelled,true);
});
