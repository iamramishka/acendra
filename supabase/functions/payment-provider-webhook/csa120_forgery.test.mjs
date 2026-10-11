import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createHandler } from './handler.mjs';
const id='12345678-1234-1234-1234-123456789abc';
const config={ready:true,environment:'sandbox',merchantId:'123456',merchantSecret:'synthetic-secret',appId:'synthetic-app',appSecret:'synthetic-secret',returnUrl:'https://example.test/return',cancelUrl:'https://example.test/cancel',notifyUrl:'https://example.test/notify'};
const md5=x=>createHash('md5').update(x).digest('hex').toUpperCase();
function signed() {const fields={merchant_id:'123456',order_id:id,payment_id:'777',payhere_amount:'123.45',payhere_currency:'LKR',status_code:'2'};return new URLSearchParams({...fields,md5sig:md5(fields.merchant_id+fields.order_id+fields.payhere_amount+fields.payhere_currency+fields.status_code+md5(config.merchantSecret))});}
function harness(mode='valid') {
 const calls=[];const handler=createHandler({onlinePaymentsEnabled:true,providerConfig:config,env:n=>({SUPABASE_URL:'https://database.example.test',SUPABASE_SERVICE_ROLE_KEY:'synthetic-service'})[n],fetch:async(url,options)=>{
  calls.push(url);
  if(url.endsWith('csa102_lookup_payment_attempt')) return Response.json({attemptId:id,orderId:id,provider:'payhere',method:'online',environment:'sandbox',merchantId:'123456',amountMinor:'12345',currency:'LKR'});
  if(url.includes('/oauth/token')) return mode==='unauthorized' ? Response.json({error:'forged'},{status:401}):Response.json({token_type:'Bearer',access_token:'synthetic'});
  if(url.includes('/payment/search')) return Response.json({status:1,data:mode==='missing'?[]:[{payment_id:mode==='different'?'778':'777',order_id:id,status:mode==='pending'?'PENDING':'RECEIVED',currency:'LKR',amount:'123.45',amount_detail:{currency:'LKR',exchange_from:'LKR',exchange_to:'LKR',exchange_rate:'1',gross:'123.45'}}]});
  if(url.endsWith('csa104_finalize_payment')) return Response.json({outcome:'processed'});
  throw new Error('Unexpected request');
 }});return {handler,calls};
}
const request=f=>new Request('https://example.test/callback',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:f});
for(const [field,value] of [['merchant_id','999'],['order_id','22345678-1234-1234-1234-123456789abc'],['payhere_amount','0.01'],['payhere_currency','USD'],['status_code','0'],['md5sig','0'.repeat(32)]]) test(`CSA120 tampering with signed ${field} never grants`,async()=>{const {handler,calls}=harness();const f=signed();f.set(field,value);assert.equal((await handler(request(f))).status,400);assert.equal(calls.some(x=>x.includes('/oauth/')||x.endsWith('csa104_finalize_payment')),false);});
test('CSA120 unsigned payment identity cannot substitute another retrieved settlement',async()=>{const {handler,calls}=harness();const f=signed();f.set('payment_id','778');assert.equal((await handler(request(f))).status,400);assert.equal(calls.some(x=>x.endsWith('csa104_finalize_payment')),false);});
for(const mode of ['unauthorized','missing','different','pending']) test(`CSA120 checksum alone cannot grant when retrieval is ${mode}`,async()=>{const {handler,calls}=harness(mode);assert.notEqual((await handler(request(signed()))).status,200);assert.equal(calls.some(x=>x.endsWith('csa104_finalize_payment')),false);});
test('CSA120 valid independent retrieval is the positive control',async()=>{const {handler,calls}=harness();assert.equal((await handler(request(signed()))).status,200);assert.equal(calls.filter(x=>x.endsWith('csa104_finalize_payment')).length,1);});
