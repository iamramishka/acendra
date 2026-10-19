import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHandler} from './handler.mjs';

const actor='19000000-0000-0000-0000-000000000001',session='19000000-0000-0000-0000-000000000002',otherActor='19000000-0000-0000-0000-000000000003';
const pid='19000000-0000-0000-0000-0000000000a1',pid2='19000000-0000-0000-0000-0000000000a2',cid='19000000-0000-0000-0000-0000000000c1';
const jwt=(claims={})=>'x.'+Buffer.from(JSON.stringify({sub:actor,session_id:session,role:'authenticated',aal:'aal2',...claims})).toString('base64url')+'.x';
const env=k=>({SUPABASE_URL:'https://synthetic.invalid',SUPABASE_ANON_KEY:'synthetic-public',SUPABASE_SERVICE_ROLE_KEY:'synthetic-secret'})[k];
const listBody=(o={})=>({mode:'list',page_size:20,cursor:null,status:null,method:null,from:null,to:null,order_number_prefix:null,...o});
const req=(body=listBody(),token=jwt(),method='POST')=>new Request('https://function.invalid',{method,headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},body:method==='POST'?JSON.stringify(body):undefined});
const item=(o={})=>({payment_id:pid,order_id:pid,order_number:'ORD-1',course_id:cid,course_title:'Synthetic course',amount_minor:'499900',currency_code:'LKR',method:'bank_transfer',status:'processing',created_at:'2026-10-15T07:45:00.123456Z',updated_at:'2026-10-15T08:10:00.000000Z',settled_at:null,...o});
const counts=(o={})=>({pending:'3',processing:'2',approved:'40',rejected:'5',total:'50',...o});
const listResult=(o={})=>({items:[item()],has_more:false,counts:counts(),as_of:'2026-10-18T05:00:00.000001Z',count_as_of:'2026-10-18T05:00:00.000001Z',...o});
// Fake backend: Auth user lookup, then RPC. Records every call and refuses any non-reporting URL.
function backend({rpc=()=>listResult(),user={id:actor},rpcStatus=200}={}){
 const calls=[];
 const fetch=async(url,o={})=>{
  calls.push({url,o});
  if(url.endsWith('/auth/v1/user'))return Response.json(user,{status:user?.id?200:401});
  assert.match(url,/\/rest\/v1\/rpc\/csapaylist_admin_payment_(list|detail)$/);
  return Response.json(rpc(JSON.parse(o.body),url),{status:rpcStatus});
 };
 return {fetch,calls,rpcCalls:()=>calls.filter(c=>c.url.includes('/rpc/'))};
}
const make=(b,extra={})=>createHandler({env,enabled:true,fetch:b.fetch,...extra});
const errorCode=async r=>(await r.json()).error?.code;

test('production default is disabled for every method and body without any backend call',async()=>{
 const h=createHandler({env,fetch:()=>{throw Error('unexpected');}});
 for(const r of [req(),req({junk:1}),req(listBody(),jwt(),'GET'),new Request('https://function.invalid',{method:'OPTIONS',headers:{Origin:'https://evil.invalid'}})]){
  const res=await h(r);assert.equal(res.status,503);assert.equal(await errorCode(res),'REPORTING_UNAVAILABLE');assert.equal(res.headers.get('Cache-Control'),'no-store');
 }
});
test('production index.ts uses the explicit server release switch',()=>{
 const src=readFileSync(new URL('./index.ts',import.meta.url),'utf8');
 assert.match(src,/enabled\s*:\s*reportingEnabled\(env, 'ACENDRA_ADMIN_PAYMENT_LIST_ENABLED'\)/);assert.doesNotMatch(src,/enabled\s*:\s*true/);
});

test('origin, method, media type and auth header are enforced before any backend call',async()=>{
 const h=createHandler({env,enabled:true,fetch:()=>{throw Error('unexpected');}});
 let r=req();r.headers.set('Origin','https://evil.invalid');assert.equal((await h(r)).status,403);
 r=req();r.headers.set('Origin','');assert.equal((await h(r)).status,403);
 assert.equal((await h(req(listBody(),jwt(),'GET'))).status,405);
 r=req();r.headers.set('Content-Type','text/plain');assert.equal((await h(r)).status,415);
 r=req();r.headers.delete('Authorization');assert.equal((await h(r)).status,401);
 const pre=new Request('https://function.invalid',{method:'OPTIONS',headers:{Origin:'http://127.0.0.1:8080','Access-Control-Request-Method':'POST','Access-Control-Request-Headers':'authorization, content-type'}});
 const pr=await h(pre);assert.equal(pr.status,204);assert.equal(pr.headers.get('Access-Control-Allow-Origin'),'http://127.0.0.1:8080');
 const bad=new Request('https://function.invalid',{method:'OPTIONS',headers:{Origin:'http://127.0.0.1:8080','Access-Control-Request-Method':'POST','Access-Control-Request-Headers':'x-evil'}});
 assert.equal((await h(bad)).status,403);
});

