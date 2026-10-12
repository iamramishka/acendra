const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function selection(value,size) {
  if(value===null)return {start:0,end:size-1,partial:false};
  const match=/^bytes=(\d*)-(\d*)$/.exec(value);
  if(!match||(!match[1]&&!match[2]))throw Error('range');
  let start=match[1]?Number(match[1]):null,end=match[2]?Number(match[2]):null;
  if((start!==null&&!Number.isSafeInteger(start))||(end!==null&&!Number.isSafeInteger(end)))throw Error('range');
  if(start===null){if(end<=0)throw Error('range');start=Math.max(0,size-end);end=size-1;}
  else {if(start>=size||(end!==null&&end<start))throw Error('range');end=Math.min(end??size-1,size-1);}
  return {start,end,partial:true};
}
// Pull one upstream chunk per consumer demand; never enqueue beyond the declared boundary.
function bounded(body,length) {
  const reader=body.getReader();let received=0;
  return new ReadableStream({async pull(controller){try{const {done,value}=await reader.read();if(done){if(received!==length)throw Error('Truncated PDF');controller.close();return;}if(!(value instanceof Uint8Array)||received+value.byteLength>length)throw Error('Invalid PDF length');received+=value.byteLength;controller.enqueue(value);}catch{await reader.cancel().catch(()=>{});controller.error(Error('PDF delivery failed'));}},cancel(reason){return reader.cancel(reason);}}, {highWaterMark:0});
}
export function createHandler({authorize,storage,env=()=>'',enabled=false}={}) {
  return async request=>{
    const headers=new Headers({'Cache-Control':'private, no-store','X-Content-Type-Options':'nosniff','Vary':'Origin'});
    const reply=(code,status)=>new Response(request.method==='HEAD'?null:JSON.stringify({error:{code}}),{status,headers:new Headers([...headers,['Content-Type','application/json']])});
    const origin=request.headers.get('Origin');const allowed=(env('PDF_ALLOWED_ORIGINS')??'').split(',').map(x=>x.trim()).filter(Boolean);
    if(origin&&!allowed.includes(origin))return reply('ACCESS_DENIED',403);
    if(origin){headers.set('Access-Control-Allow-Origin',origin);headers.set('Access-Control-Expose-Headers','Accept-Ranges, Content-Range, Content-Length');}
    if(!enabled)return reply('SERVICE_UNAVAILABLE',503);
    if(request.method==='OPTIONS'){const method=request.headers.get('Access-Control-Request-Method');const requested=request.headers.get('Access-Control-Request-Headers');if(!origin||!['GET','HEAD'].includes(method)||(requested!==null&&requested.split(',').some(h=>!['authorization','range'].includes(h.trim().toLowerCase()))))return reply('ACCESS_DENIED',403);headers.set('Vary','Origin, Access-Control-Request-Method, Access-Control-Request-Headers');headers.set('Access-Control-Allow-Methods','GET, HEAD');headers.set('Access-Control-Allow-Headers','Authorization, Range');return new Response(null,{status:204,headers});}
    if(!['GET','HEAD'].includes(request.method))return reply('METHOD_NOT_ALLOWED',405);
    const url=new URL(request.url),lessonId=url.searchParams.get('lesson_id')?.toLowerCase()??null,resourceId=url.searchParams.get('resource_id')?.toLowerCase()??null;
    if(!UUID.test(lessonId??'')||(resourceId!==null&&!UUID.test(resourceId))||[...url.searchParams.keys()].some(k=>!['lesson_id','resource_id'].includes(k))||url.searchParams.getAll('lesson_id').length!==1||url.searchParams.getAll('resource_id').length>1)return reply('INVALID_REQUEST',400);
    try {
      const result=await authorize({authorization:request.headers.get('Authorization'),lessonId,resourceId});
      if(!result||!['ready','preparing'].includes(result.state)||result.lesson_id!==lessonId)throw Error('Invalid authorization result');
      if(result.state==='preparing'||resourceId===null){headers.set('Content-Type','application/json');return new Response(request.method==='HEAD'?null:JSON.stringify({data:{lesson_id:lessonId,mode:'proxied_stream',state:result.state,resource_id:result.state==='ready'?result.resource_id:null}}),{status:result.state==='preparing'?202:200,headers});}
      if(result.resource_id!==resourceId||!Number.isSafeInteger(result.size_bytes)||result.size_bytes<=0)throw Error('Invalid resource');
      let range;try{range=selection(request.headers.get('Range'),result.size_bytes);}catch{headers.set('Content-Range',`bytes */${result.size_bytes}`);return reply('INVALID_RANGE',416);}
      const length=range.end-range.start+1;
      headers.set('Content-Type','application/pdf');headers.set('Content-Disposition','inline; filename="course.pdf"');headers.set('Accept-Ranges','bytes');headers.set('Content-Length',String(length));
      if(range.partial)headers.set('Content-Range',`bytes ${range.start}-${range.end}/${result.size_bytes}`);
      if(request.method==='HEAD')return new Response(null,{status:range.partial?206:200,headers});
      const upstream=await storage.open({bucket:result.bucket,object_path:result.object_path,start:range.start,end:range.end,size_bytes:result.size_bytes});
      const full=range.start===0&&range.end===result.size_bytes-1;
      if(!(upstream instanceof Response)||!upstream.body||upstream.status!==(full?200:206)||upstream.headers.get('Content-Type')?.split(';')[0].trim().toLowerCase()!=='application/pdf'||upstream.headers.get('Content-Length')!==String(length)||(upstream.headers.get('Content-Encoding')&&upstream.headers.get('Content-Encoding')!=='identity')||(!full&&upstream.headers.get('Content-Range')!==`bytes ${range.start}-${range.end}/${result.size_bytes}`)){await upstream?.body?.cancel().catch(()=>{});throw Error('Invalid upstream');}
      return new Response(bounded(upstream.body,length),{status:range.partial?206:200,headers});
    }catch(error){for(const name of ['Content-Length','Content-Range','Accept-Ranges','Content-Disposition'])headers.delete(name);const code=['AUTH_REQUIRED','ACCESS_DENIED','PDF_NOT_FOUND'].includes(error?.code)?error.code:'SERVICE_UNAVAILABLE';return reply(code,{AUTH_REQUIRED:401,ACCESS_DENIED:403,PDF_NOT_FOUND:404,SERVICE_UNAVAILABLE:503}[code]);}
  };
}
