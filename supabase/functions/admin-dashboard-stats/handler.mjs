const uuid=x=>typeof x==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(x);
const exact=(x,keys)=>x&&typeof x==='object'&&!Array.isArray(x)&&Object.keys(x).length===keys.length&&keys.every(k=>Object.hasOwn(x,k));
export async function readJson(body,max=8192){const r=body?.getReader();if(!r)throw Error();const chunks=[];let n=0;try{while(true){const{done,value}=await r.read();if(done)break;n+=value.length;if(n>max){await r.cancel();throw Error();}chunks.push(value);}}finally{r.releaseLock();}const b=new Uint8Array(n);let p=0;for(const c of chunks){b.set(c,p);p+=c.length;}return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(b));}
export function createHandler({env,fetch:request=globalThis.fetch,enabled=false,report=false}){
 const url=env('SUPABASE_URL'),pk=env('SUPABASE_ANON_KEY'),sk=env('SUPABASE_SERVICE_ROLE_KEY');
 const origins=new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS')??'http://127.0.0.1:8080').split(',').map(x=>x.trim()).filter(Boolean));
 return async incoming=>{
  const origin=incoming.headers.get('Origin');const respond=(status,code,data)=>Response.json(code?{error:{code}}:{data},{status,headers:{'Cache-Control':'no-store',Vary:'Origin',...(origin&&origins.has(origin)?{'Access-Control-Allow-Origin':origin}:{})}});
  if(enabled!==true)return respond(503,'REPORTING_UNAVAILABLE');
  if(origin!==null&&!origins.has(origin))return respond(403,'ORIGIN_FORBIDDEN');
  if(incoming.method==='OPTIONS'){const headers=(incoming.headers.get('Access-Control-Request-Headers')??'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);if(!origin||incoming.headers.get('Access-Control-Request-Method')!=='POST'||headers.some(x=>!['authorization','content-type','apikey','x-client-info'].includes(x)))return respond(403,'PREFLIGHT_FORBIDDEN');return new Response(null,{status:204,headers:{'Cache-Control':'no-store',Vary:'Origin','Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info'}});}
  if(incoming.method!=='POST')return respond(405,'METHOD_NOT_ALLOWED');
  const authorization=incoming.headers.get('Authorization');if(!authorization?.startsWith('Bearer ')||authorization.length>16384)return respond(401,'AUTH_REQUIRED');
  if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??''))return respond(415,'UNSUPPORTED_MEDIA_TYPE');
  let b;try{b=await readJson(incoming.body);}catch{return respond(400,'INVALID_REQUEST');}
  let args;if(!report){if(!exact(b,['period'])||b.period!=='last_30_days')return respond(400,'INVALID_REQUEST');args={p_period:b.period};}
  else{const date=x=>typeof x==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(x)&&new Date(x).toISOString().slice(0,10)===x;try{if(!exact(b,['from','to','currency_code'])||!date(b.from)||!date(b.to)||b.currency_code!=='LKR'||b.from>b.to||(Date.parse(b.to)-Date.parse(b.from))/86400000>365)return respond(400,'INVALID_REQUEST');}catch{return respond(400,'INVALID_REQUEST');}args={p_from:b.from,p_to:b.to,p_currency:b.currency_code};}
  if(!url||!pk||!sk)return respond(503,'SERVICE_UNAVAILABLE');
  try{const auth=await request(`${url}/auth/v1/user`,{headers:{Authorization:authorization,apikey:pk},redirect:'error',signal:AbortSignal.timeout(15000)});if(!auth.ok)return respond(401,'AUTH_REQUIRED');const user=await readJson(auth.body,32768);const token=authorization.slice(7).split('.');if(token.length!==3)return respond(401,'AUTH_REQUIRED');let c;try{const p=token[1].replaceAll('-','+').replaceAll('_','/');c=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(atob(p.padEnd(Math.ceil(p.length/4)*4,'=')),x=>x.charCodeAt(0))));}catch{return respond(401,'AUTH_REQUIRED');}
   if(!uuid(user.id)||user.is_anonymous===true||c.sub!==user.id||c.role!=='authenticated'||!uuid(c.session_id)||!['aal1','aal2'].includes(c.aal))return respond(401,'AUTH_REQUIRED');
   const rpc=report?'csa172_financial_report':'csa158_dashboard_stats';const response=await request(`${url}/rest/v1/rpc/${rpc}`,{method:'POST',headers:{Authorization:`Bearer ${sk}`,apikey:sk,'Content-Type':'application/json'},body:JSON.stringify({...args,p_actor:user.id,p_session_id:c.session_id,p_aal:c.aal}),redirect:'error',signal:AbortSignal.timeout(15000)});const result=await readJson(response.body,65536);if(!response.ok)return respond(result?.code==='42501'?403:result?.code==='22023'?400:503,result?.code==='42501'?'ADMIN_PERMISSION_REQUIRED':result?.code==='22023'?'INVALID_REQUEST':'REPORTING_UNAVAILABLE');
   if(!result||typeof result!=='object'||Array.isArray(result))return respond(503,'REPORTING_UNAVAILABLE');return respond(200,null,result);
  }catch{return respond(503,'SERVICE_UNAVAILABLE');}
 };
}