const invalid=[
 ['unknown key',{...listBody(),extra:1}],['missing key',(()=>{const b=listBody();delete b.cursor;return b;})()],['null body',null],['array body',[]],
 ['bad mode',listBody({mode:'export'})],['page_size 0',listBody({page_size:0})],['page_size 51',listBody({page_size:51})],['page_size string',listBody({page_size:'20'})],['page_size fraction',listBody({page_size:1.5})],
 ['bad status',listBody({status:'refunded'})],['bad method',listBody({method:'stripe'})],['admin_grant method',listBody({method:'admin_grant'})],
 ['from only',listBody({from:'2026-01-01'})],['to only',listBody({to:'2026-01-01'})],['to before from',listBody({from:'2026-01-02',to:'2026-01-01'})],
 ['span 367 days',listBody({from:'2025-01-01',to:'2026-01-03'})],['impossible date',listBody({from:'2026-02-30',to:'2026-03-01'})],['bad date format',listBody({from:'01/01/2026',to:'2026-01-02'})],
 ['prefix wildcard',listBody({order_number_prefix:'ORD%'})],['prefix space',listBody({order_number_prefix:'ORD 1'})],['prefix empty',listBody({order_number_prefix:''})],['prefix 41 chars',listBody({order_number_prefix:'A'.repeat(41)})],['prefix email',listBody({order_number_prefix:'a@b.c'})],
 ['cursor number',listBody({cursor:5})],['cursor too long',listBody({cursor:'A'.repeat(513)})],
 ['detail bad uuid',{mode:'detail',payment_id:'nope'}],['detail extra key',{mode:'detail',payment_id:pid,x:1}],['detail missing id',{mode:'detail'}],['oversized body',listBody({order_number_prefix:'A'.repeat(9000)})],
];
for(const [name,body] of invalid)test('invalid request is rejected before any backend call: '+name,async()=>{
 const b=backend();const r=await make(b)(req(body));assert.equal(r.status,400);assert.equal(await errorCode(r),'INVALID_REQUEST');assert.equal(b.calls.length,0);
});
test('a 366-day inclusive window is accepted (span limit matches admin-financial-report)',async()=>{
 const b=backend();const r=await make(b)(req(listBody({from:'2025-01-01',to:'2026-01-01',order_number_prefix:'Ord-12'})));assert.equal(r.status,200);
});

test('authentication failures never reach the privileged RPC',async()=>{
 for(const [label,b,token] of [
  ['rejected token',backend({user:{}}),jwt()],['anonymous',backend({user:{id:actor,is_anonymous:true}}),jwt()],['sub mismatch',backend({user:{id:otherActor}}),jwt()],
  ['bad aal claim',backend(),jwt({aal:'forged'})],['non-authenticated role',backend(),jwt({role:'service_role'})],['missing session claim',backend(),jwt({session_id:'x'})],['malformed jwt',backend(),'notajwt'],
 ]){const r=await make(b)(req(listBody(),token));assert.equal(r.status,401,label);assert.equal(await errorCode(r),'AUTH_REQUIRED',label);assert.equal(b.rpcCalls().length,0,label);}
});
test('AAL1 session is denied before the RPC (finance and super_admin require AAL2)',async()=>{
 const b=backend();const r=await make(b)(req(listBody(),jwt({aal:'aal1'})));assert.equal(r.status,403);assert.equal(await errorCode(r),'ADMIN_PERMISSION_REQUIRED');assert.equal(b.rpcCalls().length,0);
});
test('RPC receives only the verified actor, session, AAL and validated filters; service key only',async()=>{
 const b=backend();const body=listBody({page_size:5,status:'processing',method:'bank_transfer',from:'2026-10-01',to:'2026-10-18',order_number_prefix:'ord-1'});
 const r=await make(b)(req(body));assert.equal(r.status,200);
 const [c]=b.rpcCalls();assert.ok(c.url.endsWith('/rpc/csapaylist_admin_payment_list'));
 assert.deepEqual(JSON.parse(c.o.body),{p_actor:actor,p_session_id:session,p_aal:'aal2',p_page_size:5,p_after_created_at:null,p_after_id:null,p_as_of:null,p_status:'processing',p_method:'bank_transfer',p_from:'2026-10-01',p_to:'2026-10-18',p_prefix:'ord-1'});
 assert.equal(c.o.headers.Authorization,'Bearer synthetic-secret');
 assert.ok(!JSON.stringify(c.o).includes(jwt()));
});
test('actor identifiers supplied in the body are rejected, not trusted',async()=>{
 const b=backend();const r=await make(b)(req({...listBody(),p_actor:otherActor}));assert.equal(r.status,400);assert.equal(b.calls.length,0);
});

