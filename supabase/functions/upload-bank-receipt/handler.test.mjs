import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from './handler.mjs';
const actor='11111111-1111-4111-8111-111111111111', session='22222222-2222-4222-8222-222222222222', order='33333333-3333-4333-8333-333333333333', submission='44444444-4444-4444-8444-444444444444', asset='55555555-5555-4555-8555-555555555555';
const bytes=new Uint8Array([137,80,78,71,13,10,26,10,0]); // Synthetic signature, not a real parsed PNG.
const token='a.'+Buffer.from(JSON.stringify({sub:actor,role:'authenticated',session_id:session,aal:'aal1'})).toString('base64url')+'.c';
const request=(data=bytes,extra={})=>new Request('https://app.test/receipt',{method:'POST',headers:{Authorization:'Bearer '+token,'Content-Type':'image/png','X-Order-Id':order,'X-Receipt-Name':'receipt.png','Idempotency-Key':'key',...extra},body:data});
function fixture(options={}){
 const calls=[];let inspections=0;
 const inspector={policyReference:'synthetic-policy-v1',timeoutMs:1000,inspect:async({sha256,size,mime})=>{inspections++;return {safe:true,parseable:true,encrypted:false,withinResourceLimits:true,sha256,size,mime,policyReference:'synthetic-policy-v1',...options.inspection};}};
 const fetch=async(url,init)=>{calls.push({url,init});
  if(url.includes('/auth/'))return Response.json({id:actor});
  if(url.includes('csa108_'))return Response.json({upload_id:asset,submission_id:submission,receipt_asset_id:asset,bucket:'bank-receipts',object_path:`${actor}/${order}/${submission}/${asset}.png`,replayed:!!options.replayed,finalized:!!options.finalized,...options.prepared},{status:options.prepareStatus??200});
  if(url.includes('csa109_'))return Response.json({order_id:order,submission_id:submission,status:'submitted',replayed:!!options.replayed},{status:options.finalStatus??200});
  if(init.method==='POST')return Response.json(options.uploadError??{}, {status:options.uploadStatus??200});
  return new Response(options.stored??bytes,{status:options.readStatus??200,headers:{'Content-Type':'image/png'}});
 };
 const handler=createHandler({env:n=>({SUPABASE_URL:'https://db.test',SUPABASE_ANON_KEY:'public',SUPABASE_SERVICE_ROLE_KEY:'private'}[n]),fetch,receiptUploadsEnabled:options.enabled??true,inspector:options.noInspector?undefined:inspector});
 return {handler,calls,get inspections(){return inspections;}};
}
test('default disabled no external effects',async()=>{const f=fixture({enabled:false});assert.equal((await f.handler(request())).status,503);assert.equal(f.calls.length,0);});
test('valid synthetic upload verifies actual bytes before safe finalization',async()=>{const f=fixture();const r=await f.handler(request());assert.equal(r.status,201);const result=await r.json();assert.equal(result.data.status,'submitted');assert.ok(!JSON.stringify(result).includes('object_path'));assert.equal(f.inspections,2);assert.deepEqual(f.calls.map(c=>c.url.includes('/rpc/')?c.url.split('/').at(-1):c.url.includes('/auth/')?'auth':c.init.method),['auth','csa108_prepare_receipt','POST','GET','csa109_finalize_receipt']);assert.equal(f.calls[2].init.headers['x-upsert'],'false');for(const c of f.calls)assert.equal(c.init.redirect,'error');});
for(const [name,data,headers] of [['MIME spoof',bytes,{'Content-Type':'application/pdf'}],['extension spoof',bytes,{'X-Receipt-Name':'receipt.pdf'}],['unsafe path',bytes,{'X-Receipt-Name':'../receipt.png'}],['missing signature',new Uint8Array([1,2,3]),{}],['oversize',new Uint8Array(5242881),{}]])test('rejects '+name,async()=>{const f=fixture();assert.ok([400,413].includes((await f.handler(request(data,headers))).status));assert.equal(f.calls.length,0);});
for(const [name,inspection] of [['unsafe',{safe:false}],['encrypted',{encrypted:true}],['unparseable',{parseable:false}],['resource limit',{withinResourceLimits:false}],['wrong digest',{sha256:'0'.repeat(64)}],['wrong policy',{policyReference:'other'}]])test('fails closed inspector '+name,async()=>{const f=fixture({inspection});assert.equal((await f.handler(request())).status,422);assert.equal(f.calls.length,1);});
test('missing inspector fails before Auth',async()=>{const f=fixture({noInspector:true});assert.equal((await f.handler(request())).status,503);assert.equal(f.calls.length,0);});
test('storage digest mismatch never finalizes',async()=>{const f=fixture({stored:new Uint8Array([...bytes,1])});assert.equal((await f.handler(request())).status,409);assert.ok(!f.calls.some(c=>c.url.includes('csa109_')));});
test('finalized replay never overwrites',async()=>{const f=fixture({finalized:true,replayed:true});assert.equal((await f.handler(request())).status,200);assert.ok(!f.calls.some(c=>c.url.includes('/storage/')&&c.init.method==='POST'));});
test('upload collision reads reserved object and returns retry',async()=>{const f=fixture({uploadStatus:409,replayed:true});assert.equal((await f.handler(request())).status,200);});
test('foreign reserved path never touches storage',async()=>{const f=fixture({prepared:{object_path:`${order}/${order}/${submission}/${asset}.png`}});assert.equal((await f.handler(request())).status,503);assert.ok(!f.calls.some(c=>c.url.includes('/storage/')));});
test('cross-user order authorization denied before storage',async()=>{const f=fixture({prepareStatus:403,prepared:{code:'42501'}});assert.equal((await f.handler(request())).status,403);assert.ok(!f.calls.some(c=>c.url.includes('/storage/')));});
test('uncertain upload failure retains reservation without deletion',async()=>{const f=fixture({uploadStatus:500});assert.equal((await f.handler(request())).status,503);assert.ok(!f.calls.some(c=>c.init.method==='DELETE'||c.url.includes('csa109_')));});
test('missing object never finalizes',async()=>{const f=fixture({readStatus:404});assert.equal((await f.handler(request())).status,503);assert.ok(!f.calls.some(c=>c.url.includes('csa109_')));});
for (const [name, inspection] of [['wrong MIME',{mime:'application/pdf'}],['wrong size',{size:0}]]) test('rejects attestation '+name,async()=>{const f=fixture({inspection});assert.equal((await f.handler(request())).status,422);assert.equal(f.calls.length,1);});
test('bounds actual stored bytes despite metadata',async()=>{const f=fixture({stored:new Uint8Array(5242881)});assert.equal((await f.handler(request())).status,413);assert.ok(!f.calls.some(c=>c.url.includes('csa109_')));});
test('malformed token claims fail before inspection or prepare',async()=>{const f=fixture();assert.equal((await f.handler(request(bytes,{Authorization:'Bearer a.'+Buffer.from('null').toString('base64url')+'.c'}))).status,401);assert.equal(f.inspections,0);assert.equal(f.calls.length,1);});
test('finalization conflict retains evidence without deletion or grant',async()=>{const f=fixture({finalStatus:409});assert.equal((await f.handler(request())).status,503);assert.ok(!f.calls.some(c=>c.init.method==='DELETE'));});
test('same key changed bytes SQL conflict denies storage',async()=>{const f=fixture({prepareStatus:400,prepared:{code:'22023'}});assert.equal((await f.handler(request())).status,409);assert.ok(!f.calls.some(c=>c.url.includes('/storage/')));});

