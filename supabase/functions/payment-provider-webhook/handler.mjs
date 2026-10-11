import { createHash } from 'node:crypto';
import { createPayHereAdapter, PaymentAdapterError } from '../_shared/payments/payhere.mjs';
const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
async function boundedText(body, limit) {
  const reader = body?.getReader(); if (!reader) throw new Error('INVALID_REQUEST');
  let size = 0; const chunks = [];
  try { while (true) { const {done,value}=await reader.read(); if(done)break; size+=value.byteLength; if(size>limit){await reader.cancel();throw new Error('BODY_TOO_LARGE');} chunks.push(value); } }
  finally { reader.releaseLock(); }
  const bytes=new Uint8Array(size); let offset=0; for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.byteLength;}
  return new TextDecoder('utf-8',{fatal:true}).decode(bytes);
}
// Explicit enablement is dependency injection for synthetic tests only. The
// deployed entry point passes no enablement; environment variables cannot opt in.
export function createHandler({env,fetch:request=globalThis.fetch,providerConfig,onlinePaymentsEnabled=false}) {
  return async incoming => {
    const respond=(status,code)=>new Response(JSON.stringify(code?{error:{code}}:{received:true}),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
    if(onlinePaymentsEnabled!==true)return respond(503,'ONLINE_PAYMENTS_UNAVAILABLE');
    if(incoming.method!=='POST')return respond(405,'METHOD_NOT_ALLOWED');
    if(!/^application\/x-www-form-urlencoded(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??''))return respond(415,'UNSUPPORTED_MEDIA_TYPE');
    let form;
    try {
      const body=await boundedText(incoming.body,16384);
      // URLSearchParams is permissive with invalid escapes/UTF-8. Validate each
      // component strictly first, while preserving duplicate keys for rejection.
      for(const pair of body.split('&'))for(const part of pair.split('='))decodeURIComponent(part.replaceAll('+',' '));
      form=new URLSearchParams(body);const seen=new Set();
      for(const [key,value] of form){if(seen.has(key)||!key||key.length>100||value.length>2000||/[\x00-\x1f\x7f]/.test(key+value))throw new Error('INVALID_REQUEST');seen.add(key);}
      for(const key of ['merchant_id','order_id','payment_id','payhere_amount','payhere_currency','status_code','md5sig'])if(form.getAll(key).length!==1)throw new Error('INVALID_REQUEST');
      if(!uuid(form.get('order_id')))throw new Error('INVALID_REQUEST');
    } catch(error){return respond(error.message==='BODY_TOO_LARGE'?413:400,'INVALID_NOTIFICATION');}
    const url=env('SUPABASE_URL'),serviceKey=env('SUPABASE_SERVICE_ROLE_KEY');
    if(!url||!serviceKey||!providerConfig)return respond(503,'SERVICE_UNAVAILABLE');
    try {
      const adapter=createPayHereAdapter(providerConfig,{fetch:request});
      const rpc=async(name,args)=>{
        const result=await request(`${url}/rest/v1/rpc/${name}`,{method:'POST',headers:{Authorization:`Bearer ${serviceKey}`,apikey:serviceKey,'Content-Type':'application/json'},body:JSON.stringify(args),signal:AbortSignal.timeout(15000),redirect:'error'});
        if(!result.ok)throw new Error('SERVICE_UNAVAILABLE');
        return JSON.parse(await boundedText(result.body,16384));
      };
      const attempt=await rpc('csa102_lookup_payment_attempt',{p_provider_order_id:form.get('order_id')});
      if(!attempt||!uuid(attempt.attemptId)||attempt.orderId!==form.get('order_id'))return respond(400,'INVALID_NOTIFICATION');
      const verified=adapter.verifyNotification(form,attempt);
      // Non-success is never persisted or used to mutate/revoke entitlements.
      // Refund/chargeback handling requires separately approved policy.
      if(verified.statusCode!=='2')return respond(200);
      const settlement=await adapter.retrieveSettlement(verified,attempt);
      const identity=JSON.stringify([settlement.provider,settlement.merchantId,settlement.environment,settlement.attemptId,settlement.orderId,settlement.paymentId,settlement.amountMinor,settlement.currency,'RECEIVED']);
      const result=await rpc('csa104_finalize_payment',{
        p_attempt_id:settlement.attemptId,p_merchant:settlement.merchantId,p_environment:settlement.environment,
        p_event_id:`payhere:received:${settlement.paymentId}`,p_payload_hash:createHash('sha256').update(identity).digest('hex'),
        p_external_settlement_id:settlement.paymentId,p_amount_minor:settlement.amountMinor,p_currency:settlement.currency,
        p_confirmed_at:settlement.retrievedAt,p_evidence_reference:`payhere:authenticated_retrieval:${settlement.paymentId}`,
      });
      if(!['processed','duplicate','reconciliation_required'].includes(result?.outcome))throw new Error('SERVICE_UNAVAILABLE');
      return respond(200);
    } catch(error){
      if(error instanceof PaymentAdapterError){
        if(['PROVIDER_UNAVAILABLE','PAYMENT_NOT_CONFIGURED','INVALID_CONFIGURATION','INVALID_PROVIDER_RESPONSE'].includes(error.code))return respond(503,'PROVIDER_UNAVAILABLE');
        return respond(400,'INVALID_NOTIFICATION');
      }
      return respond(503,'SERVICE_UNAVAILABLE');
    }
  };
}
