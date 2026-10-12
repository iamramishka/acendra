const uuid=x=>typeof x==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(x);
async function readJson(stream,limit){const reader=stream?.getReader();if(!reader)throw Error('INVALID');const chunks=[];let n=0;try{while(true){const {done,value}=await reader.read();if(done)break;n+=value.length;if(n>limit){await reader.cancel();throw Error('LARGE');}chunks.push(value);}}finally{reader.releaseLock();}const bytes=new Uint8Array(n);let at=0;for(const c of chunks){bytes.set(c,at);at+=c.length;}return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));}
export function createHandler({env,fetch:request=globalThis.fetch,enabled=false}){
 const origins=new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS')??'http://127.0.0.1:8080').split(',').map(x=>x.trim()).filter(Boolean));
 return async incoming=>{
  const origin=incoming.headers.get('Origin');const reply=(status,code,data)=>Response.json(code?{error:{code}}:{data},{status,headers:{'Cache-Control':'no-store',Vary:'Origin',...(origin&&origins.has(origin)?{'Access-Control-Allow-Origin':origin}:{})}});
  if(enabled!==true)return reply(503,'PUBLICATION_UNAVAILABLE');
  if(origin!==null&&!origins.has(origin))return reply(403,'ORIGIN_FORBIDDEN');
  if(incoming.method==='OPTIONS'){const requested=(incoming.headers.get('Access-Control-Request-Headers')??'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);if(!origin||incoming.headers.get('Access-Control-Request-Method')!=='POST'||requested.some(x=>!['authorization','content-type','apikey','x-client-info','idempotency-key'].includes(x)))return reply(403,'PREFLIGHT_FORBIDDEN');return new Response(null,{status:204,headers:{'Cache-Control':'no-store',Vary:'Origin','Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info, Idempotency-Key'}});}
  if(incoming.method!=='POST')return reply(405,'METHOD_NOT_ALLOWED');
  const authorization=incoming.headers.get('Authorization'),key=incoming.headers.get('Idempotency-Key');
  if(!authorization?.startsWith('Bearer ')||authorization.length>16384)return reply(401,'AUTH_REQUIRED');
  if(!key||!/^[A-Za-z0-9._:-]{1,128}$/.test(key))return reply(400,'INVALID_IDEMPOTENCY_KEY');
  if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??''))return reply(415,'UNSUPPORTED_MEDIA_TYPE');
  let body;try{body=await readJson(incoming.body,8192);}catch(e){return reply(e.message==='LARGE'?413:400,'INVALID_REQUEST');}
  if(!body||Array.isArray(body)||typeof body!=='object'||Object.keys(body).some(k=>!['course_id','expected_updated_at','action'].includes(k))||!uuid(body.course_id)||typeof body.expected_updated_at!=='string'||!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/.test(body.expected_updated_at)||!Number.isFinite(Date.parse(body.expected_updated_at))||(Object.hasOwn(body,'action')&&!['publish','unpublish'].includes(body.action)))return reply(400,'INVALID_REQUEST');
  const url=env('SUPABASE_URL'),publicKey=env('SUPABASE_ANON_KEY'),serviceKey=env('SUPABASE_SERVICE_ROLE_KEY');if(!url||!publicKey||!serviceKey)return reply(503,'SERVICE_UNAVAILABLE');
  try{
   const userResponse=await request(`${url}/auth/v1/user`,{headers:{Authorization:authorization,apikey:publicKey},redirect:'error',signal:AbortSignal.timeout(15000)});if(!userResponse.ok)return reply(401,'AUTH_REQUIRED');const user=await readJson(userResponse.body,32768);
   const parts=authorization.slice(7).split('.');if(parts.length!==3)return reply(401,'AUTH_REQUIRED');let claims;try{const payload=parts[1].replaceAll('-','+').replaceAll('_','/');claims=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(atob(payload.padEnd(Math.ceil(payload.length/4)*4,'=')),x=>x.charCodeAt(0))));}catch{return reply(401,'AUTH_REQUIRED');}
   if(!uuid(user.id)||user.is_anonymous===true||claims?.sub!==user.id||claims?.role!=='authenticated'||!uuid(claims?.session_id))return reply(401,'AUTH_REQUIRED');if(claims.aal!=='aal2')return reply(403,'MFA_REQUIRED');
   const mutation=await request(`${url}/rest/v1/rpc/csa165_publish_course`,{method:'POST',headers:{Authorization:`Bearer ${serviceKey}`,apikey:serviceKey,'Content-Type':'application/json'},body:JSON.stringify({p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal,p_course:body.course_id,p_expected:body.expected_updated_at,p_action:body.action??'publish',p_key:key}),redirect:'error',signal:AbortSignal.timeout(15000)});const result=await readJson(mutation.body,32768);
   if(!mutation.ok){const map={'42501':[403,'ADMIN_PERMISSION_REQUIRED'],'40001':[409,'COURSE_CONFLICT'],'23514':[409,'COURSE_NOT_READY'],'22023':[400,'INVALID_REQUEST'],'55000':[409,'INVALID_TRANSITION'],'P0002':[404,'COURSE_NOT_FOUND']};const [status,code]=map[result?.code]??[503,'SERVICE_UNAVAILABLE'];return reply(status,code);}
   if(result?.course_id!==body.course_id||!['published','draft'].includes(result.status)||typeof result.replayed!=='boolean'||typeof result.updated_at!=='string')return reply(503,'SERVICE_UNAVAILABLE');
   return reply(200,null,{course_id:result.course_id,status:result.status,published_at:result.published_at,updated_at:result.updated_at,replayed:result.replayed});
  }catch{return reply(503,'SERVICE_UNAVAILABLE');}
 };
}
