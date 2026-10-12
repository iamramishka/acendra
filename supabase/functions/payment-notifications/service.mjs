import { createWorker } from './worker.mjs';

// Server-side transport only. No email vendor is inferred from environment.
// The reviewed scheduler supplies a provider with stable-key deduplication.
export function createServiceWorker({ env, fetch: request = globalThis.fetch, deliver, enabled = false }) {
 const url=env('SUPABASE_URL'); const key=env('SUPABASE_SERVICE_ROLE_KEY');
 const call=async(path,body)=>{
  if (!url || !key) throw new Error('NOTIFICATION_CONFIGURATION_REQUIRED');
  const response=await request(`${url}${path}`,{method:body ? 'POST':'GET',headers:{Authorization:`Bearer ${key}`,apikey:key,...(body?{'Content-Type':'application/json'}:{})},
   ...(body?{body:JSON.stringify(body)}:{}),redirect:'error',signal:AbortSignal.timeout(15000)});
  if (!response.ok) throw new Error('NOTIFICATION_SERVICE_UNAVAILABLE');
  return response.json();
 };
 return createWorker({enabled,deliver,store:{claim:limit=>call('/rest/v1/rpc/csa119_claim_notifications',{p_limit:limit}),
  complete:(id,token,sent)=>call('/rest/v1/rpc/csa119_complete_notification',{p_id:id,p_lease_token:token,p_sent:sent})},
  resolveRecipient:async user=>{
   if(typeof user!=='string'||!/^[0-9a-f-]{36}$/i.test(user)) throw new Error('INVALID_RECIPIENT');
   const account=await call(`/auth/v1/admin/users/${user}`);
   if(account.id!==user||account.deleted_at||account.is_anonymous||!account.email_confirmed_at) throw new Error('INVALID_RECIPIENT');
   return account.email;
  }});
}
