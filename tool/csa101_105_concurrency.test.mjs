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
test('CSA101–105 concurrent initialization and finalization on real PostgreSQL sessions', { skip: !enabled, timeout: 90000 }, async t => {
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
    const label = `csa105-${randomUUID().slice(0,8)}`;
    const first=worker(`begin;\n${firstSql};\n\\echo CSA105_READY\n`,`${label}-first`);
    let second;
    try {
      await until(()=>first.output().includes('CSA105_READY'),'first transaction must hold its write before second starts');
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
  const actor=randomUUID(), session=randomUUID(), course=randomUUID();
  const merchant=`synthetic-${actor}`;
  sql(`insert into auth.users(id) values('${actor}');
    insert into auth.sessions(id,user_id,aal,not_after) values('${session}','${actor}','aal1',now()+interval '1 day');
    insert into public.courses(id,slug,title,price_minor,status,published_at) values('${course}','csa105-${course}','Synthetic concurrent fulfillment',10000,'published',now());`);
  const makeOrder=()=>JSON.parse(sql(`select public.csa098_create_checkout_order('${actor}','${session}','aal1','${randomUUID()}','${course}','online')`)).data.order_id;
  const initialize=(order,key)=>`select public.csa101_initialize_checkout('${actor}','${session}','aal1','${key}','${order}','${merchant}','sandbox')`;
  const parsed=output=>JSON.parse(output.split('\n').find(line=>line.startsWith('{')));
  const attemptFrom=value=>value.data?.attemptId ?? value.attempt?.attemptId ?? value.data?.attempt?.attemptId;
  const finalize=(attempt,payment)=>`select public.csa104_finalize_payment('${attempt}','${merchant}','sandbox','payhere:received:${payment}','${'a'.repeat(64)}','${payment}',10000,'LKR',clock_timestamp(),'payhere:authenticated_retrieval:${payment}')`;

  await t.test('different initialization keys racing for one order reuse one bound attempt',async()=>{
    const order=makeOrder();
    const [a,b]=await race(initialize(order,'first'),initialize(order,'second'));
    const first=parsed(a.output), second=parsed(b.output);
    assert.ok(attemptFrom(first),'initialization must return a stored attempt');
    assert.equal(attemptFrom(first),attemptFrom(second));
    assert.equal(sql(`select count(*) from public.payment_attempts where order_id='${order}'`),'1');
  });

  await t.test('duplicate verified delivery concurrently commits one settlement/grant/outbox',async()=>{
    const order=makeOrder(), attempt=attemptFrom(JSON.parse(sql(initialize(order,'duplicate'))));
    const payment=`credit-${randomUUID()}`;
    const [a,b]=await race(finalize(attempt,payment),finalize(attempt,payment));
    assert.equal(parsed(a.output).outcome,'processed');
    assert.equal(parsed(b.output).outcome,'duplicate');
    assert.equal(sql(`select count(*) from app_private.verified_settlements where order_id='${order}'`),'1');
    assert.equal(sql(`select count(*) from public.enrollment_grants where source_order_id='${order}'`),'1');
    assert.equal(sql(`select count(*) from app_private.payment_events where payment_attempt_id='${attempt}'`),'1');
    assert.equal(sql(`select status from public.orders where id='${order}'`),'paid');
    assert.equal(sql(`select count(*) from app_private.notification_outbox where event_key='payment_verified:'||'${order}'`),'1');
    assert.equal(sql(`select count(*) from app_private.audit_logs where resource_id='${order}'`),'1');
  });

  await t.test('two actual payments for one order preserve extra money without double fulfillment',async()=>{
    // Direct synthetic owner fixture avoids already-enrolled checkout policy.
    const order=randomUUID();
    sql(`insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status)
      values('${order}','race-${order}','${actor}','${course}','Synthetic',10000,'LKR','online','pending_payment')`);
    const attempt=attemptFrom(JSON.parse(sql(initialize(order,'extra'))));
    const [a,b]=await race(finalize(attempt,`first-${randomUUID()}`),finalize(attempt,`extra-${randomUUID()}`));
    assert.equal(parsed(a.output).outcome,'processed');
    assert.equal(parsed(b.output).outcome,'reconciliation_required');
    assert.equal(sql(`select count(*) from app_private.verified_settlements where order_id='${order}'`),'2');
    assert.equal(sql(`select count(*) from public.enrollment_grants where source_order_id='${order}'`),'1');
  });
  await t.test('one retrieved settlement cannot concurrently fund distinct orders',async()=>{
    const orders=[randomUUID(),randomUUID()];
    for(const order of orders) {
      sql(`insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status)
        values('${order}','race-${order}','${actor}','${course}','Synthetic',10000,'LKR','online','pending_payment')`);
    }
    const attempts=orders.map((order,index)=>attemptFrom(JSON.parse(sql(initialize(order,`cross-order-${index}`)))));
    const payment=`shared-${randomUUID()}`;
    await race(finalize(attempts[0],payment),finalize(attempts[1],payment),3,'22023');
    assert.equal(sql(`select count(*) from app_private.verified_settlements where provider_merchant_id='${merchant}' and external_settlement_id='${payment}'`),'1');
    assert.equal(sql(`select count(*) from public.enrollment_grants where source_order_id in ('${orders[0]}','${orders[1]}')`),'1');
    assert.equal(sql(`select status from public.orders where id='${orders[1]}'`),'pending_payment');
  });

  // Synthetic fixtures remain only in the task-owned disposable database.
});
