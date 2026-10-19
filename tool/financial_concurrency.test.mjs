import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const enabled = process.env.ACENDRA_FINANCIAL_CONCURRENCY === '1';
function connection() {
  const env = { ...process.env };
  if (env.ACENDRA_FINANCIAL_PG_PORT) {
    assert.match(env.ACENDRA_FINANCIAL_PG_PORT, /^\d{4,5}$/);
    assert.ok(Number(env.ACENDRA_FINANCIAL_PG_PORT) >= 1024 && Number(env.ACENDRA_FINANCIAL_PG_PORT) <= 65535);
    return { command: env.ACENDRA_FINANCIAL_PSQL ?? 'psql', args: ['-h','127.0.0.1','-p',env.ACENDRA_FINANCIAL_PG_PORT,'-U','postgres','-d','postgres'], env };
  }
  const command = process.platform === 'win32' ? 'docker.exe' : 'docker';
  const call = args => spawnSync(command,args,{env,encoding:'utf8',timeout:20000});
  pinLocalDockerEndpoint(env, call);
  assert.equal(call(['info','--format','{{.OSType}}']).stdout.trim(),'linux');
  const profile = env.ACENDRA_FINANCIAL_PROFILE ?? 'dev';
  assert.ok(['dev', 'test'].includes(profile));
  const layout = createLayout(root,profile,env.ACENDRA_LOCAL_PORT_BASE);
  const result = call(['ps','-q','--filter',`name=^/supabase_db_${layout.projectId}$`]);
  assert.equal(result.status,0); const id = result.stdout.trim();
  assert.match(id,/^[a-f0-9]{12,64}$/,'Exactly one task-owned disposable development database required');
  return { command, args: ['exec','-i',id,'psql','-U','postgres','-d','postgres'], env, docker: true };
}
test('financial races on independent real PostgreSQL sessions', { skip: !enabled, timeout: 90000 }, async t => {
  const target = connection();
  function sql(statement) {
    const result = spawnSync(target.command,[...target.args,'-X','-v','ON_ERROR_STOP=1','-qAt','-c',statement],{env:target.env,encoding:'utf8',timeout:15000});
    assert.equal(result.status,0,`Synthetic SQL failed: ${result.stderr}`); return result.stdout.trim();
  }
  function worker(statement, label) {
    const args = target.docker ? ['exec','-e',`PGAPPNAME=${label}`,...target.args.slice(1)] : target.args;
    const child = spawn(target.command,[...args,'-X','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-qAt'],
      {env:{...target.env,PGAPPNAME:label},stdio:['pipe','pipe','pipe']});
    let output='', error='';
    child.stdout.on('data',chunk=>{output+=chunk;}); child.stderr.on('data',chunk=>{error+=chunk;});
    const done = new Promise((resolve,reject)=>{child.on('error',reject); child.on('close',code=>resolve({code,output,error}));});
    child.stdin.write(statement);
    return { child, done, output:()=>output };
  }
  async function until(predicate, description) {
    const deadline=Date.now()+10000;
    while (Date.now()<deadline) { if(predicate()) return; await new Promise(resolve=>setTimeout(resolve,40)); }
    assert.fail(description);
  }
  async function race(firstSql, secondSql, expectedSecondCode=0, expectedSqlstate) {
    const label = `csa71-${randomUUID().slice(0,8)}`;
    const first=worker(`begin;\n${firstSql};\n\\echo CSA71_READY\n`,`${label}-first`);
    let second;
    try {
      await until(()=>first.output().includes('CSA71_READY'),'first transaction must hold its write before second starts');
      second=worker(`begin;\n${secondSql};\ncommit;\n`,`${label}-second`); second.child.stdin.end();
      // Observe an actual blocked database backend, not a timing assumption.
      await until(()=>sql(`select count(*) from pg_stat_activity where application_name='${label}-second' and wait_event_type='Lock'`)==='1','second transaction must contend on held database lock');
      first.child.stdin.end('commit;\n');
      const [a,b]=await Promise.all([first.done,second.done]);
      assert.equal(a.code,0,a.error); assert.equal(b.code,expectedSecondCode,b.error);
      if(expectedSqlstate) assert.match(b.error,new RegExp(expectedSqlstate));
      return [a,b];
    } finally {
      first.child.stdin.end(); if(second) second.child.stdin.end();
      if(first.child.exitCode===null) first.child.kill(); if(second?.child.exitCode===null) second.child.kill();
    }
  }
  const actor=randomUUID(), other=randomUUID(), session=randomUUID(), otherSession=randomUUID(), course=randomUUID();
  sql(`insert into auth.users(id) values('${actor}'),('${other}');
    insert into auth.sessions(id,user_id,aal,not_after) values('${session}','${actor}','aal1',now()+interval '1 day'),('${otherSession}','${other}','aal1',now()+interval '1 day');
    insert into public.courses(id,slug,title,price_minor,status,published_at) values('${course}','race-${course}','Synthetic concurrency course',10000,'published',now());`);
  const checkout = (key,method='online',user=actor,sid=session) => `select public.csa098_create_checkout_order('${user}','${sid}','aal1','${key}','${course}','${method}')`;
  await t.test('same principal/key simultaneous retries create exactly one immutable order',async()=>{
    const [a,b]=await race(checkout('same-key'),checkout('same-key'));
    const first=JSON.parse(a.output.split('\n').find(line=>line.startsWith('{')));
    const second=JSON.parse(b.output.split('\n').find(line=>line.startsWith('{')));
    assert.equal(first.replayed,false); assert.equal(second.replayed,true); assert.deepEqual(first.data,second.data);
    assert.equal(sql(`select count(*) from app_private.idempotency_records where principal_scope='user:${actor}' and idempotency_key='same-key'`),'1');
    assert.equal(sql(`select count(*) from public.orders where id='${first.data.order_id}'`),'1');
  });
  await t.test('concurrent changed payload conflicts after winning key commits',async()=>{
    await race(checkout('changed-key'),checkout('changed-key','bank_transfer'),3,'22023');
    assert.equal(sql(`select safe_result->>'payment_method' from app_private.idempotency_records where principal_scope='user:${actor}' and idempotency_key='changed-key'`),'online');
  });
  await t.test('different principals can use same key independently',async()=>{
    const first=worker(`begin;\n${checkout('isolated')};\n\\echo CSA71_READY\n`,'csa71-independent-first');
    let second;
    try {
      await until(()=>first.output().includes('CSA71_READY'),'first transaction ready');
      second=worker(`${checkout('isolated','online',other,otherSession)};\n`,'csa71-independent-second'); second.child.stdin.end();
      const b=await second.done; assert.equal(b.code,0,b.error);
      first.child.stdin.end('commit;\n'); const a=await first.done; assert.equal(a.code,0,a.error);
      assert.equal(sql(`select count(*) from app_private.idempotency_records where idempotency_key='isolated' and principal_scope in ('user:${actor}','user:${other}')`),'2');
    } finally { first.child.stdin.end(); if(first.child.exitCode===null) first.child.kill(); if(second?.child.exitCode===null) second.child.kill(); }
  });
  const orderA=randomUUID(), orderB=randomUUID(), bankOrder=randomUUID();
  await t.test('CSA-265 different keys for one buyer/course serialize to one open order',async()=>{
    const guardedCourse=randomUUID();
    sql(`insert into public.courses(id,slug,title,price_minor,status,published_at) values('${guardedCourse}','guarded-${guardedCourse}','Synthetic guarded course',10000,'published',now());`);
    const guarded=key=>`select public.csa265_create_checkout_order('${actor}','${session}','aal1','${key}','${guardedCourse}','online')`;
    await race(guarded('guarded-first'),guarded('guarded-second'),3,'22023');
    assert.equal(sql(`select count(*) from public.orders where buyer_id='${actor}' and course_id='${guardedCourse}' and status='pending_payment'`),'1');
    assert.equal(JSON.parse(sql(guarded('guarded-first'))).replayed,true);
  });
  sql(`insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method) values
    ('${orderA}','race-${orderA}','${actor}','${course}','Synthetic',10000,'LKR','online'),
    ('${orderB}','race-${orderB}','${actor}','${course}','Synthetic',10000,'LKR','online'),
    ('${bankOrder}','race-${bankOrder}','${actor}','${course}','Synthetic',10000,'LKR','bank_transfer');`);
  const settlement = order => `insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at) values('${order}','online',10000,'LKR','payhere','synthetic-${actor}','sandbox','same-credit','provider_retrieval','synthetic-only',now())`;
  await t.test('one scoped external settlement cannot concurrently fund two orders',async()=>{
    await race(settlement(orderA),settlement(orderB),3,'23505');
    assert.equal(sql(`select count(*) from app_private.verified_settlements where provider_merchant_id='synthetic-${actor}' and external_settlement_id='same-credit'`),'1');
  });
  const submission = `insert into public.bank_transfer_submissions(order_id,submitted_by) values('${bankOrder}','${actor}')`;
  await t.test('partial unique constraint prevents simultaneous active bank submissions',async()=>{
    await race(submission,submission,3,'23505');
    assert.equal(sql(`select count(*) from public.bank_transfer_submissions where order_id='${bankOrder}'`),'1');
  });
  // Records live only in the task-owned disposable database, stopped by CI.
});
