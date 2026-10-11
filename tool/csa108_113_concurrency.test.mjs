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
test('CSA108–113 receipt and bank review races on real PostgreSQL sessions', { skip: !enabled, timeout: 90000 }, async t => {
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
    const label = `csa113-${randomUUID().slice(0,8)}`;
    const first=worker(`begin;\n${firstSql};\n\\echo CSA113_READY\n`,`${label}-first`);
    let second;
    try {
      await until(()=>first.output().includes('CSA113_READY'),'first transaction must hold its write before second starts');
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
  const buyer=randomUUID(), reviewer=randomUUID(), admin=randomUUID();
  const buyerSession=randomUUID(), reviewerSession=randomUUID(), adminSession=randomUUID(), course=randomUUID(), bank=randomUUID(), version=randomUUID();
  sql(`insert into auth.users(id) values('${buyer}'),('${reviewer}'),('${admin}');
    insert into auth.sessions(id,user_id,aal,not_after) values('${buyerSession}','${buyer}','aal1',now()+interval '1 day'),('${reviewerSession}','${reviewer}','aal2',now()+interval '1 day'),('${adminSession}','${admin}','aal2',now()+interval '1 day');
    insert into public.user_roles(user_id,role_id) select '${reviewer}',id from public.roles where code='finance_admin';
    insert into public.user_roles(user_id,role_id) select '${admin}',id from public.roles where code='super_admin';
    insert into public.courses(id,slug,title,price_minor,status,published_at) values('${course}','bankrace-${course}','Synthetic bank race',10000,'published',now());
    insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name,currency_code)
      values('${version}','${bank}',1,'Synthetic bank','Synthetic holder','TEST-ONLY','Synthetic branch','LKR');`);
  const makeOrder=()=>JSON.parse(sql(`select public.csa098_create_checkout_order('${buyer}','${buyerSession}','aal1','${randomUUID()}','${course}','bank_transfer','${version}')`)).data.order_id;
  const prepare=(order,key)=>`select public.csa108_prepare_receipt('${buyer}','${buyerSession}','aal1','${key}','${order}','${'a'.repeat(64)}',100,'image/png','png')`;
  const parsed=output=>JSON.parse(output.split('\n').find(line=>line.startsWith('{')));
  function ready(order,key=randomUUID()) {
    const upload=JSON.parse(sql(prepare(order,key)));
    sql(`insert into storage.objects(bucket_id,name) values('bank-receipts','${upload.object_path}')`);
    sql(`select public.csa109_finalize_receipt('${buyer}','${buyerSession}','aal1','${upload.upload_id}','${'a'.repeat(64)}',100,'image/png','synthetic-inspection')`);
    return upload.submission_id;
  }
  const credit=(order,payment)=>JSON.stringify({bank_credit_confirmed:true,destination_account_id:bank,bank_transaction_id:payment,amount_minor:'10000',currency:'LKR',settled_at:'2026-10-11T00:00:00Z',source:'bank_statement',order_reference:sql(`select order_number from public.orders where id='${order}'`)});
  const approve=(submission,order,payment,key)=>`select public.csa112_review_bank_transfer('${reviewer}','${reviewerSession}','aal2','${key}','${submission}','approve','${credit(order,payment)}'::jsonb,null,'Synthetic independent bank verification')`;
  const reject=(submission,key)=>`select public.csa112_review_bank_transfer('${reviewer}','${reviewerSession}','aal2','${key}','${submission}','reject',null,'Synthetic safe rejection','Synthetic private reviewer note')`;

  await t.test('same-key receipt reservations serialize to one object and submission',async()=>{
    const order=makeOrder();
    const [a,b]=await race(prepare(order,'same-upload'),prepare(order,'same-upload'));
    assert.equal(parsed(a.output).upload_id,parsed(b.output).upload_id);
    assert.equal(sql(`select count(*) from public.bank_transfer_submissions where order_id='${order}'`),'1');
  });
  await t.test('same approved review retry commits one settlement source audit and notice',async()=>{
    const order=makeOrder(),submission=ready(order),payment=`bank-${randomUUID()}`;
    const [a,b]=await race(approve(submission,order,payment,'same-review'),approve(submission,order,payment,'same-review'));
    assert.equal(parsed(a.output).status,'approved'); assert.equal(parsed(b.output).replayed,true);
    assert.equal(sql(`select count(*) from app_private.verified_settlements where order_id='${order}'`),'1');
    assert.equal(sql(`select count(*) from public.enrollment_grants where source_order_id='${order}'`),'1');
    assert.equal(sql(`select count(*) from app_private.bank_transfer_reviews where submission_id='${submission}'`),'1');
    assert.equal(sql(`select count(*) from app_private.notification_outbox where event_key='bank_review:'||'${submission}'`),'1');
  });
  function pendingOrder() {
    const order=randomUUID();
    sql(`insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status)
      values('${order}','race-${order}','${buyer}','${course}','Synthetic bank race',10000,'LKR','bank_transfer','pending_payment');
      insert into app_private.order_bank_instructions(order_id,bank_account_version_id,instruction_snapshot)
      select '${order}',id,jsonb_build_object('bank_name',bank_name,'account_holder',account_holder,'account_number',account_number,'branch_name',branch_name,'currency_code',currency_code) from app_private.bank_account_versions where id='${version}'`);
    return order;
  }
  await t.test('concurrent approval versus rejection cannot commit opposing decisions',async()=>{
    const order=pendingOrder(),submission=ready(order);
    await race(approve(submission,order,`winner-${randomUUID()}`,'approve-winner'),reject(submission,'reject-loser'),3,'55000');
    assert.equal(sql(`select status from public.bank_transfer_submissions where id='${submission}'`),'approved');
    assert.equal(sql(`select count(*) from app_private.bank_transfer_reviews where submission_id='${submission}'`),'1');
  });
  await t.test('same independently confirmed bank credit cannot fund two orders',async()=>{
    const orders=[pendingOrder(),pendingOrder()],submissions=orders.map(order=>ready(order)),payment=`shared-bank-${randomUUID()}`;
    await race(approve(submissions[0],orders[0],payment,'credit-first'),approve(submissions[1],orders[1],payment,'credit-second'),3,'23505');
    assert.equal(sql(`select count(*) from app_private.verified_settlements where receiving_bank_account_scope='${bank}' and external_settlement_id='${payment}'`),'1');
    assert.equal(sql(`select status from public.orders where id='${orders[1]}'`),'pending_verification');
  });
  await t.test('role revocation committed before bank review denies formerly authorized reviewer',async()=>{
    const order=pendingOrder(),submission=ready(order);
    const revoke=`select public.csa073_change_role('${admin}','${adminSession}','aal2','${reviewer}','finance_admin','revoke','Synthetic revocation','${randomUUID()}')`;
    await race(revoke,approve(submission,order,`revoked-${randomUUID()}`,'revoked-review'),3,'42501');
    assert.equal(sql(`select count(*) from app_private.bank_transfer_reviews where submission_id='${submission}'`),'0');
    assert.equal(sql(`select status from public.orders where id='${order}'`),'pending_verification');
  });
});
