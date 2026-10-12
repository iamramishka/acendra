const uuid=x=>typeof x==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(x);
const reason=x=>typeof x==='string'&&x.trim().length>0&&x.length<=1000&&!/[\x00-\x1f\x7f]/.test(x);
const exact=(x,keys)=>x&&typeof x==='object'&&!Array.isArray(x)&&Object.keys(x).length===keys.length&&keys.every(k=>Object.hasOwn(x,k));
async function json(body,limit) {
 const reader=body?.getReader();if(!reader) throw new Error('INVALID_REQUEST');const chunks=[];let size=0;
 try {while(true) {const {done,value}=await reader.read();if(done) break;size+=value.length;if(size>limit){await reader.cancel();throw new Error('BODY_TOO_LARGE');}chunks.push(value);}} finally {reader.releaseLock();}
 const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
 return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
}
export function createHandler({env,fetch:request=globalThis.fetch,enabled=false}) {
 const url=env('SUPABASE_URL'), publicKey=env('SUPABASE_ANON_KEY'), serviceKey=env('SUPABASE_SERVICE_ROLE_KEY');
 const origins=new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS')??'http://127.0.0.1:8080').split(',').map(x=>x.trim()));
 return async incoming=>{
  const origin=incoming.headers.get('Origin');
  const respond=(status,code,data)=>Response.json(code?{error:{code}}:{data},{status,headers:{'Cache-Control':'no-store',Vary:'Origin',...(origin&&origins.has(origin)?{'Access-Control-Allow-Origin':origin}:{})}});
  if(enabled!==true) return respond(503,'ENTITLEMENT_ADMIN_UNAVAILABLE');
  if(origin&&!origins.has(origin)) return respond(403,'ORIGIN_FORBIDDEN');
  if(incoming.method==='OPTIONS') {
   const headers=(incoming.headers.get('Access-Control-Request-Headers')??'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);
   if(!origin||incoming.headers.get('Access-Control-Request-Method')!=='POST'||headers.some(x=>!['authorization','content-type','apikey','x-client-info','idempotency-key'].includes(x))) return respond(403,'PREFLIGHT_FORBIDDEN');
   return new Response(null,{status:204,headers:{'Cache-Control':'no-store',Vary:'Origin','Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info, Idempotency-Key'}});
  }
  if(incoming.method!=='POST') return respond(405,'METHOD_NOT_ALLOWED');
  const authorization=incoming.headers.get('Authorization'),key=incoming.headers.get('Idempotency-Key');
  if(!authorization?.startsWith('Bearer ')||authorization.length>16384) return respond(401,'AUTH_REQUIRED');
  if(!key||!/^[A-Za-z0-9._:-]{1,128}$/.test(key)) return respond(400,'INVALID_IDEMPOTENCY_KEY');
  if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??'')) return respond(415,'UNSUPPORTED_MEDIA_TYPE');
  let body;try {body=await json(incoming.body,8192);}catch(e){return respond(e.message==='BODY_TOO_LARGE'?413:400,'INVALID_REQUEST');}
  let rpc,args;
  if(body?.action==='grant'&&exact(body,['action','user_id','course_id','reason','expires_at'])&&uuid(body.user_id)&&uuid(body.course_id)&&reason(body.reason)&&
    (body.expires_at===null||(typeof body.expires_at==='string'&&/^\d{4}-\d{2}-\d{2}T/.test(body.expires_at)&&Number.isFinite(Date.parse(body.expires_at))))) {
   rpc='csa116_grant_admin';args={p_user:body.user_id,p_course:body.course_id,p_reason:body.reason,p_expires_at:body.expires_at};
  } else if(body?.action==='revoke'&&exact(body,['action','user_id','course_id','grant_id','scope','reason'])&&uuid(body.user_id)&&reason(body.reason)&&
   ((body.scope==='grant'&&uuid(body.course_id)&&uuid(body.grant_id))||(body.scope==='course'&&uuid(body.course_id)&&body.grant_id===null)||(body.scope==='account'&&body.course_id===null&&body.grant_id===null))) {
   rpc='csa118_revoke_access';args={p_user:body.user_id,p_course:body.course_id,p_grant:body.grant_id,p_scope:body.scope,p_reason:body.reason};
  } else if(body?.action==='release'&&exact(body,['action','restriction_id','reason'])&&uuid(body.restriction_id)&&reason(body.reason)) {
   rpc='csa118_release_restriction';args={p_restriction:body.restriction_id,p_reason:body.reason};
  } else return respond(400,'INVALID_REQUEST');
  if(!url||!publicKey||!serviceKey) return respond(503,'SERVICE_UNAVAILABLE');
  try {
   const userResponse=await request(`${url}/auth/v1/user`,{headers:{Authorization:authorization,apikey:publicKey},redirect:'error',signal:AbortSignal.timeout(15000)});
   if(!userResponse.ok) return respond(401,'AUTH_REQUIRED');
   const user=await json(userResponse.body,32768);
   const token=authorization.slice(7).split('.');if(token.length!==3) return respond(401,'AUTH_REQUIRED');
   let claims;try {const payload=token[1].replaceAll('-','+').replaceAll('_','/');claims=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length/4)*4,'=')),x=>x.charCodeAt(0))));}catch{return respond(401,'AUTH_REQUIRED');}
   if(!uuid(user.id)||user.is_anonymous===true||claims?.sub!==user.id||claims?.role!=='authenticated'||!uuid(claims?.session_id)) return respond(401,'AUTH_REQUIRED');
   if(claims.aal!=='aal2') return respond(403,'MFA_REQUIRED');
   const mutation=await request(`${url}/rest/v1/rpc/${rpc}`,{method:'POST',headers:{Authorization:`Bearer ${serviceKey}`,apikey:serviceKey,'Content-Type':'application/json'},body:JSON.stringify({...args,p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal,p_key:key}),redirect:'error',signal:AbortSignal.timeout(15000)});
   const result=await json(mutation.body,32768);
   if(!mutation.ok) return respond(result?.code==='42501'?403:['22023','23505','55000'].includes(result?.code)?409:result?.code==='P0002'?404:503,
    result?.code==='42501'?'ADMIN_PERMISSION_REQUIRED':['22023','23505','55000'].includes(result?.code)?'ENTITLEMENT_CONFLICT':result?.code==='P0002'?'ENTITLEMENT_NOT_FOUND':'SERVICE_UNAVAILABLE');
   if(!result||typeof result!=='object'||Array.isArray(result)||typeof result.replayed!=='boolean') return respond(503,'SERVICE_UNAVAILABLE');
   return respond(200,null,result);
  } catch {return respond(503,'SERVICE_UNAVAILABLE');}
 };
}