import { inspectReceipt, snapshotInspector, digest } from './validation.mjs';
test('inspection receives cloned bytes and fixed policy snapshot',async()=>{
 const original=bytes.slice();
 const sha256=digest(original);
 const source={policyReference:'original-policy',timeoutMs:1000,inspect:async input=>{
   input.bytes.fill(0);
   return {safe:true,parseable:true,encrypted:false,withinResourceLimits:true,sha256:input.sha256,size:input.size,mime:input.mime,policyReference:'original-policy'};
 }};
 const snapshot=snapshotInspector(source);
 source.policyReference='changed-policy';
 source.inspect=()=>{throw Error('changed implementation');};
 assert.equal(await inspectReceipt(snapshot,original,'image/png',sha256),'original-policy');
 assert.deepEqual(original,bytes);
});
test('inspector timeout fails closed',async()=>{
 const inspector=snapshotInspector({policyReference:'test',timeoutMs:5,inspect:()=>new Promise(()=>{})});
 await assert.rejects(inspectReceipt(inspector,bytes,'image/png',digest(bytes)),error=>error.code==='INSPECTION_FAILED');
});
test('inspector exceptions never leak details',async()=>{
 const inspector=snapshotInspector({policyReference:'test',timeoutMs:1000,inspect:()=>{throw Error('private receipt details');}});
 await assert.rejects(inspectReceipt(inspector,bytes,'image/png',digest(bytes)),error=>error.code==='INSPECTION_FAILED'&&!error.message.includes('private'));
});

for(const uploadError of [{error:'Duplicate',message:'Asset Already Exists',statusCode:'409'},{code:'ResourceAlreadyExists'},{statusCode:409}])test('legacy bounded collision error reads original bytes '+JSON.stringify(uploadError),async()=>{const f=fixture({uploadStatus:400,uploadError,replayed:true});assert.equal((await f.handler(request())).status,200);});
test('arbitrary400 upload error cannot finalize',async()=>{const f=fixture({uploadStatus:400,uploadError:{message:'unrelated failure'}});assert.equal((await f.handler(request())).status,503);assert.ok(!f.calls.some(c=>c.url.includes('csa109_')));});
test('oversized upload error cannot be parsed as collision',async()=>{const f=fixture({uploadStatus:400,uploadError:{error:'Duplicate',padding:'x'.repeat(4096)}});assert.equal((await f.handler(request())).status,503);assert.ok(!f.calls.some(c=>c.url.includes('csa109_')));});

test('historical upload replay does not report current order status',async()=>{const f=fixture({finalized:true,replayed:true});const response=await f.handler(request());const result=await response.json();assert.equal(response.status,200);assert.equal(result.data.status,'submitted');assert.ok(!Object.hasOwn(result.data,'order_status'));});
