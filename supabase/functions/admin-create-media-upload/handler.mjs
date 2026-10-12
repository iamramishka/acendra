import { Buffer } from 'node:buffer';
import { createHash } from 'node:crypto';
const uuid=v=>typeof v==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
const types={course_pdf:{'application/pdf':'pdf'},lesson_image:{'image/png':'png','image/jpeg':'jpg'},public_thumbnail:{'image/png':'png','image/jpeg':'jpg'}};
const magic={'application/pdf':[37,80,68,70,45],'image/png':[137,80,78,71,13,10,26,10],'image/jpeg':[255,216,255]};
const MAX_REQUEST_BYTES=8192;
const MAX_PDF_BYTES=50*1024*1024;
const MAX_THUMBNAIL_BYTES=5*1024*1024;
async function boundedJson(message,maxBytes=MAX_REQUEST_BYTES) {
 const reader=message.body?.getReader();if(!reader)throw Error('INVALID_REQUEST');
 let size=0;const chunks=[];
 try { while(true){const {done,value}=await reader.read();if(done)break;size+=value.byteLength;if(size>maxBytes){await reader.cancel();throw Error('REQUEST_TOO_LARGE');}chunks.push(value);} }
 finally{reader.releaseLock();}
 const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.byteLength;}
 return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
}

