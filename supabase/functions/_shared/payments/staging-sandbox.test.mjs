import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { stagingSandboxConfiguration, STAGING_SUPABASE_URL, STAGING_APP_ORIGIN } from './staging-sandbox.mjs';
import { createStagingPaymentHandler } from './staging-entrypoints.mjs';

const baseline = { APP_ENV:'staging', PAYHERE_ENVIRONMENT:'sandbox', SUPABASE_URL:STAGING_SUPABASE_URL,
  ACENDRA_CHECKOUT_ALLOWED_ORIGINS:STAGING_APP_ORIGIN,
  PAYHERE_SANDBOX_MERCHANT_ID:'synthetic-merchant', PAYHERE_SANDBOX_MERCHANT_SECRET:'synthetic-secret',
  PAYHERE_SANDBOX_APP_ID:'synthetic-app', PAYHERE_SANDBOX_APP_SECRET:'synthetic-app-secret' };
const env = values => key => values[key];
test('reviewed project sandbox uses only server sandbox credentials and harmless return',()=>{
  const config=stagingSandboxConfiguration(env(baseline));
  assert.equal(config.environment,'sandbox'); assert.equal(config.returnUrl,`${STAGING_APP_ORIGIN}/dashboard/courses`);
  assert.equal(config.notifyUrl,`${STAGING_SUPABASE_URL}/functions/v1/payment-provider-webhook`);
  assert.ok(Object.isFrozen(config));
});
for (const [key,value] of [['APP_ENV','production'],['APP_ENV','development'],['PAYHERE_ENVIRONMENT','production'],
  ['SUPABASE_URL','https://another-project.supabase.co'],['SUPABASE_URL',`${STAGING_SUPABASE_URL}/`],
  ['ACENDRA_CHECKOUT_ALLOWED_ORIGINS',`${STAGING_APP_ORIGIN},https://evil.test`],
  ['PAYHERE_SANDBOX_APP_ID','invalid:app'],['PAYHERE_SANDBOX_APP_SECRET','line\nsecret']]) {
  test(`conflicting staging boundary ${key} stays disabled`,()=>assert.equal(stagingSandboxConfiguration(env({...baseline,[key]:value})),undefined));
}
for (const key of Object.keys(baseline)) {
  test(`missing ${key} cannot enable sandbox even with generic credentials`,()=>{
    const values={...baseline,PAYHERE_MERCHANT_ID:'generic',PAYHERE_MERCHANT_SECRET:'generic',PAYHERE_APP_ID:'generic',PAYHERE_APP_SECRET:'generic'};
    delete values[key]; assert.equal(stagingSandboxConfiguration(env(values)),undefined);
  });
}
const uuid='11111111-1111-4111-8111-111111111111';
function request(kind) {
  const customer={first_name:'Sample',last_name:'Student',phone:'+94771234567',address:'Sample Street',city:'Colombo',country:'Sri Lanka'};
  return new Request('https://api.example.test', { method:'POST',headers:{Authorization:'Bearer synthetic',
    'Idempotency-Key':'sample-replay','Content-Type':kind==='webhook'?'application/x-www-form-urlencoded':'application/json'},
    body:kind==='webhook'?'forged=true':JSON.stringify(kind==='order'?{course_id:uuid,payment_method:'online'}:{order_id:uuid,customer}) });
}
for(const kind of ['order','initialize','webhook']) {
  test(`${kind} production and default gates make no trusted requests`,async()=>{
    for(const values of [{},{...baseline,APP_ENV:'production'},{...baseline,PAYHERE_ENVIRONMENT:'production'}]) {
      let calls=0; const handler=createStagingPaymentHandler(kind,{env:env(values),fetch:()=>{calls++;throw Error('no network allowed');}});
      const response=await handler(request(kind)); assert.equal(response.status,503); assert.equal(calls,0);
    }
  });
}
test('enabled sandbox webhook rejects forged malformed callbacks without financial mutation',async()=>{
  let calls=0;
  const handler=createStagingPaymentHandler('webhook',{env:env({...baseline,SUPABASE_SERVICE_ROLE_KEY:'synthetic-key'}),fetch:()=>{calls++;throw Error('no transport');}});
  const response=await handler(request('webhook')); assert.equal(response.status,400);assert.equal(calls,0);
});
test('enabled sandbox order still demands verified identity before creating order',async()=>{
  let calls=0;
  const handler=createStagingPaymentHandler('order',{env:env({...baseline,SUPABASE_ANON_KEY:'synthetic-public',SUPABASE_SERVICE_ROLE_KEY:'synthetic-server'}),fetch:async url=>{calls++;assert.equal(url,`${STAGING_SUPABASE_URL}/auth/v1/user`);return new Response('{}',{status:401});}});
  assert.equal((await handler(request('order'))).status,401);assert.equal(calls,1);
});

