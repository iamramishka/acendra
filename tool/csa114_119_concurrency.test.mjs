import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
test('CSA114–119 serialized grant/revocation and independent notification leases',{skip:process.env.ACENDRA_FINANCIAL_CONCURRENCY!=='1',timeout:90000},async t=>{
 const env={...process.env};let command,args,docker=false;
 if(env.ACENDRA_FINANCIAL_PG_PORT) {
  assert.match(env.ACENDRA_FINANCIAL_PG_PORT,/^\d{4,5}$/);assert.ok(+env.ACENDRA_FINANCIAL_PG_PORT>=1024&&+env.ACENDRA_FINANCIAL_PG_PORT<=65535);
  command=env.ACENDRA_FINANCIAL_PSQL??'psql';args=['-h','127.0.0.1','-p',env.ACENDRA_FINANCIAL_PG_PORT,'-U','postgres','-d',env.ACENDRA_ENTITLEMENT_TEST_DB??'postgres'];
 } else {
  docker=true;command=process.platform==='win32'?'docker.exe':'docker';const call=a=>spawnSync(command,a,{env,encoding:'utf8',timeout:20000});pinLocalDockerEndpoint(env,call);
  const profile=env.ACENDRA_FINANCIAL_PROFILE??'test';assert.ok(['dev','test'].includes(profile));const layout=createLayout(root,profile,env.ACENDRA_LOCAL_PORT_BASE);
  const id=call(['ps','-q','--filter',`name=^/supabase_db_${layout.projectId}$`]).stdout.trim();assert.match(id,/^[a-f0-9]{12,64}$/);
  args=['exec','-i',id,'psql','-U','postgres','-d','postgres'];
 }
 const sql=s=>{const r=spawnSync(command,[...args,'-X','-v','ON_ERROR_STOP=1','-qAt','-c',s],{env,encoding:'utf8',timeout:15000});assert.equal(r.status,0,r.stderr);return r.stdout.trim();};
 const worker=(s,label)=>{
  const a=docker?['exec','-e',`PGAPPNAME=${label}`,...args.slice(1)]:args;
  const child=spawn(command,[...a,'-X','-v','ON_ERROR_STOP=1','-qAt'],{env:{...env,PGAPPNAME:label},stdio:['pipe','pipe','pipe']});
  let output='',error='';child.stdout.on('data',x=>output+=x);child.stderr.on('data',x=>error+=x);
  const done=new Promise((resolve,reject)=>{child.on('error',reject);child.on('close',code=>resolve({code,output,error}));});child.stdin.write(s);return {child,done,output:()=>output};
 };
 const until=async predicate=>{const deadline=Date.now()+10000;while(Date.now()<deadline){if(predicate())return;await new Promise(r=>setTimeout(r,40));}assert.fail('Required real database interleaving did not occur');};
 const race=async(a,b,block=true)=>{
  const label=`csa119-${randomUUID().slice(0,8)}`;const first=worker(`begin;\n${a};\n\\echo READY\n`,label+'-a');let second;
  try {await until(()=>first.output().includes('READY'));second=worker(`begin;\n${b};\ncommit;\n`,label+'-b');second.child.stdin.end();
   if(block) await until(()=>sql(`select count(*) from pg_stat_activity where application_name='${label}-b' and wait_event_type='Lock'`)==='1');
   else await second.done;
   first.child.stdin.end('commit;\n');const results=await Promise.all([first.done,second.done]);for(const r of results)assert.equal(r.code,0,r.error);return results;
  } finally {first.child.stdin.end();second?.child.stdin.end();if(first.child.exitCode===null)first.child.kill();if(second&&second.child.exitCode===null)second.child.kill();}
 };
 const buyer=randomUUID(),admin=randomUUID(),bs=randomUUID(),ads=randomUUID(),course=randomUUID();
 sql(`insert into auth.users(id) values('${buyer}'),('${admin}');insert into auth.sessions(id,user_id,aal,not_after) values('${bs}','${buyer}','aal1',now()+interval '1 day'),('${ads}','${admin}','aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select '${admin}',id from public.roles where code='super_admin';
 insert into public.courses(id,slug,title,price_minor,status,published_at) values('${course}','entitlement-race-${course}','Synthetic race',10000,'published',now());`);
 const grant=k=>`select public.csa116_grant_admin('${admin}','${ads}','aal2','${k}','${buyer}','${course}','Synthetic reason',null)`;
 const access=()=>sql(`select public.csa117_check_entitlement('${buyer}','${bs}','aal1','${course}')`);
 const parsed=r=>JSON.parse(r.output.split('\n').find(x=>x.startsWith('{')));
 await t.test('same-key concurrent grants commit one source audit and notification',async()=>{
  const [a,b]=await race(grant('grant-replay'),grant('grant-replay'));assert.equal(parsed(a).grant_id,parsed(b).grant_id);assert.equal(parsed(b).replayed,true);
  assert.equal(sql(`select count(*) from public.enrollment_grants where user_id='${buyer}'`),'1');
  assert.equal(sql(`select count(*) from app_private.audit_logs where actor_user_id='${admin}' and request_id='grant-replay'`),'1');
 });
 function payment() {
  const order=randomUUID(),attempt=randomUUID(),settlement=randomUUID();
  sql(`insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status) values('${order}','RACE-${order}','${buyer}','${course}','Synthetic race',10000,'LKR','online','pending_payment');
   insert into public.payment_attempts(id,order_id,method,provider,provider_session_id,amount_minor,currency_code,provider_merchant_id,provider_environment) values('${attempt}','${order}','online','payhere','${attempt}',10000,'LKR','synthetic','sandbox');`);
  return `select public.csa104_finalize_payment('${attempt}','synthetic','sandbox','payhere:received:${settlement}','${'a'.repeat(64)}','${settlement}',10000,'LKR',now(),'payhere:authenticated_retrieval:${settlement}')`;
 }
 await t.test('source-specific revocation concurrent with purchase preserves new paid grant',async()=>{
  const gid=sql(`select id from public.enrollment_grants where user_id='${buyer}' and source_type='admin_grant'`);
  await race(`select public.csa118_revoke_access('${admin}','${ads}','aal2','source-revoke','${buyer}','${course}','${gid}','grant','Synthetic reason')`,payment());
  assert.equal(access(),'t');assert.equal(sql(`select count(*) from public.enrollment_grants where user_id='${buyer}' and invalidated_at is null and source_type='online_payment'`),'1');
 });
 await t.test('course restriction concurrent with purchase cannot be bypassed by new grant',async()=>{
  await race(`select public.csa118_revoke_access('${admin}','${ads}','aal2','course-restrict','${buyer}','${course}',null,'course','Synthetic safety')`,payment());assert.equal(access(),'f');
  assert.equal(sql(`select status from public.enrollments where user_id='${buyer}' and course_id='${course}'`),'revoked');
 });
 await t.test('concurrent outbox workers skip uncommitted leased rows',async()=>{
  // The disposable fixture may contain other suites' notices. Temporarily defer
  // only pending notices; no live service/database is accepted by this runner.
  sql(`update app_private.notification_outbox set next_attempt_at=now()+interval '1 day' where status='pending';
   insert into app_private.notification_outbox(event_key,recipient_user_id,notification_type,safe_payload) values('lease-${buyer}','${buyer}','payment_verified','{}');`);
  const [a,b]=await race('select public.csa119_claim_notifications(1)','select public.csa119_claim_notifications(1)',false);
  const first=JSON.parse(a.output.split('\n').find(x=>x.startsWith('[')));const second=JSON.parse(b.output.split('\n').find(x=>x.startsWith('[')));
  assert.equal(first.length,1);assert.equal(second.length,0);assert.equal(sql(`select attempt_count from app_private.notification_outbox where event_key='lease-${buyer}'`),'1');
 });
});
