// Explicit local/backend worker invocation only. Never runs on Flutter/Edge.
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { runPdfJob } from './pdf_worker.mjs';
const limit=50*1024*1024;
export function createWorkerRuntime({env=name=>process.env[name],fetch:request=globalThis.fetch}={}) {
 const base=env('SUPABASE_URL'),key=env('SUPABASE_SERVICE_ROLE_KEY'),python=env('PDF_WORKER_PYTHON'),font=env('PDF_WORKER_FONT');
 const url=new URL(base);
 if(url.protocol!=='https:'||url.username||url.password||url.search||url.hash||url.pathname!=='/'||!key||!python||!font)throw Error('PDF_WORKER_CONFIGURATION_REQUIRED');
 const headers={Authorization:`Bearer ${key}`,apikey:key};
 async function rpc(name,args={}) {
  const response=await request(`${url.origin}/rest/v1/rpc/${name}`,{method:'POST',headers:{...headers,'Content-Type':'application/json'},body:JSON.stringify(args),redirect:'error',signal:AbortSignal.timeout(15000)});
  if(!response.ok)throw Error('PDF_WORKER_RPC_FAILED');
  const reader=response.body?.getReader();if(!reader)throw Error('PDF_WORKER_RPC_FAILED');
  let total=0;const chunks=[];try{while(true){const {value,done}=await reader.read();if(done)break;total+=value.length;if(total>16384){await reader.cancel();throw Error('PDF_WORKER_RPC_FAILED');}chunks.push(value);}}finally{reader.releaseLock();}
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
 }
 const objectUrl=path=>`${url.origin}/storage/v1/object/course-pdfs/${path.split('/').map(encodeURIComponent).join('/')}`;
 const storage={
  download:({path})=>request(objectUrl(path),{headers,redirect:'error',signal:AbortSignal.timeout(15000)}),
  async upload({path,bytes}){const response=await request(objectUrl(path),{method:'POST',headers:{...headers,'Content-Type':'application/pdf','x-upsert':'false'},body:bytes,redirect:'error',signal:AbortSignal.timeout(15000)});if(response.ok)return {created:true};if(response.status===409||response.status===400)return {created:false};throw Error('PDF_UPLOAD_FAILED');},
  async exists({path}){const response=await request(objectUrl(path),{method:'HEAD',headers,redirect:'error',signal:AbortSignal.timeout(15000)});if(response.status===404)return false;if(!response.ok)throw Error('PDF_STORAGE_FAILED');return true;}
 };
 async function generate(source,identity) {
  if(process.platform!=='linux'||process.getuid?.()===0)throw Error('PDF_WORKER_RUNTIME_REQUIRED');
  return new Promise((resolve,reject)=>{
   // No shell, credentials, inherited secrets or font selection from a client.
   const child=spawn(python,[fileURLToPath(new URL('./pdf_watermark/process_job.py',import.meta.url))],{env:{PATH:process.env.PATH??'',LANG:'C.UTF-8'},stdio:['pipe','pipe','ignore'],windowsHide:true});
   const chunks=[];let size=0;const timer=setTimeout(()=>{child.kill('SIGKILL');reject(Error('PDF_GENERATION_FAILED'));},65000);
   child.stdout.on('data',chunk=>{size+=chunk.length;if(size>limit){child.kill('SIGKILL');reject(Error('PDF_GENERATION_FAILED'));}else chunks.push(chunk);});
   child.on('error',()=>{clearTimeout(timer);reject(Error('PDF_GENERATION_FAILED'));});
   child.stdin.on('error',()=>{});
   child.on('close',code=>{clearTimeout(timer);if(code!==0||size===0||size>limit)reject(Error('PDF_GENERATION_FAILED'));else resolve(new Uint8Array(Buffer.concat(chunks)));});
   child.stdin.end(JSON.stringify({source:Buffer.from(source).toString('base64'),identity:{...identity,trusted_font_path:font}}));
  });
 }
 return {rpc,storage,generate};
}
if(process.argv[1]===fileURLToPath(import.meta.url)) {
 if(process.env.PDF_WORKER_ENABLED!=='true'){process.stderr.write('PDF_WORKER_DISABLED\n');process.exitCode=1;}
 else try {const result=await runPdfJob(createWorkerRuntime());process.stdout.write(result.state==='completed'?'PDF_JOB_PROCESSED\n':'PDF_JOB_IDLE\n');}
 catch{process.stderr.write('PDF_JOB_FAILED\n');process.exitCode=1;}
}
