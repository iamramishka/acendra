// Versioned reviewable deployment policy; a matching explicit opt-in is required.
// Parser service enforces CPU/memory/wall limits independently of this HTTP timeout.
export const MEDIA_POLICY = Object.freeze({
 reference:'csa267-media-v1',timeoutMs:25000,
 maxBytes:Object.freeze({course_pdf:50*1024*1024,lesson_image:5*1024*1024,public_thumbnail:5*1024*1024}),
});
export function inspectionRuntime(env, request=globalThis.fetch) {
 let url;try{url=new URL(env('ACENDRA_MEDIA_INSPECTOR_URL'));}catch{return {};}
 const key=env('ACENDRA_MEDIA_INSPECTOR_KEY');
 if(url.protocol!=='https:'||url.username||url.password||url.hash||url.search||
    typeof key!=='string'||key.length<32||key.length>256||
    env('ACENDRA_MEDIA_POLICY')!==MEDIA_POLICY.reference)return {};
 return {policy:MEDIA_POLICY,inspector:async input=>{
  const response=await request(url.href,{method:'POST',redirect:'error',
   signal:AbortSignal.timeout(MEDIA_POLICY.timeoutMs),
   headers:{Authorization:'Bearer '+key,'Content-Type':input.mime,
    'X-Media-SHA256':input.sha256,'X-Media-Policy':input.policyReference,
    'Content-Length':String(input.size)},body:input.bytes});
  if(!response.ok)throw Error('INSPECTION_FAILED');
  const reader=response.body?.getReader();if(!reader)throw Error('INSPECTION_FAILED');
  const chunks=[];let size=0;try{while(true){const {done,value}=await reader.read();if(done)break;
   size+=value.byteLength;if(size>4096){await reader.cancel();throw Error('INSPECTION_FAILED');}chunks.push(value);
  }}finally{reader.releaseLock();}
  const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.byteLength;}
  return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
 }};
}