export function createHandler({env,fetch:request=globalThis.fetch,policy,inspector,mode='prepare'}) {
 if(!['prepare','finalize'].includes(mode))throw new TypeError('Invalid media handler mode');
 // Policy and inspector are injected by trusted deployment code, never request/env flags.
 const approved=policy&&typeof policy.reference==='string'&&/^[A-Za-z0-9._:-]{1,128}$/.test(policy.reference)&&Number.isInteger(policy.timeoutMs)&&policy.timeoutMs>0&&policy.timeoutMs<=30000&&Object.keys(types).filter(t=>t!=='public_thumbnail').every(t=>Number.isSafeInteger(policy.maxBytes?.[t])&&policy.maxBytes[t]>0)&&typeof inspector==='function';
 const config=approved?{reference:policy.reference,timeoutMs:policy.timeoutMs,maxBytes:{...policy.maxBytes,public_thumbnail:Math.min(policy.maxBytes.public_thumbnail??MAX_THUMBNAIL_BYTES,MAX_THUMBNAIL_BYTES)}}:null;
 return async incoming=>{
 const origin=incoming.headers.get('Origin');const allowed=new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS')??'http://127.0.0.1:8080').split(',').map(x=>x.trim()).filter(Boolean));
 const respond=(status,code,data)=>Response.json(code?{error:{code}}:{data},{status,headers:{'Cache-Control':'no-store','Vary':'Origin',...(origin&&allowed.has(origin)?{'Access-Control-Allow-Origin':origin}:{})}});
 if(origin!==null&&!allowed.has(origin))return respond(403,'ORIGIN_FORBIDDEN');
 if(incoming.method==='OPTIONS'){if(!origin||incoming.headers.get('Access-Control-Request-Method')!=='POST'||(incoming.headers.get('Access-Control-Request-Headers')??'').split(',').some(x=>x.trim()&&!['authorization','content-type','apikey','x-client-info'].includes(x.trim().toLowerCase())))return respond(403,'PREFLIGHT_FORBIDDEN');return new Response(null,{status:204,headers:{'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info','Vary':'Origin'}});}
 if(incoming.method!=='POST')return respond(405,'METHOD_NOT_ALLOWED');
 const authorization=incoming.headers.get('Authorization');if(!authorization?.startsWith('Bearer ')||authorization.length>16384)return respond(401,'AUTH_REQUIRED');
 let body;try{body=await boundedJson(incoming);}catch(e){return respond(e.message==='REQUEST_TOO_LARGE'?413:400,e.message==='REQUEST_TOO_LARGE'?'REQUEST_TOO_LARGE':'INVALID_REQUEST');}
 const fields=mode==='prepare'?['request_id','course_id','lesson_id','asset_type','file_name','content_type','size_bytes']:['asset_id','request_id'];
 if(!body||Array.isArray(body)||typeof body!=='object'||Object.keys(body).some(k=>!fields.includes(k))||!uuid(body.request_id))return respond(400,'INVALID_REQUEST');
 if(mode==='prepare'&&(!uuid(body.course_id)||(body.asset_type==='public_thumbnail'?body.lesson_id!=null:!uuid(body.lesson_id))||!types[body.asset_type]?.[body.content_type]||typeof body.file_name!=='string'||!/^[A-Za-z0-9][A-Za-z0-9._-]{0,99}\.(pdf|png|jpe?g)$/i.test(body.file_name)||!Number.isSafeInteger(body.size_bytes)||body.size_bytes<=0))return respond(400,'INVALID_REQUEST');
 if(mode==='finalize'&&!uuid(body.asset_id))return respond(400,'INVALID_REQUEST');
 for(const field of ['request_id','course_id','lesson_id','asset_id'])if(body[field])body[field]=body[field].toLowerCase();
 if(!config)return respond(503,'MEDIA_UPLOAD_UNAVAILABLE');
 if(mode==='prepare'&&(body.size_bytes>Math.min(config.maxBytes[body.asset_type],body.asset_type==='course_pdf'?MAX_PDF_BYTES:Number.MAX_SAFE_INTEGER)||({pdf:'application/pdf',png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg'}[body.file_name.split('.').at(-1).toLowerCase()]!==body.content_type)))return respond(400,'INVALID_REQUEST');
 const url=env('SUPABASE_URL'),pub=env('SUPABASE_ANON_KEY'),secret=env('SUPABASE_SERVICE_ROLE_KEY');if(!url||!pub||!secret)return respond(503,'SERVICE_UNAVAILABLE');
 const service={Authorization:`Bearer ${secret}`,apikey:secret};const opts={redirect:'error',signal:AbortSignal.timeout(15000)};
 try{
 const auth=await request(`${url}/auth/v1/user`,{...opts,headers:{Authorization:authorization,apikey:pub}});if(!auth.ok)return respond(401,'AUTH_REQUIRED');const user=await boundedJson(auth,65536);
 let claims;try{const parts=authorization.slice(7).split('.');if(parts.length!==3)throw Error();claims=JSON.parse(Buffer.from(parts[1],'base64url').toString('utf8'));}catch{return respond(401,'AUTH_REQUIRED');}
 if(!uuid(user.id)||user.is_anonymous===true||claims.sub!==user.id||claims.role!=='authenticated'||!uuid(claims.session_id)||!['aal1','aal2'].includes(claims.aal))return respond(401,'AUTH_REQUIRED');
 const identity={p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal};
 const rpc=async(name,args)=>{const r=await request(`${url}/rest/v1/rpc/${name}`,{...opts,method:'POST',headers:{...service,'Content-Type':'application/json'},body:JSON.stringify({...identity,...args})});const data=await boundedJson(r,65536);if(!r.ok){const err=new Error();err.sql=data.code;throw err;}return data;};
 const reserved=await rpc(mode==='prepare'?'csa164_prepare_media_upload':'csa164_get_media_upload',mode==='prepare'?{p_request_id:body.request_id,p_course:body.course_id,p_lesson:body.lesson_id??null,p_type:body.asset_type,p_mime:body.content_type,p_size:body.size_bytes,p_policy:config.reference}:{p_asset:body.asset_id});
 const extension=types[reserved?.asset_type]?.[reserved?.mime];
 const expectedBucket=reserved?.asset_type==='course_pdf'?'course-pdfs':'course-media';
 const expectedPath=reserved?.asset_type==='course_pdf'?`originals/${reserved.asset_id}/v1.pdf`:reserved?.asset_type==='public_thumbnail'?`${reserved.course_id}/thumbnails/${reserved.asset_id}.${extension}`:`${reserved.course_id}/${reserved.lesson_id}/${reserved.asset_id}.${extension}`;
 if(!uuid(reserved?.asset_id)||!uuid(reserved.course_id)||(reserved.asset_type==='public_thumbnail'?reserved.lesson_id!==null:!uuid(reserved.lesson_id))||!extension||reserved.bucket!==expectedBucket||reserved.path!==expectedPath||reserved.policy_reference!==config.reference||!Number.isSafeInteger(reserved.size)||reserved.size<=0||reserved.size>Math.min(config.maxBytes[reserved.asset_type],reserved.asset_type==='course_pdf'?MAX_PDF_BYTES:Number.MAX_SAFE_INTEGER)||(mode==='finalize'&&reserved.asset_id!==body.asset_id)||(mode==='prepare'&&(reserved.course_id!==body.course_id||reserved.lesson_id!==(body.lesson_id??null)||reserved.mime!==body.content_type||reserved.size!==body.size_bytes)))return respond(503,'SERVICE_UNAVAILABLE');
 if(mode==='prepare'){
 if(reserved.validated)return respond(200,undefined,{asset_id:reserved.asset_id,status:'validated'});
 const signed=await request(`${url}/storage/v1/object/upload/sign/${reserved.bucket}/${reserved.path}`,{...opts,method:'POST',headers:{...service,'Content-Type':'application/json','x-upsert':'false'},body:'{}'});if(!signed.ok)return respond(503,'SERVICE_UNAVAILABLE');const data=await boundedJson(signed,65536);if(typeof data.token!=='string'||!data.token)return respond(503,'SERVICE_UNAVAILABLE');
 return respond(201,undefined,{asset_id:reserved.asset_id,upload:{mode:'supabase_signed_upload',bucket:reserved.bucket,path:reserved.path,token:data.token}});
 }
 const stored=await request(`${url}/storage/v1/object/${reserved.bucket}/${reserved.path}`,{...opts,headers:service});if(!stored.ok)return respond(409,'ASSET_NOT_UPLOADED');
 if(stored.headers.get('Content-Type')!==reserved.mime)return respond(409,'ASSET_CONFLICT');
 const reader=stored.body?.getReader();if(!reader)return respond(422,'INVALID_MEDIA');let length=0;const chunks=[];try{while(true){const {done,value}=await reader.read();if(done)break;length+=value.length;if(length>reserved.size){await reader.cancel();return respond(409,'ASSET_CONFLICT');}chunks.push(value);}}finally{reader.releaseLock();}
 if(length!==reserved.size)return respond(409,'ASSET_CONFLICT');const bytes=new Uint8Array(length);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length;}
 if(!magic[reserved.mime].every((v,i)=>bytes[i]===v))return respond(422,'INVALID_MEDIA');const sha256=createHash('sha256').update(bytes).digest('hex');let timer;
 let verdict;try{verdict=await Promise.race([Promise.resolve().then(()=>inspector({bytes:bytes.slice(),mime:reserved.mime,size:length,sha256,policyReference:config.reference})),new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error()),config.timeoutMs);})]);}catch{return respond(422,'INSPECTION_FAILED');}finally{clearTimeout(timer);}
 if(verdict?.safe!==true||verdict.parseable!==true||verdict.encrypted!==false||verdict.withinResourceLimits!==true||verdict.sha256!==sha256||verdict.size!==length||verdict.mime!==reserved.mime||verdict.policyReference!==config.reference)return respond(422,'INSPECTION_FAILED');
 const result=await rpc('csa164_finalize_media_upload',{p_asset:reserved.asset_id,p_digest:sha256,p_size:length,p_mime:reserved.mime,p_policy:config.reference});return respond(200,undefined,result);
 }catch(e){const status={'42501':403,'22023':409,'23505':409,'P0002':404}[e.sql]??503;return respond(status,status===403?'FORBIDDEN':status===409?'ASSET_CONFLICT':status===404?'ASSET_NOT_FOUND':'SERVICE_UNAVAILABLE');}
 };
}