test('successful list returns exactly the allowlisted wire shape',async()=>{
 const b=backend();const r=await make(b)(req());assert.equal(r.status,200);assert.equal(r.headers.get('Cache-Control'),'no-store');
 const {data}=await r.json();
 assert.deepEqual(Object.keys(data).sort(),['as_of','count_as_of','count_basis','counts','items','next_cursor']);
 assert.deepEqual(Object.keys(data.items[0]).sort(),['amount_minor','course_id','course_title','created_at','currency_code','method','order_id','order_number','payment_id','settled_at','status','updated_at']);
 assert.equal(data.next_cursor,null);assert.equal(data.count_basis,'current_snapshot');assert.deepEqual(data.counts,counts());
 assert.equal(data.count_as_of,data.as_of);
});

test('continuation preserves creation cutoff but returns current counts and their snapshot time',async()=>{
 const cutoff='2026-10-18T05:00:00.000001Z',current='2026-10-18T05:01:00.000002Z';
 const laterCounts=counts({processing:'1',approved:'41'});
 const b=backend({rpc:a=>a.p_after_id
  ?listResult({items:[item({status:'approved',settled_at:current})],counts:laterCounts,as_of:a.p_as_of,count_as_of:current})
  :listResult({has_more:true})});
 const h=make(b,{now:()=>Date.parse('2026-10-18T05:01:00Z')});
 const first=await (await h(req(listBody({page_size:1})))).json();
 assert.equal(first.data.count_as_of,cutoff);
 const response=await h(req(listBody({page_size:1,cursor:first.data.next_cursor})));
 assert.equal(response.status,200);
 const {data}=await response.json();
 assert.equal(data.as_of,cutoff);assert.equal(data.count_as_of,current);
 assert.deepEqual(data.counts,laterCounts);assert.equal(data.items[0].status,'approved');
});

test('missing, malformed or earlier count snapshot timestamps fail closed',async()=>{
 for(const value of [undefined,null,'yesterday','2026-10-18T04:59:59.999999Z']){
  const r=await make(backend({rpc:()=>listResult({count_as_of:value})}))(req());
  assert.equal(r.status,503);assert.equal(await errorCode(r),'REPORTING_UNAVAILABLE');
 }
});
test('large and zero amounts survive as exact decimal strings; numbers and overflow fail closed',async()=>{
 for(const amount of ['0','9007199254740993','9223372036854775807']){
  const b=backend({rpc:()=>listResult({items:[item({amount_minor:amount})]})});const r=await make(b)(req());assert.equal(r.status,200);assert.equal((await r.json()).data.items[0].amount_minor,amount);
 }
 const total={pending:'9223372036854775806',processing:'1',approved:'0',rejected:'0',total:'9223372036854775807'};
 const big=await make(backend({rpc:()=>listResult({counts:total})}))(req());assert.equal(big.status,200);assert.deepEqual((await big.json()).data.counts,total);
 for(const amount of [499900,'9223372036854775808','-1','01','1.5',' 1',null]){
  const r=await make(backend({rpc:()=>listResult({items:[item({amount_minor:amount})]})}))(req());assert.equal(r.status,503,String(amount));assert.equal(await errorCode(r),'REPORTING_UNAVAILABLE');
 }
});
test('counts must be decimal strings that sum to total',async()=>{
 for(const bad of [counts({total:'51'}),counts({pending:3}),counts({pending:'-1'}),{pending:'1',processing:'1',approved:'1',rejected:'1'},{...counts(),refunded:'0'}]){
  const r=await make(backend({rpc:()=>listResult({counts:bad})}))(req());assert.equal(r.status,503);
 }
});
test('privacy: unexpected fields from the backend fail closed and never reach the body',async()=>{
 for(const extra of [{receipt_storage_path:'private/receipts/SECRET-PATH.pdf'},{student_email:'secret@student.invalid'},{provider_session_id:'SECRET-SESSION'},{public_rejection_reason:'SECRET-REASON'},{external_settlement_id:'SECRET-SETTLE'}]){
  const r=await make(backend({rpc:()=>listResult({items:[item(extra)]})}))(req());const text=await r.text();
  assert.equal(r.status,503);assert.ok(!text.includes('SECRET'));
 }
 const r=await make(backend({rpc:()=>listResult({receipts:'SECRET-TOP'})}))(req());assert.equal(r.status,503);assert.ok(!(await r.text()).includes('SECRET'));
});
test('invalid statuses, methods, currencies, timestamps and ids from backend fail closed',async()=>{
 for(const bad of [{status:'refunded'},{status:'paid'},{status:null},{method:'admin_grant'},{currency_code:'USD'},{created_at:'yesterday'},{settled_at:'x'},{payment_id:'nope'},{order_number:''},{course_title:5},{status:'approved',settled_at:null},{status:'processing',settled_at:'2026-10-16T01:00:00.000000Z'}]){
  const r=await make(backend({rpc:()=>listResult({items:[item(bad)]})}))(req());assert.equal(r.status,503,JSON.stringify(bad));
 }
 const ok=await make(backend({rpc:()=>listResult({items:[item({status:'approved',settled_at:'2026-10-16T01:00:00.000000Z'})]})}))(req());assert.equal(ok.status,200);
});
test('backend returning more rows than page_size fails closed',async()=>{
 const r=await make(backend({rpc:()=>listResult({items:[item(),item({payment_id:pid2,order_id:pid2})]})}))(req(listBody({page_size:1})));assert.equal(r.status,503);
});

