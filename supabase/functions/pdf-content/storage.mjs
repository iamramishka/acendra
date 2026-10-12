export function createStorage({env,fetchImpl=fetch}) {
  const uuid='[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
  const derivative=new RegExp(`^derivatives/${uuid}/v[1-9][0-9]*/${uuid}/${uuid}\\.pdf$`,'i');
  return {async open({bucket,object_path,start,end,size_bytes}) {
    const base=env('SUPABASE_URL'),key=env('SUPABASE_SERVICE_ROLE_KEY');
    if(!base||!key||bucket!=='course-pdfs'||typeof object_path!=='string'||!derivative.test(object_path))throw Error('Storage unavailable');
    const url=new URL(base);if(url.username||url.password||(url.protocol!=='https:'&&!(url.protocol==='http:'&&['localhost','127.0.0.1'].includes(url.hostname))))throw Error('Storage unavailable');
    url.pathname=`/storage/v1/object/authenticated/${encodeURIComponent(bucket)}/${object_path.split('/').map(encodeURIComponent).join('/')}`;url.search='';url.hash='';
    return fetchImpl(url,{method:'GET',redirect:'error',signal:AbortSignal.timeout(15000),headers:{Authorization:`Bearer ${key}`,apikey:key,'Accept-Encoding':'identity',...(start===0&&end===size_bytes-1?{}:{Range:`bytes=${start}-${end}`})}});
  }};
}
