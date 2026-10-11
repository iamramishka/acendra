import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from './handler.mjs';
const actor='07500000-0000-0000-0000-000000000001';
const payload={student_id:'07500000-0000-0000-0000-000000000002',role_code:'finance_admin',action:'grant',reason:'Synthetic denial test',request_id:'07500000-0000-0000-0000-000000000003'};
const env=name=>({SUPABASE_URL:'http://local',SUPABASE_ANON_KEY:'public-fixture',SUPABASE_SERVICE_ROLE_KEY:'private-fixture'})[name];
const claims={sub:actor,role:'authenticated',aal:'aal2',session_id:'07500000-0000-0000-0000-000000000004'};
const token=value=>`header.${Buffer.from(JSON.stringify(value)).toString('base64url')}.signature`;
const incoming=bearer=>new Request('http://local/function',{method:'POST',headers:{Authorization:`Bearer ${bearer}`,'Content-Type':'application/json'},body:JSON.stringify(payload)});
test('authentication rejection prevents every privileged mutation request',async()=>{
 for(const [name,user,bearer,expected] of [
  ['anonymous identity',{id:actor,is_anonymous:true},token(claims),401],
  ['missing verified identity',{},token(claims),401],
  ['foreign verified identity',{id:payload.student_id},token(claims),401],
  ['missing session',{id:actor},token({...claims,session_id:null}),401],
  ['invalid session',{id:actor},token({...claims,session_id:'forged'}),401],
  ['non-user JWT role',{id:actor},token({...claims,role:'service_role'}),401],
  ['missing assurance',{id:actor},token({...claims,aal:null}),403],
  ['insufficient assurance',{id:actor},token({...claims,aal:'aal1'}),403],
  ['malformed claims',{id:actor},'header.invalid-base64!.signature',401],
 ]){
  const calls=[];
  const handler=createHandler({env,fetch:async(url,options)=>{
   calls.push({url,options});
   assert.equal(url,'http://local/auth/v1/user',`${name}: no privileged RPC`);
   return new Response(JSON.stringify(user),{status:200});
  }});
  const response=await handler(incoming(bearer));
  assert.equal(response.status,expected,name);
  assert.equal(calls.length,1,name);
  assert.equal(calls[0].options.headers.Authorization,`Bearer ${bearer}`,name);
  assert.equal(calls[0].options.headers.apikey,'public-fixture',name);
  assert.equal(response.headers.get('Cache-Control'),'no-store',name);
  assert.ok(!(await response.text()).includes('private-fixture'),name);
 }
});
test('missing authentication and unsupported methods make no outbound calls',async()=>{
 const handler=createHandler({env,fetch:()=>assert.fail('No authentication or privileged request permitted')});
 for(const authorization of [null,'Basic forged','Bearer '+'a'.repeat(16385)]){
  const request=new Request('http://local/function',{method:'POST',headers:{'Content-Type':'application/json',...(authorization===null?{}:{Authorization:authorization})},body:JSON.stringify(payload)});
  assert.equal((await handler(request)).status,401);
 }
 for(const method of ['GET','PUT','PATCH','DELETE']) assert.equal((await handler(new Request('http://local/function',{method}))).status,405);
});
test('rejected Auth responses cannot authorize grants or revocations',async()=>{
 for(const action of ['grant','revoke']) for(const status of [401,403,500]){
  let calls=0;
  const handler=createHandler({env,fetch:async url=>{
   calls++;
   assert.equal(url,'http://local/auth/v1/user');
   return new Response(JSON.stringify({id:actor,detail:'private-fixture'}),{status});
  }});
  const request=incoming(token(claims));
  const response=await handler(new Request(request.url,{method:'POST',headers:request.headers,body:JSON.stringify({...payload,action})}));
  assert.equal(response.status,401);
  assert.equal(calls,1);
  assert.ok(!(await response.text()).includes('private-fixture'));
 }
});