test('error codes are mapped, bounded and never expose backend text',async()=>{
 for(const [code,status,pub] of [['42501',403,'ADMIN_PERMISSION_REQUIRED'],['22023',400,'INVALID_REQUEST'],['55000',503,'REPORTING_UNAVAILABLE'],['XX000',503,'REPORTING_UNAVAILABLE'],['P0002',503,'REPORTING_UNAVAILABLE']]){
  const b=backend({rpc:()=>({code,message:'PRIVATE order 123 receipt path secret@x.invalid'}),rpcStatus:400});
  const r=await make(b)(req());const text=await r.text();assert.equal(r.status,status,code);assert.equal(JSON.parse(text).error.code,pub);assert.ok(!text.includes('PRIVATE'));
 }
});
test('upstream failure and missing configuration are generic 503 SERVICE_UNAVAILABLE',async()=>{
 let r=await createHandler({env,enabled:true,fetch:async()=>{throw Error('PRIVATE network detail');}})(req());assert.equal(r.status,503);const t=await r.text();assert.ok(!t.includes('PRIVATE'));assert.equal(JSON.parse(t).error.code,'SERVICE_UNAVAILABLE');
 r=await createHandler({env:()=>undefined,enabled:true,fetch:()=>{throw Error('unexpected');}})(req());assert.equal(r.status,503);assert.equal(await errorCode(r),'SERVICE_UNAVAILABLE');
});
test('oversized backend response is rejected',async()=>{
 const r=await make(backend({rpc:()=>({padding:'x'.repeat(140000)})}))(req());assert.equal(r.status,503);assert.equal(r.headers.get('Cache-Control'),'no-store');
});

