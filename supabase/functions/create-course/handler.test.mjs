import test from 'node:test';
import assert from 'node:assert/strict';
import {createHandler} from './handler.mjs';
const actor='08900000-0000-0000-0000-000000000001',session='08900000-0000-0000-0000-000000000002';
const body={request_id:'08900000-0000-0000-0000-000000000003',title:'Synthetic',slug:'synthetic'};
const token=(claims={})=>'x.'+Buffer.from(JSON.stringify({sub:actor,session_id:session,role:'authenticated',aal:'aal1',...claims})).toString('base64url')+'.x';
const env=k=>({SUPABASE_URL:'https://synthetic.invalid',SUPABASE_ANON_KEY:'public-synthetic',SUPABASE_SERVICE_ROLE_KEY:'private-synthetic'})[k];
const req=(payload=body,jwt=token())=>new Request('https://function.invalid',{method:'POST',headers:{Authorization:'Bearer '+jwt},body:JSON.stringify(payload)});
test('handler exports callable creation entry',()=>assert.equal(typeof createHandler,'function'));
test('verified content manager aal1 reaches bounded RPC with actor from Auth',async()=>{
 let call=0;
 const handler=createHandler({env,fetch:async(url,opts)=>{
  if(call++===0)return Response.json({id:actor});
  assert.ok(url.endsWith('/rpc/csa089_create_course'));
  const data=JSON.parse(opts.body);assert.deepEqual(data,{p_actor:actor,p_session_id:session,p_aal:'aal1',p_request_id:body.request_id,p_payload:{title:'Synthetic',slug:'synthetic'}});
  return Response.json({course_id:actor,status:'draft'});
 }});
 const result=await handler(req());assert.equal(result.status,200);assert.equal(call,2);
});
for(const field of ['price_minor','status','created_by','staff_role','role'])test('reject forbidden '+field,async()=>{
 let calls=0;const handler=createHandler({env,fetch:async()=>{calls++;return Response.json({});}});
 assert.equal((await handler(req({...body,[field]:'forged'}))).status,400);assert.equal(calls,0);
});
test('unauthorized Auth token never reaches mutation',async()=>{
 let calls=0;const handler=createHandler({env,fetch:async()=>{calls++;return Response.json({}, {status:401});}});
 assert.equal((await handler(req())).status,401);assert.equal(calls,1);
});
test('verified user mismatching supplied subject denied',async()=>{
 const handler=createHandler({env,fetch:async()=>Response.json({id:session})});assert.equal((await handler(req())).status,401);
});
test('database current authorization rejection is generic',async()=>{
 let calls=0;const handler=createHandler({env,fetch:async()=>calls++===0?Response.json({id:actor}):Response.json({code:'42501',message:'secret database detail'},{status:400})});
 const r=await handler(req());assert.equal(r.status,403);assert.ok(!(await r.text()).includes('secret'));
});
test('malformed/unsupported assurance denied',async()=>{
 const handler=createHandler({env,fetch:async()=>Response.json({id:actor})});assert.equal((await handler(req(body,token({aal:'forged'})))).status,401);
});
test('unapproved origin denied before auth',async()=>{
 const handler=createHandler({env,fetch:()=>{throw Error('must not fetch');}});const r=req();r.headers.set('Origin','https://evil.invalid');assert.equal((await handler(r)).status,403);
});
