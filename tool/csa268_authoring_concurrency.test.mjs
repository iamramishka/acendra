import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';

test('CSA268 real authoring races preserve revisions and revocation', { skip: process.env.ACENDRA_FINANCIAL_CONCURRENCY !== '1', timeout: 90000 }, async t => {
  const env = { ...process.env };
  let command, args;
  if (env.ACENDRA_FINANCIAL_PG_PORT) {
    assert.match(env.ACENDRA_FINANCIAL_PG_PORT, /^\d{4,5}$/);
    assert.ok(+env.ACENDRA_FINANCIAL_PG_PORT >= 1024 && +env.ACENDRA_FINANCIAL_PG_PORT <= 65535);
    command = env.ACENDRA_FINANCIAL_PSQL ?? 'psql';
    const database = env.ACENDRA_ENTITLEMENT_TEST_DB ?? 'postgres';
    assert.match(database, /^[a-z][a-z0-9_]{0,62}$/);
    args = ['-h', '127.0.0.1', '-p', env.ACENDRA_FINANCIAL_PG_PORT, '-U', 'postgres', '-d', database];
  } else {
    command = process.platform === 'win32' ? 'docker.exe' : 'docker';
    const call = a => spawnSync(command, a, { env, encoding: 'utf8', timeout: 20000 });
    pinLocalDockerEndpoint(env, call);
    const profile = env.ACENDRA_FINANCIAL_PROFILE ?? 'test';
    assert.ok(['dev', 'test'].includes(profile));
    const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
    const layout = createLayout(root, profile, env.ACENDRA_LOCAL_PORT_BASE);
    const id = call(['ps', '-q', '--filter', `name=^/supabase_db_${layout.projectId}$`]).stdout.trim();
    assert.match(id, /^[a-f0-9]{12,64}$/);
    args = ['exec', '-i', id, 'psql', '-U', 'postgres', '-d', 'postgres'];
  }
  const sql = statement => {
    const r = spawnSync(command, [...args, '-X', '-v', 'ON_ERROR_STOP=1', '-qAt', '-c', statement], { env, encoding: 'utf8', timeout: 15000 });
    assert.equal(r.status, 0, r.stderr); return r.stdout.trim();
  };
  const worker = statement => {
    const child = spawn(command, [...args, '-X', '-v', 'ON_ERROR_STOP=1', '-qAt'], { env, stdio: ['pipe', 'pipe', 'pipe'] });
    let output = '', error = '';
    child.stdout.on('data', x => output += x); child.stderr.on('data', x => error += x);
    const done = new Promise((resolve, reject) => { child.on('error', reject); child.on('close', code => resolve({ code, output, error })); });
    child.stdin.write(statement); return { child, done, output: () => output };
  };
  const until = async fn => { const limit = Date.now() + 10000; while (Date.now() < limit) { if (fn()) return; await new Promise(r => setTimeout(r, 40)); } assert.fail('Required database interleaving did not occur'); };
  const fixture = () => {
    const actor = randomUUID(), session = randomUUID(), course = randomUUID();
    sql(`insert into auth.users(id) values('${actor}');
      insert into auth.sessions(id,user_id,aal,not_after) values('${session}','${actor}','aal1',now()+interval '1 day');
      insert into public.user_roles(user_id,role_id) select '${actor}',id from public.roles where code='content_manager';
      insert into public.courses(id,title,slug,price_minor) values('${course}','Race course','csa268-race-${course}',12345);
      insert into public.course_staff(course_id,user_id,staff_role,assigned_by) values('${course}','${actor}','owner','${actor}');`);
    const stamp = sql(`select updated_at from public.courses where id='${course}'`);
    const payload = JSON.stringify({ title: 'Persisted edit', slug: `csa268-race-${course}`, category_id: null, short_description: 'Summary', description: 'Description', price_minor: '12346', currency_code: 'LKR' });
    return { actor, session, course, update: () => `select public.csa268_manage_course('${actor}','${session}','aal1','update','${course}','${stamp}','${randomUUID()}','${payload}'::jsonb)` };
  };
  await t.test('two edits from the same original revision commit exactly once', async () => {
    const f = fixture(); const first = worker(`begin;\n${f.update()};\n\\echo READY\n`); let second;
    try {
      await until(() => first.output().includes('READY'));
      second = worker(`begin;\n${f.update()};\ncommit;\n`); second.child.stdin.end();
      await until(() => sql("select count(*) from pg_stat_activity where wait_event_type='Lock' and query like '%csa268_manage_course%' and pid<>pg_backend_pid()") === '1');
      first.child.stdin.end('commit;\n');
      const [a, b] = await Promise.all([first.done, second.done]);
      assert.equal(a.code, 0, a.error); assert.equal(b.code, 3, b.error); assert.match(b.error, /Course changed/);
      assert.equal(sql(`select count(*) from app_private.csa268_authoring_audit where course_id='${f.course}'`), '1');
      assert.equal(sql(`select price_minor from public.courses where id='${f.course}'`), '12346');
    } finally { first.child.stdin.end(); second?.child.stdin.end(); if (first.child.exitCode === null) first.child.kill(); if (second?.child.exitCode === null) second.child.kill(); }
  });
  await t.test('assignment revocation wins before a waiting write is authorized', async () => {
    const f = fixture(); const first = worker(`begin; select pg_advisory_xact_lock(610061); update public.course_staff set revoked_at=clock_timestamp() where course_id='${f.course}';\n\\echo READY\n`); let second;
    try {
      await until(() => first.output().includes('READY'));
      second = worker(`begin;\n${f.update()};\ncommit;\n`); second.child.stdin.end();
      await until(() => sql("select count(*) from pg_stat_activity where wait_event_type='Lock' and query like '%csa268_manage_course%' and pid<>pg_backend_pid()") === '1');
      first.child.stdin.end('commit;\n');
      const [a, b] = await Promise.all([first.done, second.done]);
      assert.equal(a.code, 0, a.error); assert.equal(b.code, 3, b.error); assert.match(b.error, /assignment required/);
      assert.equal(sql(`select count(*) from app_private.csa268_authoring_audit where course_id='${f.course}'`), '0');
      assert.equal(sql(`select price_minor from public.courses where id='${f.course}'`), '12345');
    } finally { first.child.stdin.end(); second?.child.stdin.end(); if (first.child.exitCode === null) first.child.kill(); if (second?.child.exitCode === null) second.child.kill(); }
  });
});