test('pagination: cursor is issued only when more rows exist and continues from the last row',async()=>{
 const last=item({payment_id:pid2,order_id:pid2,created_at:'2026-10-14T00:00:00.000007Z'});
 const b=backend({rpc:a=>a.p_after_id?listResult({items:[item()],as_of:a.p_as_of}):listResult({items:[item(),last],has_more:true})});
 const h=make(b,{now:()=>Date.parse('2026-10-18T05:01:00Z')});
 const first=(await (await h(req(listBody({page_size:2})))).json()).data;assert.equal(typeof first.next_cursor,'string');assert.ok(first.next_cursor.length<=512);
 const second=await h(req(listBody({page_size:2,cursor:first.next_cursor})));assert.equal(second.status,200);
 const args=JSON.parse(b.rpcCalls()[1].o.body);
 assert.equal(args.p_after_created_at,'2026-10-14T00:00:00.000007Z');assert.equal(args.p_after_id,pid2);assert.equal(args.p_as_of,first.as_of);
 assert.equal((await second.json()).data.next_cursor,null);
});
async function firstCursor(h,body=listBody({page_size:2}),token=jwt()){
 const r=await h(req(body,token));return (await r.json()).data.next_cursor;
}
const paged=(extra={})=>backend({rpc:()=>listResult({items:[item(),item({payment_id:pid2,order_id:pid2})],has_more:true,...extra})});
test('cursor bound to filters: reuse with different filters is rejected before the RPC',async()=>{
 const b=paged();const h=make(b,{now:()=>Date.parse('2026-10-18T05:01:00Z')});const cursor=await firstCursor(h,listBody({page_size:2,status:'processing'}));
 const n=b.rpcCalls().length;
 for(const changed of [{status:'pending'},{status:null},{method:'online'},{from:'2026-10-01',to:'2026-10-02'},{order_number_prefix:'ORD'}]){
  const r=await h(req(listBody({page_size:2,status:'processing',cursor,...changed})));assert.equal(r.status,400,JSON.stringify(changed));assert.equal(await errorCode(r),'INVALID_REQUEST');
 }
 assert.equal(b.rpcCalls().length,n);
 assert.equal((await h(req(listBody({page_size:2,status:'processing',cursor})))).status,200);
});
test('tampered, truncated, foreign-actor and expired cursors are rejected',async()=>{
 let t=Date.parse('2026-10-18T05:00:00Z');const b=paged();const h=make(b,{now:()=>t});
 const cursor=await firstCursor(h);const [payload,mac]=cursor.split('.');
 const flipped=payload.slice(0,-2)+(payload.at(-2)==='A'?'B':'A')+payload.at(-1);
 const forged=Buffer.from(JSON.stringify({...JSON.parse(Buffer.from(payload,'base64url')),i:'19000000-0000-0000-0000-0000000000ff'})).toString('base64url');
 for(const bad of [flipped+'.'+mac,forged+'.'+mac,payload,payload+'.',mac,'x.y','....','A'.repeat(100)]){
  const r=await h(req(listBody({page_size:2,cursor:bad})));assert.equal(r.status,400,bad.slice(0,20));assert.equal(await errorCode(r),'INVALID_REQUEST');
 }
 const oh=make(backend({user:{id:otherActor}}),{now:()=>t});
 const foreign=await oh(req(listBody({page_size:2,cursor}),jwt({sub:otherActor})));assert.equal(foreign.status,400);
 t+=16*60*1000;assert.equal((await h(req(listBody({page_size:2,cursor})))).status,400);
});

test('detail mode: exact RPC arguments, wire shape, and 404 only after authorization',async()=>{
 const b=backend({rpc:()=>({item:item(),as_of:'2026-10-18T05:00:00.000001Z'})});
 const r=await make(b)(req({mode:'detail',payment_id:pid}));assert.equal(r.status,200);
 const [c]=b.rpcCalls();assert.ok(c.url.endsWith('/rpc/csapaylist_admin_payment_detail'));
 assert.deepEqual(JSON.parse(c.o.body),{p_actor:actor,p_session_id:session,p_aal:'aal2',p_payment_id:pid});
 const {data}=await r.json();assert.deepEqual(Object.keys(data).sort(),['as_of','item']);
 const nf=await make(backend({rpc:()=>({code:'P0002',message:'PRIVATE'}),rpcStatus:404}))(req({mode:'detail',payment_id:pid}));assert.equal(nf.status,404);assert.equal(await errorCode(nf),'RESOURCE_NOT_FOUND');
 const denied=await make(backend({rpc:()=>({code:'42501',message:'PRIVATE'}),rpcStatus:403}))(req({mode:'detail',payment_id:pid}));assert.equal(denied.status,403);
 const leak=await make(backend({rpc:()=>({item:item({student_email:'SECRET@x.invalid'}),as_of:'2026-10-18T05:00:00.000001Z'})}))(req({mode:'detail',payment_id:pid}));assert.equal(leak.status,503);assert.ok(!(await leak.text()).includes('SECRET'));
 const aal1=await make(backend())(req({mode:'detail',payment_id:pid},jwt({aal:'aal1'})));assert.equal(aal1.status,403);
});
test('handler is read-only: only Auth lookup and the two reporting RPCs are ever called',async()=>{
 const b=backend({rpc:(a,url)=>url.endsWith('_detail')?{item:item(),as_of:'2026-10-18T05:00:00.000001Z'}:listResult()});
 const h=make(b);await h(req());await h(req({mode:'detail',payment_id:pid}));
 for(const c of b.calls)assert.match(c.url,/\/auth\/v1\/user$|\/rpc\/csapaylist_admin_payment_(list|detail)$/);
});
