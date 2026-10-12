import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
test('CSA165 real concurrent publication authority and readiness',{skip:process.env.ACENDRA_FINANCIAL_CONCURRENCY!=='1',timeout:90000},async t=>{
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
  const label=`csa165-${randomUUID().slice(0,8)}`;const first=worker(`begin;\n${a};\n\\echo READY\n`,label+'-a');let second;
  try {await until(()=>first.output().includes('READY'));second=worker(`begin;\n${b};\ncommit;\n`,label+'-b');second.child.stdin.end();
   if(block) await until(()=>sql(`select count(*) from pg_stat_activity where application_name='${label}-b' and wait_event_type='Lock'`)==='1');
   else await second.done;
   first.child.stdin.end('commit;\n');const results=await Promise.all([first.done,second.done]);assert.equal(results[0].code,0,results[0].error);return results;
  } finally {first.child.stdin.end();second?.child.stdin.end();if(first.child.exitCode===null)first.child.kill();if(second&&second.child.exitCode===null)second.child.kill();}
 };
 const fixture=()=>{
  const admin=randomUUID(),session=randomUUID(),course=randomUUID(),section=randomUUID(),lesson=randomUUID(),asset=randomUUID();
  sql(`insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('course-pdfs','course-pdfs',false,52428800,array['application/pdf']) on conflict(id) do nothing;
   insert into auth.users(id) values('${admin}');insert into auth.sessions(id,user_id,aal,not_after) values('${session}','${admin}','aal2',now()+interval '1 day');
   insert into public.user_roles(user_id,role_id) select '${admin}',id from public.roles where code='super_admin';
   insert into public.courses(id,slug,title,description,short_description,price_minor) values('${course}','race-${course}','Synthetic','Description','Summary',10000);
   insert into public.course_sections(id,course_id,title,position,is_published) values('${section}','${course}','Section',0,true);
   insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values('${lesson}','${section}','PDF','pdf',0,true);
   insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,checksum_sha256,validation_status,validated_at)
   values('${asset}','course_pdf','supabase','course-pdfs','originals/${asset}/v1.pdf','application/pdf',1000,repeat('a',64),'validated',clock_timestamp());
   insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values('${lesson}','${asset}','primary',0);`);
  const stamp=sql(`select updated_at from public.courses where id='${course}'`);
  return {admin,session,course,asset,publish:key=>`select public.csa165_publish_course('${admin}','${session}','aal2','${course}','${stamp}','publish','${key}')`};
 };
 const parsed=r=>JSON.parse(r.output.split('\n').find(x=>x.startsWith('{')));
 await t.test('same key replays once and competing stale command conflicts',async()=>{
  const f=fixture();const [a,b]=await race(f.publish('same-key'),f.publish('same-key'));
  assert.equal(b.code,0,b.error);assert.equal(parsed(a).replayed,false);assert.equal(parsed(b).replayed,true);
  assert.equal(sql(`select count(*) from app_private.csa165_publication_audit where course_id='${f.course}'`),'1');
  const g=fixture();const results=await race(g.publish('first-key'),`\\set VERBOSITY verbose\n${g.publish('different-key')}`);
  assert.notEqual(results[1].code,0);assert.match(results[1].error,/40001/);
  assert.equal(sql(`select count(*) from app_private.csa165_publication_audit where course_id='${g.course}'`),'1');
 });
 await t.test('revocation holding authority lock denies waiting publisher',async()=>{
  const f=fixture();const results=await race(`select pg_advisory_xact_lock(610061);update public.user_roles set revoked_at=clock_timestamp() where user_id='${f.admin}'`,`\\set VERBOSITY verbose\n${f.publish('revoked')}`);
  assert.notEqual(results[1].code,0);assert.match(results[1].error,/42501/);
  assert.equal(sql(`select status from public.courses where id='${f.course}'`),'draft');
  assert.equal(sql(`select count(*) from app_private.csa165_publication_audit where course_id='${f.course}'`),'0');
 });
 await t.test('uncommitted media rejection blocks publication then fails readiness',async()=>{
  const f=fixture();const results=await race(`update app_private.media_assets set validation_status='rejected' where id='${f.asset}'`,`\\set VERBOSITY verbose\n${f.publish('rejected-media')}`);
  assert.notEqual(results[1].code,0);assert.match(results[1].error,/23514/);
  assert.equal(sql(`select status from public.courses where id='${f.course}'`),'draft');
  assert.equal(sql(`select count(*) from app_private.csa165_publication_audit where course_id='${f.course}'`),'0');
 });
});