test('sandbox wiring preserves checksum then OAuth settlement before atomic finalize',async()=>{
  const digest=value=>createHash('md5').update(value).digest('hex').toUpperCase();
  const form=new URLSearchParams({merchant_id:baseline.PAYHERE_SANDBOX_MERCHANT_ID,order_id:uuid,payment_id:'9007199254740993',
    payhere_amount:'123.45',payhere_currency:'LKR',status_code:'2'});
  form.set('md5sig',digest(baseline.PAYHERE_SANDBOX_MERCHANT_ID+uuid+'123.45LKR2'+digest(baseline.PAYHERE_SANDBOX_MERCHANT_SECRET)));
  const calls=[];
  const handler=createStagingPaymentHandler('webhook',{env:env({...baseline,SUPABASE_SERVICE_ROLE_KEY:'synthetic-server'}),fetch:async(url,options)=>{
    calls.push(url);
    if(url.endsWith('/csa102_lookup_payment_attempt')) return Response.json({attemptId:uuid,orderId:uuid,provider:'payhere',method:'online',environment:'sandbox',merchantId:baseline.PAYHERE_SANDBOX_MERCHANT_ID,currency:'LKR',amountMinor:'12345',title:'Synthetic'});
    if(url.endsWith('/merchant/v1/oauth/token')) return Response.json({token_type:'Bearer',access_token:'synthetic-provider-token'});
    if(url.includes('/merchant/v1/payment/search')) return Response.json({status:1,data:[{payment_id:'9007199254740993',order_id:uuid,status:'RECEIVED',currency:'LKR',amount:'123.45',amount_detail:{currency:'LKR',exchange_from:'LKR',exchange_to:'LKR',exchange_rate:'1',gross:'123.45'}}]});
    if(url.endsWith('/csa104_finalize_payment')) {
      const data=JSON.parse(options.body);assert.equal(data.p_environment,'sandbox');assert.equal(data.p_amount_minor,'12345');
      assert.equal(data.p_evidence_reference,'payhere:authenticated_retrieval:9007199254740993');
      return Response.json({outcome:'processed'});
    }
    throw Error('unexpected transport');
  }});
  const incoming=body=>new Request('https://api.example.test',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body});
  const forged=new URLSearchParams(form);forged.set('md5sig','0'.repeat(32));
  assert.equal((await handler(incoming(forged))).status,400);assert.equal(calls.length,1);
  calls.length=0;
  assert.equal((await handler(incoming(form))).status,200);
  assert.deepEqual(calls,[`${STAGING_SUPABASE_URL}/rest/v1/rpc/csa102_lookup_payment_attempt`,
    'https://sandbox.payhere.lk/merchant/v1/oauth/token',
    `https://sandbox.payhere.lk/merchant/v1/payment/search?order_id=${uuid}`,
    `${STAGING_SUPABASE_URL}/rest/v1/rpc/csa104_finalize_payment`]);
});
