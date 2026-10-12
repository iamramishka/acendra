import test from 'node:test';
import assert from 'node:assert/strict';
import {createHandler as roles} from '../supabase/functions/admin-assign-user-role/handler.mjs';
import {createHandler as media} from '../supabase/functions/admin-create-media-upload/handler.mjs';
import {createHandler as publish} from '../supabase/functions/admin-publish-course/handler.mjs';
import {createHandler as enrollments} from '../supabase/functions/admin-enrollments/handler.mjs';
import {createHandler as entitlements} from '../supabase/functions/admin-entitlements/handler.mjs';
import {createHandler as dashboard} from '../supabase/functions/admin-dashboard-stats/handler.mjs';
import {createHandler as financial} from '../supabase/functions/admin-financial-report/handler.mjs';
import {createHandler as bank} from '../supabase/functions/admin-review-bank-transfer/handler.mjs';
import {createHandler as course} from '../supabase/functions/create-course/handler.mjs';

const actor='17600000-0000-0000-0000-000000000001';
const target='17600000-0000-0000-0000-000000000002';
const session='17600000-0000-0000-0000-000000000003';
const requestId='17600000-0000-0000-0000-000000000004';
const claims={sub:actor,role:'authenticated',session_id:session,aal:'aal2'};
const token=c=>`synthetic.${Buffer.from(JSON.stringify(c)).toString('base64url')}.synthetic`;
const secret='CSA176_PRIVATE_SERVICE_KEY';
const privateDetail='CSA176_PRIVATE_BANK_RECEIPT_PATH_AND_SQL_DIAGNOSTIC';
const env=n=>({SUPABASE_URL:'https://database.invalid',SUPABASE_ANON_KEY:'synthetic-public',SUPABASE_SERVICE_ROLE_KEY:secret})[n];
const policy={reference:'csa176-synthetic-policy',timeoutMs:1000,maxBytes:{course_pdf:1000,lesson_image:1000}};
const endpoints=[
 ['admin-assign-user-role',roles,{student_id:target,role_code:'finance_admin',action:'grant',reason:'Synthetic denial',request_id:requestId},{},true,'csa073_change_role'],
 ['admin-create-media-upload',media,{request_id:requestId,course_id:target,lesson_id:target,asset_type:'course_pdf',file_name:'lesson.pdf',content_type:'application/pdf',size_bytes:9},{policy,inspector:async()=>assert.fail('Denied upload must not inspect')},false,'csa164_prepare_media_upload'],
 ['admin-finalize-media-upload',media,{asset_id:target,request_id:requestId},{mode:'finalize',policy,inspector:async()=>assert.fail('Denied upload must not inspect')},false,'csa164_get_media_upload'],
 ['admin-publish-course',publish,{course_id:target,expected_updated_at:'2026-10-12T00:00:00Z',action:'publish'},{enabled:true},true,'csa165_publish_course'],
 ['admin-enrollments',enrollments,{user_id:target,after_id:null,limit:20},{enabled:true},true,'csa168_list_enrollments'],
 ['admin-entitlements',entitlements,{action:'grant',user_id:target,course_id:target,reason:'Synthetic denial',expires_at:null},{enabled:true},true,'csa116_grant_admin'],
 ['admin-entitlements/revoke',entitlements,{action:'revoke',user_id:target,course_id:null,grant_id:null,scope:'account',reason:'Synthetic denial'},{enabled:true},true,'csa118_revoke_access'],
 ['admin-entitlements/release',entitlements,{action:'release',restriction_id:target,reason:'Synthetic denial'},{enabled:true},true,'csa118_release_restriction'],
 ['admin-dashboard-stats',dashboard,{period:'last_30_days'},{enabled:true},false,'csa158_dashboard_stats'],
 ['admin-financial-report',financial,{from:'2026-10-01',to:'2026-10-12',currency_code:'LKR'},{enabled:true},false,'csa172_financial_report'],
 ['admin-review-bank-transfer',bank,{submission_id:target,decision:'reject',rejection_reason:'Synthetic denial',private_notes:'Synthetic private note'},{bankReviewEnabled:true},true,'csa112_review_bank_transfer'],
 ['create-course',course,{request_id:requestId,title:'Synthetic denied draft',slug:'csa176-denied'},{},false,'csa089_create_course'],
];
endpoints.push(['admin-assign-user-role/revoke',roles,{...endpoints[0][2],action:'revoke'},{},true,'csa073_change_role']);
endpoints.push(['admin-publish-course/unpublish',publish,{...endpoints[3][2],action:'unpublish'},{enabled:true},true,'csa165_publish_course']);
endpoints.push(['admin-review-bank-transfer/approve',bank,{submission_id:target,decision:'approve',verified_credit:{bank_credit_confirmed:true,destination_account_id:target,bank_transaction_id:'CSA176-SYNTHETIC-CREDIT',amount_minor:'250000',currency:'LKR',settled_at:'2026-10-10T12:00:00Z',source:'bank_portal',order_reference:'ACD-SYNTHETIC'}},{bankReviewEnabled:true},true,'csa112_review_bank_transfer']);

