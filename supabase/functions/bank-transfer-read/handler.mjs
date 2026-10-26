const uuid = v => typeof v === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
async function json(body, max) {
  const reader = body?.getReader(); if (!reader) throw Error('Missing body');
  const chunks = []; let length = 0;
  try { for (;;) { const {done,value} = await reader.read(); if (done) break;
    length += value.length; if (length > max) { await reader.cancel(); throw Error('Bound'); } chunks.push(value); }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(length); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk,offset); offset += chunk.length; }
  return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
}
export function createHandler({env,fetch: request = globalThis.fetch,enabled = false}) {
  const config = {url:env('SUPABASE_URL'),key:env('SUPABASE_ANON_KEY'),service:env('SUPABASE_SERVICE_ROLE_KEY'),
    origins:new Set((env('ACENDRA_BANK_READ_ALLOWED_ORIGINS') ?? '').split(',').map(v=>v.trim()).filter(Boolean))};
  return async incoming => {
    const origin = incoming.headers.get('Origin');
    const respond = (status,code,data) => new Response(JSON.stringify(code ? {error:{code}} : {data}),
      {status,headers:{'Content-Type':'application/json','Cache-Control':'no-store',Vary:'Origin',
        ...(origin && config.origins.has(origin) ? {'Access-Control-Allow-Origin':origin} : {})}});
    if (origin && !config.origins.has(origin)) return respond(403,'ORIGIN_FORBIDDEN');
    if (incoming.method==='OPTIONS') {
      const headers = (incoming.headers.get('Access-Control-Request-Headers')??'').toLowerCase().split(',').map(v=>v.trim()).filter(Boolean);
      if (!origin || incoming.headers.get('Access-Control-Request-Method')!=='POST' || headers.some(v=>!['authorization','content-type','apikey','x-client-info'].includes(v))) return respond(403,'PREFLIGHT_FORBIDDEN');
      return new Response(null,{status:204,headers:{'Access-Control-Allow-Origin':origin,Vary:'Origin','Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info'}});
    }
    if (incoming.method!=='POST') return respond(405,'METHOD_NOT_ALLOWED');
    const bearer=incoming.headers.get('Authorization');
    if (!bearer?.startsWith('Bearer ') || bearer.length>16384) return respond(401,'AUTH_REQUIRED');
    if (!enabled || !config.url || !config.key || !config.service) return respond(503,'BANK_READ_UNAVAILABLE');
    if (!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??'')) return respond(415,'UNSUPPORTED_MEDIA_TYPE');
    let body; try {body=await json(incoming.body,2048);} catch {return respond(400,'INVALID_REQUEST');}
    const queue=body?.queue===true;
    const instructions=body?.instructions===true;
    if (!body || (instructions
      ? queue || Object.keys(body).length!==2 || !uuid(body.order_id)
      : Object.keys(body).length!==1 || (!queue && !uuid(body.order_id)))) return respond(400,'INVALID_REQUEST');
    try {
      const auth=await request(config.url+'/auth/v1/user',{headers:{Authorization:bearer,apikey:config.key},redirect:'error',signal:AbortSignal.timeout(15000)});
      if (!auth.ok) return respond(401,'AUTH_REQUIRED');
      const user=await json(auth.body,32768);
      const parts=bearer.slice(7).split('.'); if(parts.length!==3) return respond(401,'AUTH_REQUIRED');
      const payload=parts[1].replaceAll('-','+').replaceAll('_','/');
      const claims=JSON.parse(atob(payload.padEnd(Math.ceil(payload.length/4)*4,'=')));
      if(!uuid(user?.id)||user.is_anonymous===true||claims.sub!==user.id||claims.role!=='authenticated'||!uuid(claims.session_id)||!['aal1','aal2'].includes(claims.aal)) return respond(401,'AUTH_REQUIRED');
      if(queue && claims.aal!=='aal2') return respond(403,'MFA_REQUIRED');
      const rpc=await request(config.url+'/rest/v1/rpc/'+(instructions?'csa276_read_bank_instructions':'csa179_read_bank_transfer'),{method:'POST',headers:{Authorization:'Bearer '+config.service,apikey:config.service,'Content-Type':'application/json'},
        body:JSON.stringify({p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal,p_order:queue?null:body.order_id,...(instructions?{}:{p_queue:queue})}),redirect:'error',signal:AbortSignal.timeout(15000)});
      const result=await json(rpc.body,131072);
      if(!rpc.ok) return respond(result?.code==='42501'?403:result?.code==='P0002'?404:503,result?.code==='42501'?'FORBIDDEN':result?.code==='P0002'?'ORDER_NOT_FOUND':'SERVICE_UNAVAILABLE');
      if(instructions) {
        if(result?.order_id!==body.order_id || result?.payment_method!=='bank_transfer' || result?.status!=='pending_payment' || !result?.bank_instructions) return respond(503,'SERVICE_UNAVAILABLE');
        const b=result.bank_instructions;
        return respond(200,null,{order_id:result.order_id,order_number:result.order_number,course:{id:result.course?.id,title:result.course?.title},amount_minor:result.amount_minor,currency_code:result.currency_code,payment_method:result.payment_method,status:result.status,next_action:result.next_action,
          bank_instructions:{bank_name:b.bank_name,account_holder:b.account_holder,account_number:b.account_number,branch_name:b.branch_name,currency_code:b.currency_code}});
      }
      const safe=item=>({order_id:item.order_id,order_number:item.order_number,course_title:item.course_title,status:item.status,submission_id:item.submission_id,submitted_at:item.submitted_at,rejection_reason:item.rejection_reason,
        amount_minor:item.amount_minor,currency:item.currency,
        ...(!queue?{order_created_at:item.order_created_at}:{})});
      if(queue && (!Array.isArray(result?.items)||result.items.length>100)) return respond(503,'SERVICE_UNAVAILABLE');
      return respond(200,null,queue?{items:result.items.map(safe)}:safe(result));
    } catch {return respond(503,'SERVICE_UNAVAILABLE');}
  };
}
