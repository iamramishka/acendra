import {Buffer} from 'node:buffer';
import {createHash} from 'node:crypto';
const uuid=v=>typeof v==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
async function bounded(response,limit){
 const reader=response.body?.getReader();if(!reader)throw Error();
 const chunks=[];let length=0;try{while(true){const {done,value}=await reader.read();if(done)break;
 length+=value.byteLength;if(length>limit){await reader.cancel();throw Error();}chunks.push(value);}}finally{reader.releaseLock();}
 const bytes=new Uint8Array(length);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.byteLength;}return bytes;
}
export function createHandler({env,fetch:request=globalThis.fetch}){
 return async incoming=>{
 const headers={'Cache-Control':'no-store','Access-Control-Allow-Origin':'*','X-Content-Type-Options':'nosniff'};
 const fail=(status)=>Response.json({error:{code:status===404?'ARTWORK_NOT_FOUND':status===401?'AUTH_REQUIRED':'ARTWORK_UNAVAILABLE'}},{status,headers});
 if(incoming.method==='OPTIONS')return new Response(null,{status:204,headers:{...headers,'Access-Control-Allow-Methods':'GET','Access-Control-Allow-Headers':'authorization, apikey, x-client-info'}});
 if(incoming.method!=='GET')return fail(405);
 const query=new URL(incoming.url).searchParams,course=query.get('course_id');
 if(!uuid(course)||[...query.keys()].length!==1)return fail(400);
 const url=env('SUPABASE_URL'),secret=env('SUPABASE_SERVICE_ROLE_KEY'),pub=env('SUPABASE_ANON_KEY');
 if(!url||!secret||!pub)return fail(503);
 const opts={redirect:'error',signal:AbortSignal.timeout(15000)};
 try{
 let identity={p_actor:null,p_session_id:null,p_aal:null};
 const authorization=incoming.headers.get('Authorization');
 if(authorization){
 if(!authorization.startsWith('Bearer ')||authorization.length>16384)return fail(401);
 const auth=await request(url+'/auth/v1/user',{...opts,headers:{Authorization:authorization,apikey:pub}});
 if(!auth.ok)return fail(401);
 const user=JSON.parse(new TextDecoder().decode(await bounded(auth,65536)));
 let claims;try{const parts=authorization.slice(7).split('.');if(parts.length!==3)throw Error();claims=JSON.parse(Buffer.from(parts[1],'base64url').toString('utf8'));}catch{return fail(401);}
 if(!uuid(user.id)||user.is_anonymous===true||claims.sub!==user.id||claims.role!=='authenticated'||!uuid(claims.session_id)||!['aal1','aal2'].includes(claims.aal))return fail(401);
 identity={p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal};
 }
 const service={Authorization:'Bearer '+secret,apikey:secret};
 const resolve=async()=>{
 const response=await request(url+'/rest/v1/rpc/csa267_resolve_artwork',{...opts,method:'POST',
 headers:{...service,'Content-Type':'application/json'},body:JSON.stringify({p_course:course.toLowerCase(),...identity})});
 if(!response.ok){const error=Error();error.denied=[400,403,404].includes(response.status);throw error;}
 return JSON.parse(new TextDecoder().decode(await bounded(response,4096)));
 };
 const asset=await resolve();
 if(!asset)return fail(404);
 const extension={'image/png':'png','image/jpeg':'jpg'}[asset.mime];
 if(asset.course_id!==course.toLowerCase()||!uuid(asset.asset_id)||!extension||asset.bucket!=='course-media'||
 asset.path!==asset.course_id+'/thumbnails/'+asset.asset_id+'.'+extension||
 !Number.isSafeInteger(asset.size)||asset.size<1||asset.size>5242880||! /^[0-9a-f]{64}$/.test(asset.sha256))return fail(503);
 const response=await request(url+'/storage/v1/object/course-media/'+asset.path,{...opts,headers:service});
 if(!response.ok)return fail(503);
 const bytes=await bounded(response,asset.size);
 if(bytes.length!==asset.size||createHash('sha256').update(bytes).digest('hex')!==asset.sha256)return fail(503);
 // Do not serve an asset replaced or revoked during Storage IO.
 const current=await resolve();
 if(!current||current.asset_id!==asset.asset_id||current.sha256!==asset.sha256)return fail(404);
 return new Response(bytes,{headers:{...headers,'Content-Type':asset.mime,'Content-Length':String(bytes.length),
 'Content-Security-Policy':"default-src 'none'; sandbox",'Content-Disposition':'inline'}});
 }catch(error){return fail(error.denied?404:503);}
 };
}
