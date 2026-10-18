// Read-only admin payment list. Authorization is rechecked in PostgreSQL; this
// boundary validates input, signs cursors and allowlists the response shape.
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TS=/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/;
const DEC=/^(0|[1-9]\d{0,18})$/;
const INT64_MAX=9223372036854775807n;
const STATUSES=['pending','processing','approved','rejected'];
const METHODS=['online','bank_transfer'];
const CURSOR_TTL_MS=15*60*1000;
const LIST_KEYS=['mode','page_size','cursor','status','method','from','to','order_number_prefix'];
const ITEM_KEYS=['payment_id','order_id','order_number','course_id','course_title','amount_minor','currency_code','method','status','created_at','updated_at','settled_at'];
const COUNT_KEYS=['pending','processing','approved','rejected','total'];

const isUuid=x=>typeof x==='string'&&UUID.test(x);
const isObject=x=>x!==null&&typeof x==='object'&&!Array.isArray(x);
const exact=(x,keys)=>isObject(x)&&Object.keys(x).length===keys.length&&keys.every(k=>Object.hasOwn(x,k));
const isDate=x=>typeof x==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(x)&&!Number.isNaN(Date.parse(x))&&new Date(x).toISOString().slice(0,10)===x;
const isDecimal=x=>typeof x==='string'&&DEC.test(x)&&BigInt(x)<=INT64_MAX;
const isText=(x,max)=>typeof x==='string'&&x.length>=1&&x.length<=max&&/[^\s]/.test(x);
const enc=new TextEncoder();
const b64=bytes=>btoa(String.fromCharCode(...new Uint8Array(bytes))).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');
const unb64=text=>{const p=text.replaceAll('-','+').replaceAll('_','/');return Uint8Array.from(atob(p.padEnd(Math.ceil(p.length/4)*4,'=')),x=>x.charCodeAt(0));};

async function readJson(body,max){
 const reader=body?.getReader();if(!reader)throw Error('INVALID');
 const chunks=[];let size=0;
 try{while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>max){await reader.cancel();throw Error('TOO_LARGE');}chunks.push(value);}}finally{reader.releaseLock();}
 const bytes=new Uint8Array(size);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length;}
 return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
}

function validate(body){
 if(exact(body,['mode','payment_id'])&&body.mode==='detail'&&isUuid(body.payment_id))return {mode:'detail',paymentId:body.payment_id};
 if(!exact(body,LIST_KEYS)||body.mode!=='list')return null;
 const {page_size:size,cursor,status,method,from,to,order_number_prefix:prefix}=body;
 if(!Number.isInteger(size)||size<1||size>50)return null;
 if(cursor!==null&&(typeof cursor!=='string'||cursor.length<1||cursor.length>512))return null;
 if(status!==null&&!STATUSES.includes(status))return null;
 if(method!==null&&!METHODS.includes(method))return null;
 if((from===null)!==(to===null))return null;
 if(from!==null&&(!isDate(from)||!isDate(to)||to<from||(Date.parse(to)-Date.parse(from))/86400000>365))return null;
 if(prefix!==null&&(typeof prefix!=='string'||!/^[A-Za-z0-9-]{1,40}$/.test(prefix)))return null;
 return {mode:'list',size,cursor,status,method,from,to,prefix};
}

function validateItem(item){
 if(!exact(item,ITEM_KEYS))return false;
 if(!isUuid(item.payment_id)||!isUuid(item.order_id)||!isUuid(item.course_id))return false;
 if(!isText(item.order_number,100)||!isText(item.course_title,200)||!isDecimal(item.amount_minor)||item.currency_code!=='LKR')return false;
 if(!METHODS.includes(item.method)||!STATUSES.includes(item.status)||!TS.test(item.created_at)||!TS.test(item.updated_at))return false;
 // settled_at exists exactly when the order is approved by a verified settlement.
 return item.status==='approved'?TS.test(item.settled_at):item.settled_at===null;
}
function validateCounts(c){
 if(!exact(c,COUNT_KEYS)||!COUNT_KEYS.every(k=>isDecimal(c[k])))return false;
 return BigInt(c.pending)+BigInt(c.processing)+BigInt(c.approved)+BigInt(c.rejected)===BigInt(c.total);
}
const pick=(o,keys)=>Object.fromEntries(keys.map(k=>[k,o[k]]));

