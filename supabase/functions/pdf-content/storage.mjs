export function createStorage({env,fetchImpl=fetch}) {
  return {async open({bucket,object_path,start,end,size_bytes}) {
    const base=env('SUPABASE_URL'),key=env('SUPABASE_SERVICE_ROLE_KEY');
    if(!base||!key||!bucket||!object_path||object_path.split('/').some(x=>!x||x==='.'||x==='..'))throw Error('Storage unavailable');
    const url=new URL(base);if(url.protocol!=='https:'&&!(url.protocol==='http:'&&['localhost','127.0.0.1'].includes(url.hostname)))throw Error('Storage unavailable');
    url.pathname=`/storage/v1/object/authenticated/${encodeURIComponent(bucket)}/${object_path.split('/').map(encodeURIComponent).join('/')}`;url.search='';url.hash='';
    return fetchImpl(url,{method:'GET',redirect:'error',headers:{Authorization:`Bearer ${key}`,apikey:key,'Accept-Encoding':'identity',...(start===0&&end===size_bytes-1?{}:{Range:`bytes=${start}-${end}`})}});
  }};
}
