import {signPlayback} from './signer.mjs';
const uuid=x=>typeof x==='string'&&/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(x);
async function readJson(body,max=8192){const r=body?.getReader();if(!r)throw Error();let bytes=[];let size=0;try{while(true){const {value,done}=await r.read();if(done)break;size+=value.length;if(size>max){await r.cancel();throw Error();}bytes.push(...value);}}finally{r.releaseLock();}return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(new Uint8Array(bytes)));}
export function createHandler({env,fetch:request=globalThis.fetch,enabled=false,sign=signPlayback,clock=()=>Math.floor(Date.now()/1000)}) {
 return async incoming=>{
 const origin=incoming.headers.get('Origin');
 const origins=new Set((env('ACENDRA_VIDEO_ALLOWED_ORIGINS')??'http://127.0.0.1:8080').split(',').map(x=>x.trim()));
 const cors=origin&&origins.has(origin)?{'Access-Control-Allow-Origin':origin}:{};
 const reply=(status,code,data)=>Response.json(code?{error:{code}}:{data},{status,headers:{'Cache-Control':'no-store',Vary:'Origin',...cors}});
 if(enabled!==true)return reply(503,'VIDEO_UNAVAILABLE');
 if(origin&&!origins.has(origin))return reply(403,'ORIGIN_FORBIDDEN');
 if(incoming.method==='OPTIONS'){
 const headers=(incoming.headers.get('Access-Control-Request-Headers')??'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);
 if(!origin||incoming.headers.get('Access-Control-Request-Method')!=='POST'||headers.some(x=>!['authorization','content-type','apikey','x-client-info'].includes(x)))return reply(403,'PREFLIGHT_FORBIDDEN');
 return new Response(null,{status:204,headers:{'Cache-Control':'no-store',Vary:'Origin',...cors,'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info'}});
 }
 if(incoming.method!=='POST')return reply(405,'METHOD_NOT_ALLOWED');
 const authorization=incoming.headers.get('Authorization');
 if(!authorization||authorization.length>16384||!/^Bearer [A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(authorization))return reply(401,'AUTH_REQUIRED');
 if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??''))return reply(415,'UNSUPPORTED_MEDIA_TYPE');
 let body;try{body=await readJson(incoming.body);}catch{return reply(400,'INVALID_REQUEST');}
 if(!body||Object.keys(body).length!==1||!uuid(body.lesson_id))return reply(400,'INVALID_REQUEST');
 const url=env('SUPABASE_URL'),pk=env('SUPABASE_ANON_KEY'),sk=env('SUPABASE_SERVICE_ROLE_KEY');
 if(!url||!pk||!sk)return reply(503,'VIDEO_UNAVAILABLE');
 try {
 const u=await request(`${url}/auth/v1/user`,{headers:{Authorization:authorization,apikey:pk},redirect:'error',signal:AbortSignal.timeout(15000)});
 if(!u.ok)return reply(401,'AUTH_REQUIRED');
 const user=await readJson(u.body,32768);
 const payload=authorization.split('.')[1];let claims;try{claims=JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(payload.replaceAll('-','+').replaceAll('_','/').padEnd(Math.ceil(payload.length/4)*4,'=')),c=>c.charCodeAt(0))));}catch{return reply(401,'AUTH_REQUIRED');}
 if(!claims||typeof claims!=='object'||Array.isArray(claims))return reply(401,'AUTH_REQUIRED');
 const now=clock();
 if(!uuid(user.id)||user.is_anonymous===true||claims.sub!==user.id||claims.role!=='authenticated'||!uuid(claims.session_id)||!['aal1','aal2'].includes(claims.aal)||!Number.isSafeInteger(claims.exp)||claims.exp<=now)return reply(401,'AUTH_REQUIRED');
 const response=await request(`${url}/rest/v1/rpc/csa136_authorize_video`,{method:'POST',headers:{Authorization:`Bearer ${sk}`,apikey:sk,'Content-Type':'application/json'},body:JSON.stringify({p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal,p_lesson:body.lesson_id.toLowerCase(),p_token_exp:claims.exp}),redirect:'error',signal:AbortSignal.timeout(15000)});
 const grant=await readJson(response.body,32768);
 if(!response.ok)return reply(grant?.code==='42501'?403:503,grant?.code==='42501'?'ACCESS_DENIED':'VIDEO_UNAVAILABLE');
 const signingNow=clock();
 if(grant?.lesson_id!==body.lesson_id.toLowerCase()||!Number.isSafeInteger(grant.expires_at)||grant.expires_at<=signingNow||grant.expires_at>claims.exp||grant.expires_at>now+300||!/^[A-Za-z0-9]{1,255}$/.test(grant.playback_id))return reply(503,'VIDEO_UNAVAILABLE');
 const token=await sign({playbackId:grant.playback_id,keyId:env('MUX_SIGNING_KEY_ID'),privateKey:env('MUX_SIGNING_PRIVATE_KEY_PEM'),now:signingNow,expiresAt:grant.expires_at});
 return reply(200,null,{lesson_id:grant.lesson_id,expires_at:grant.expires_at,playback_url:`https://stream.mux.com/${grant.playback_id}.m3u8?token=${token}`});
 }catch{return reply(503,'VIDEO_UNAVAILABLE');}
 };
}