export function createHandler({env,fetch:request=globalThis.fetch,enabled=false,now=()=>Date.now()}){
 const url=env('SUPABASE_URL'),publicKey=env('SUPABASE_ANON_KEY'),serviceKey=env('SUPABASE_SERVICE_ROLE_KEY');
 const origins=new Set((env('ACENDRA_ADMIN_ALLOWED_ORIGINS')??'http://127.0.0.1:8080').split(',').map(x=>x.trim()).filter(Boolean));
 const sign=async payload=>{
  const key=await crypto.subtle.importKey('raw',enc.encode(serviceKey),{name:'HMAC',hash:'SHA-256'},false,['sign','verify']);
  return {key,mac:b64(await crypto.subtle.sign('HMAC',key,enc.encode(payload)))};
 };
 const filterHash=async f=>b64(await crypto.subtle.digest('SHA-256',enc.encode(JSON.stringify([f.status,f.method,f.from,f.to,f.prefix?.toLowerCase()??null]))));
 const makeCursor=async(last,asOf,actor,f)=>{
  const payload=b64(enc.encode(JSON.stringify({v:1,c:last.created_at,i:last.payment_id,a:asOf,u:actor,f:await filterHash(f)})));
  return `${payload}.${(await sign(payload)).mac}`;
 };
 const readCursor=async(cursor,actor,f)=>{
  const parts=cursor.split('.');if(parts.length!==2||!/^[A-Za-z0-9_-]+$/.test(parts[0])||!/^[A-Za-z0-9_-]+$/.test(parts[1]))return null;
  try{
   const {key}=await sign('');
   const mac=unb64(parts[1]);
   if(!await crypto.subtle.verify('HMAC',key,mac,enc.encode(parts[0])))return null;
   const c=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(unb64(parts[0])));
   if(!exact(c,['v','c','i','a','u','f'])||c.v!==1||!TS.test(c.c)||!isUuid(c.i)||!TS.test(c.a)||c.u!==actor||c.f!==await filterHash(f))return null;
   const age=now()-Date.parse(c.a);if(!(age>=-60000&&age<=CURSOR_TTL_MS))return null;
   return c;
  }catch{return null;}
 };

 return async incoming=>{
  const origin=incoming.headers.get('Origin');
  const respond=(status,code,data)=>Response.json(code?{error:{code}}:{data},{status,headers:{'Cache-Control':'no-store',Vary:'Origin',...(origin&&origins.has(origin)?{'Access-Control-Allow-Origin':origin}:{})}});
  if(enabled!==true)return respond(503,'REPORTING_UNAVAILABLE');
  if(origin!==null&&!origins.has(origin))return respond(403,'ORIGIN_FORBIDDEN');
  if(incoming.method==='OPTIONS'){
   const headers=(incoming.headers.get('Access-Control-Request-Headers')??'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);
   if(!origin||incoming.headers.get('Access-Control-Request-Method')!=='POST'||headers.some(x=>!['authorization','content-type','apikey','x-client-info'].includes(x)))return respond(403,'PREFLIGHT_FORBIDDEN');
   return new Response(null,{status:204,headers:{'Cache-Control':'no-store',Vary:'Origin','Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'Authorization, Content-Type, apikey, x-client-info'}});
  }
  if(incoming.method!=='POST')return respond(405,'METHOD_NOT_ALLOWED');
  const authorization=incoming.headers.get('Authorization');
  if(!authorization?.startsWith('Bearer ')||authorization.length>16384)return respond(401,'AUTH_REQUIRED');
  if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(incoming.headers.get('Content-Type')??''))return respond(415,'UNSUPPORTED_MEDIA_TYPE');
  let raw;try{raw=await readJson(incoming.body,8192);}catch{return respond(400,'INVALID_REQUEST');}
  const input=validate(raw);if(!input)return respond(400,'INVALID_REQUEST');
  if(!url||!publicKey||!serviceKey)return respond(503,'SERVICE_UNAVAILABLE');
  try{
   const auth=await request(`${url}/auth/v1/user`,{headers:{Authorization:authorization,apikey:publicKey},redirect:'error',signal:AbortSignal.timeout(15000)});
   if(!auth.ok)return respond(401,'AUTH_REQUIRED');
   const user=await readJson(auth.body,32768);
   const token=authorization.slice(7).split('.');if(token.length!==3)return respond(401,'AUTH_REQUIRED');
   let claims;try{const p=token[1].replaceAll('-','+').replaceAll('_','/');claims=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(atob(p.padEnd(Math.ceil(p.length/4)*4,'=')),x=>x.charCodeAt(0))));}catch{return respond(401,'AUTH_REQUIRED');}
   if(!isUuid(user?.id)||user.is_anonymous===true||claims?.sub!==user.id||claims?.role!=='authenticated'||!isUuid(claims?.session_id)||!['aal1','aal2'].includes(claims?.aal))return respond(401,'AUTH_REQUIRED');
   // Only finance_admin/super_admin may read payments and both require AAL2; SQL rechecks roles and AAL.
   if(claims.aal!=='aal2')return respond(403,'ADMIN_PERMISSION_REQUIRED');
   let rpc,args,cursor=null;
   if(input.mode==='detail'){
    rpc='csapaylist_admin_payment_detail';args={p_payment_id:input.paymentId};
   }else{
    if(input.cursor!==null){cursor=await readCursor(input.cursor,user.id,input);if(!cursor)return respond(400,'INVALID_REQUEST');}
    rpc='csapaylist_admin_payment_list';
    args={p_page_size:input.size,p_after_created_at:cursor?.c??null,p_after_id:cursor?.i??null,p_as_of:cursor?.a??null,p_status:input.status,p_method:input.method,p_from:input.from,p_to:input.to,p_prefix:input.prefix};
   }
   const response=await request(`${url}/rest/v1/rpc/${rpc}`,{method:'POST',headers:{Authorization:`Bearer ${serviceKey}`,apikey:serviceKey,'Content-Type':'application/json'},body:JSON.stringify({p_actor:user.id,p_session_id:claims.session_id,p_aal:claims.aal,...args}),redirect:'error',signal:AbortSignal.timeout(15000)});
   const result=await readJson(response.body,131072);
   if(!response.ok){
    const code=result?.code;
    if(code==='42501')return respond(403,'ADMIN_PERMISSION_REQUIRED');
    if(code==='22023')return respond(400,'INVALID_REQUEST');
    if(code==='P0002'&&input.mode==='detail')return respond(404,'RESOURCE_NOT_FOUND');
    return respond(503,'REPORTING_UNAVAILABLE');
   }
   if(input.mode==='detail'){
    if(!exact(result,['item','as_of'])||!validateItem(result.item)||!TS.test(result.as_of))return respond(503,'REPORTING_UNAVAILABLE');
    return respond(200,null,{item:pick(result.item,ITEM_KEYS),as_of:result.as_of});
   }
   if(!exact(result,['items','has_more','counts','as_of'])||!Array.isArray(result.items)||result.items.length>input.size||typeof result.has_more!=='boolean'
    ||!result.items.every(validateItem)||!validateCounts(result.counts)||!TS.test(result.as_of)||(result.has_more&&result.items.length!==input.size))return respond(503,'REPORTING_UNAVAILABLE');
   const next=result.has_more?await makeCursor(result.items.at(-1),result.as_of,user.id,input):null;
   return respond(200,null,{items:result.items.map(i=>pick(i,ITEM_KEYS)),next_cursor:next,counts:pick(result.counts,COUNT_KEYS),as_of:result.as_of,count_basis:'current_snapshot'});
  }catch{return respond(503,'SERVICE_UNAVAILABLE');}
 };
}