function incoming(name,body,c=claims,authorization=`Bearer ${token(c)}`){
 return new Request(`https://functions.invalid/${name}`,{method:'POST',headers:{'Content-Type':'application/json','Idempotency-Key':'csa176-denied',...(authorization===null?{}:{Authorization:authorization})},body:JSON.stringify(body)});
}
async function checkResponse(response,status){
 assert.equal(response.status,status);
 assert.equal(response.headers.get('Cache-Control'),'no-store');
 const text=await response.text();
 assert.ok(!text.includes(secret));
 assert.ok(!text.includes(privateDetail));
 const json=JSON.parse(text);
 assert.equal(typeof json.error.code,'string');
 assert.equal(json.data,undefined);
}

for(const [name,factory,body,options,requiresMfa,rpc] of endpoints){
 test(`${name}: absent authentication makes no outbound request`,async()=>{
  const handler=factory({env,...options,fetch:async()=>assert.fail('No Auth, RPC, storage, or mutation allowed')});
  await checkResponse(await handler(incoming(name,body,claims,null)),401);
 });
 for(const [label,user,c,status] of [
  ['anonymous verified account',{id:actor,is_anonymous:true},claims,401],
  ['forged actor identity',{id:target},claims,401],
  ['service-role claim',{id:actor},{...claims,role:'service_role'},401],
  ['missing session',{id:actor},{...claims,session_id:null},401],
  ['missing assurance',{id:actor},{...claims,aal:null},requiresMfa?403:401],
 ]) test(`${name}: ${label} cannot reach privileged RPC`,async()=>{
  let count=0;
  const handler=factory({env,...options,fetch:async(url,opts)=>{
   count++;assert.equal(url,'https://database.invalid/auth/v1/user');
   assert.equal(opts.headers.Authorization,`Bearer ${token(c)}`);
   assert.equal(opts.headers.apikey,'synthetic-public');
   return Response.json(user);
  }});
  await checkResponse(await handler(incoming(name,body,c)),status);
  assert.equal(count,1);
 });
 test(`${name}: forged JWT rejected by Auth cannot authorize`,async()=>{
  let count=0;
  const handler=factory({env,...options,fetch:async url=>{
   count++;assert.equal(url,'https://database.invalid/auth/v1/user');
   return Response.json({id:actor,message:privateDetail},{status:401});
  }});
  await checkResponse(await handler(incoming(name,body,{...claims,user_role:'super_admin',app_metadata:{role:'super_admin'}})),401);
  assert.equal(count,1);
 });
 test(`${name}: trusted RPC denial with forged admin metadata is sanitized and terminal`,async()=>{
  const calls=[];
  const c={...claims,user_role:'super_admin',app_metadata:{role:'super_admin'}};
  const handler=factory({env,...options,fetch:async(url,opts)=>{
   calls.push(url);
   if(url.endsWith('/auth/v1/user'))return Response.json({id:actor,user_metadata:{role:'super_admin'}});
   assert.equal(url,`https://database.invalid/rest/v1/rpc/${rpc}`);
   const args=JSON.parse(opts.body);
   assert.equal(args.p_actor,actor);assert.equal(args.p_session_id,session);
   assert.equal(args.p_aal,'aal2');assert.equal(args.app_metadata,undefined);
   return Response.json({code:'42501',message:privateDetail,details:privateDetail,hint:secret},{status:403});
  }});
  await checkResponse(await handler(incoming(name,body,c)),403);
  assert.equal(calls.length,2,'No subsequent storage or privileged calls after denial');
 });
 if(requiresMfa)test(`${name}: MFA downgrade stops before privileged RPC`,async()=>{
  let calls=0;
  const handler=factory({env,...options,fetch:async url=>{
   calls++;assert.equal(url,'https://database.invalid/auth/v1/user');return Response.json({id:actor});
  }});
  await checkResponse(await handler(incoming(name,body,{...claims,aal:'aal1'})),403);
  assert.equal(calls,1);
 });
}
