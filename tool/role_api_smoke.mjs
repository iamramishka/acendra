// Run only against the task-owned disposable development stack on hosted CI.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createHmac, randomBytes, randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const layout = createLayout(root, 'dev', process.env.ACENDRA_LOCAL_PORT_BASE);
const dockerEnv = { ...process.env };
let stage = 'local target guard';
function docker(args) {
  const result = spawnSync('docker', args, { env: dockerEnv, encoding: 'utf8' });
  assert.equal(result.status, 0, 'Task-owned Docker operation');
  return result.stdout.trim();
}
function totp(secret) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const char of secret.replace(/=+$/, '').toUpperCase()) {
    const index = alphabet.indexOf(char);
    assert.ok(index >= 0);
    bits += index.toString(2).padStart(5, '0');
  }
  const key = Buffer.from(bits.match(/.{8}/g).map(byte => parseInt(byte, 2)));
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000)));
  const hash = createHmac('sha1', key).update(counter).digest();
  const offset = hash[19] & 15;
  return ((hash.readUInt32BE(offset) & 0x7fffffff) % 1000000).toString().padStart(6, '0');
}

async function main() {
  pinLocalDockerEndpoint(dockerEnv, args => spawnSync('docker', args, { env: dockerEnv, encoding: 'utf8' }));
  const config = JSON.parse(fs.readFileSync(path.join(root, 'config/development.local.json'), 'utf8'));
  const base = `http://127.0.0.1:${layout.portBase}`;
  assert.equal(config.SUPABASE_URL, base);
  const key = config.SUPABASE_PUBLISHABLE_KEY;
  const items = JSON.parse(docker(['inspect', ...docker(['ps', '-q', '--filter', `network=${layout.projectId}-loopback`]).split(/\s+/).filter(Boolean)]));
  const db = items.find(item => item.Name === `/supabase_db_${layout.projectId}`);
  assert.ok(db, 'Expected task-owned database');
  const sql = statement => docker(['exec', db.Id, 'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-qAt', '-c', statement]);
  async function request(route, token, body) {
    const result = await fetch(base + route, { method: 'POST',
      headers: { apikey: key, 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: JSON.stringify(body), signal: AbortSignal.timeout(30000) });
    return { status: result.status, data: result.status === 204 ? null : await result.json() };
  }
  async function signup() {
    const email = `role-${randomBytes(8).toString('hex')}@example.com`;
    const password = randomBytes(24).toString('hex') + 'Aa!1';
    const result = await request('/auth/v1/signup', undefined, { email, password });
    assert.equal(result.status, 200);
    const id = result.data.user?.id ?? result.data.id;
    assert.match(id, /^[0-9a-f-]{36}$/);
    // Operator confirms only this disposable synthetic MFA fixture account.
    // Auth security smoke separately exercises the provider verification token.
    sql(`update auth.users set email_confirmed_at=coalesce(email_confirmed_at,now()) where id='${id}';`);
    const login = await request('/auth/v1/token?grant_type=password', undefined, { email, password });
    assert.equal(login.status, 200);
    assert.ok(login.data.access_token && login.data.user?.id === id);
    return { id, token: login.data.access_token };
  }
  async function mfa(user) {
    const factor = await request('/auth/v1/factors', user.token, { factor_type: 'totp', friendly_name: 'Synthetic CI TOTP' });
    assert.equal(factor.status, 200);
    assert.ok(factor.data.totp?.secret && factor.data.id);
    const challenge = await request(`/auth/v1/factors/${factor.data.id}/challenge`, user.token, {});
    assert.equal(challenge.status, 200);
    const verified = await request(`/auth/v1/factors/${factor.data.id}/verify`, user.token,
      { challenge_id: challenge.data.id, code: totp(factor.data.totp.secret) });
    assert.equal(verified.status, 200);
    assert.ok(verified.data.access_token);
    return verified.data.access_token;
  }
  stage = 'real signup and operator bootstrap';
  const admin = await signup();
  const target = await signup();
  const nextAdmin = await signup();
  sql(`select public.csa061_bootstrap_super_admin('${admin.id}','Synthetic CI first admin','${randomUUID()}');`);
  const body = { student_id: target.id, role_code: 'finance_admin', action: 'grant', reason: 'Synthetic approved reviewer', request_id: randomUUID() };
  const endpoint = '/functions/v1/admin-assign-user-role';
  stage = 'real Flutter Web browser preflight';
  const preflight = await fetch(base + endpoint, { method: 'OPTIONS', headers: {
    Origin: 'http://127.0.0.1:8080', 'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'authorization,content-type,apikey,x-client-info',
  }, signal: AbortSignal.timeout(30000) });
  // CLI Kong answers OPTIONS before the worker with permissive gateway CORS.
  // Test browser compatibility there, and enforce the origin boundary on POST.
  assert.ok([200,204].includes(preflight.status));
  assert.ok(['*','http://127.0.0.1:8080'].includes(preflight.headers.get('Access-Control-Allow-Origin')));
  const allowedHeaders = preflight.headers.get('Access-Control-Allow-Headers')?.toLowerCase().split(',').map(value => value.trim());
  assert.ok(['authorization','content-type','apikey','x-client-info'].every(value => allowedHeaders?.includes(value)));
  const deniedOrigin = await fetch(base + endpoint, { method: 'POST', headers: {
    Origin: 'https://unapproved.example', Authorization: `Bearer ${admin.token}`,
    apikey: key, 'Content-Type': 'application/json',
  }, body: JSON.stringify(body), signal: AbortSignal.timeout(30000) });
  assert.equal(deniedOrigin.status, 403);
  assert.equal((await deniedOrigin.json()).error.code, 'ORIGIN_FORBIDDEN');
  stage = 'MFA and caller injection denial';
  assert.equal((await request(endpoint, admin.token, body)).status, 403);
  assert.equal((await request(endpoint, target.token, body)).status, 403);
  assert.equal((await request(endpoint, admin.token, { ...body, p_actor: admin.id })).status, 400);
  const forged = admin.token.split('.');
  const claims = JSON.parse(Buffer.from(forged[1], 'base64url'));
  forged[1] = Buffer.from(JSON.stringify({ ...claims, aal: 'aal2' })).toString('base64url');
  assert.ok([401,403].includes((await request(endpoint, forged.join('.'), body)).status));
  assert.equal((await request('/rest/v1/rpc/csa061_change_role', admin.token,
    { p_actor: admin.id, p_aal: 'aal2', p_target: target.id, p_code: 'finance_admin', p_action: 'grant', p_reason: 'Forged browser RPC', p_request_id: randomUUID() })).status, 403);
  stage = 'real TOTP verification and audited mutation';
  const token = await mfa(admin);
  const result = await request(endpoint, token, body);
  assert.equal(result.status, 200);
  assert.equal(result.data.data.status, 'active');
  const replay = await request(endpoint, token, body);
  assert.equal(replay.status, 200);
  assert.equal(replay.data.data.replayed, true);
  assert.equal(sql(`select count(*) from public.csa061_role_audit where request_id='${body.request_id}';`), '1');
  assert.equal((await request(endpoint, token, { ...body, student_id: admin.id, role_code: 'super_admin', action: 'revoke', request_id: randomUUID() })).status, 403);
  assert.equal((await request(endpoint, token, { ...body, action: 'revoke', request_id: randomUUID() })).status, 200);
  assert.equal((await request(endpoint, token, body)).data.data.status, 'revoked');
  stage = 'concurrent admin revocation preserves authority';
  stage = 'real course creation and public draft isolation';
  const courseEndpoint = '/functions/v1/create-course';
  const courseBody = { title: 'Synthetic trusted draft', slug: `ci-draft-${randomBytes(8).toString('hex')}`, request_id: randomUUID() };
  assert.equal((await request(courseEndpoint, admin.token, courseBody)).status, 403);
  assert.equal((await request(courseEndpoint, target.token, courseBody)).status, 403);
  assert.equal((await request(courseEndpoint, token, { ...courseBody, price_minor: 1 })).status, 400);
  assert.ok([401,403].includes((await request(courseEndpoint, forged.join('.'), courseBody)).status));
  const created = await request(courseEndpoint, token, courseBody);
  assert.equal(created.status, 200);
  const courseId = created.data.data.course_id;
  assert.match(courseId, /^[0-9a-f-]{36}$/i);
  assert.equal(created.data.data.status, 'draft');
  assert.equal((await request(courseEndpoint, token, courseBody)).data.data.course_id, courseId);
  assert.equal((await request(courseEndpoint, token, { ...courseBody, title: 'Changed replay' })).status, 409);
  assert.equal(sql(`select count(*) from app_private.csa089_course_creation_audit where actor_id='${admin.id}' and request_id='${courseBody.request_id}';`), '1');
  assert.equal(sql(`select count(*) from public.course_staff where course_id='${courseId}' and user_id='${admin.id}' and staff_role='owner' and revoked_at is null;`), '1');
  for (const callerToken of [undefined, token]) {
    const publicResult = await fetch(`${base}/rest/v1/courses?select=id,title&id=eq.${courseId}`, {
      headers: { apikey: key, ...(callerToken ? { Authorization: `Bearer ${callerToken}` } : {}) }, signal: AbortSignal.timeout(30000),
    });
    assert.equal(publicResult.status, 200);
    assert.deepEqual(await publicResult.json(), []);
  }
  assert.equal((await request(endpoint, token, { ...body, role_code: 'content_manager', request_id: randomUUID() })).status, 200);
  const managerBody = { ...courseBody, slug: `ci-manager-${randomBytes(8).toString('hex')}`, request_id: randomUUID() };
  assert.equal((await request(courseEndpoint, target.token, managerBody)).status, 200);
  assert.equal((await request(endpoint, token, { ...body, role_code: 'content_manager', action: 'revoke', request_id: randomUUID() })).status, 200);
  assert.equal((await request(courseEndpoint, target.token, managerBody)).status, 403);
  stage = 'concurrent admin revocation preserves authority';
  assert.equal((await request(endpoint, token, { ...body, student_id: nextAdmin.id, role_code: 'super_admin', request_id: randomUUID() })).status, 200);
  const secondToken = await mfa(nextAdmin);
  const results = await Promise.all([
    request(endpoint, token, { ...body, student_id: nextAdmin.id, role_code: 'super_admin', action: 'revoke', request_id: randomUUID() }),
    request(endpoint, secondToken, { ...body, student_id: admin.id, role_code: 'super_admin', action: 'revoke', request_id: randomUUID() }),
  ]);
  assert.deepEqual(results.map(result => result.status).sort(), [200,403]);
  assert.equal(sql("select count(*) from public.user_roles ur join public.roles r on r.id=ur.role_id where r.code='super_admin' and ur.revoked_at is null;"), '1');
  const revokedToken = results[0].status === 200 ? secondToken : token;
  assert.equal((await request(endpoint, revokedToken, { ...body, request_id: randomUUID() })).status, 403);
  stage = 'session downgrade waits for role transaction commit';
  const lockActor = results[0].status === 200 ? admin.id : nextAdmin.id;
  const lockToken = results[0].status === 200 ? token : secondToken;
  const lockSession = JSON.parse(Buffer.from(lockToken.split('.')[1], 'base64url')).session_id;
  assert.match(lockSession, /^[0-9a-f-]{36}$/i);
  const lockRequest = randomUUID();
  const holderName = `csa073-holder-${randomUUID()}`;
  const updaterName = `csa073-updater-${randomUUID()}`;
  function connection(statement) {
    const child = spawn('docker', ['exec', '-i', db.Id, 'psql', '-U', 'postgres', '-d', 'postgres',
      '-v', 'ON_ERROR_STOP=1', '-qAt', ...(statement ? ['-c', statement] : [])], {
      env: dockerEnv, stdio: ['pipe', 'ignore', 'ignore'], timeout: 20000,
    });
    // Teardown can close a failed subprocess pipe; completion still determines
    // transaction success and all actual DB assertions remain mandatory.
    child.stdin.on('error', () => {});
    const done = new Promise(resolve => {
      child.once('error', () => resolve(-1));
      child.once('close', code => resolve(code));
    });
    return { child, done };
  }
  async function observe(statement, description) {
    const deadline = Date.now() + 5000;
    while (Date.now() < deadline) {
      if (sql(statement) === 't') return;
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    assert.fail(description);
  }
  const holder = connection();
  let updater;
  try {
    holder.child.stdin.write(`set application_name='${holderName}'; begin; select public.csa073_change_role('${lockActor}','${lockSession}','aal2','${target.id}','content_manager','grant','Synthetic lock verification','${lockRequest}');\n`);
    await observe(`select exists(select 1 from pg_stat_activity where application_name='${holderName}' and state='idle in transaction');`, 'Role transaction retains session lock');
    updater = connection(`set application_name='${updaterName}'; update auth.sessions set aal='aal1' where id='${lockSession}' and user_id='${lockActor}';`);
    updater.child.stdin.end();
    await observe(`select exists(select 1 from pg_stat_activity waiting join pg_stat_activity holding on holding.pid=any(pg_blocking_pids(waiting.pid)) where waiting.application_name='${updaterName}' and holding.application_name='${holderName}' and waiting.wait_event_type='Lock');`, 'Non-key MFA downgrade waits behind role transaction');
    holder.child.stdin.end('commit;\n');
    assert.equal(await holder.done, 0, 'Role mutation commits');
    assert.equal(await updater.done, 0, 'Session downgrade completes after commit');
    assert.equal(sql(`select count(*) from public.csa061_role_audit where request_id='${lockRequest}';`), '1');
    assert.equal(sql(`select aal from auth.sessions where id='${lockSession}';`), 'aal1');
    sql(`update auth.sessions set aal='aal2' where id='${lockSession}' and user_id='${lockActor}';`);
  } finally {
    // Only uniquely labelled connections in the task-owned disposable fixture.
    sql(`select pg_terminate_backend(pid) from pg_stat_activity where application_name in ('${holderName}','${updaterName}');`);
    if (!holder.child.stdin.writableEnded) holder.child.stdin.end();
    if (updater && !updater.child.stdin.writableEnded) updater.child.stdin.end();
    await holder.done;
    if (updater) await updater.done;
  }
  stage = 'current MFA downgrade, expiry and logout denial';
  const currentToken = results[0].status === 200 ? token : secondToken;
  const currentId = results[0].status === 200 ? admin.id : nextAdmin.id;
  const currentClaims = JSON.parse(Buffer.from(currentToken.split('.')[1], 'base64url'));
  assert.match(currentClaims.session_id, /^[0-9a-f-]{36}$/i);
  const sessionId = currentClaims.session_id;
  const denyBody = { ...body, request_id: randomUUID() };
  const auditBefore = sql(`select count(*) from public.csa061_role_audit where actor_id='${currentId}';`);
  sql(`update auth.sessions set aal='aal1' where id='${sessionId}' and user_id='${currentId}';`);
  assert.equal((await request(endpoint, currentToken, denyBody)).status, 403);
  sql(`update auth.sessions set aal='aal2',not_after=now()-interval '1 second' where id='${sessionId}' and user_id='${currentId}';`);
  assert.equal((await request(endpoint, currentToken, denyBody)).status, 403);
  sql(`update auth.sessions set not_after=null where id='${sessionId}' and user_id='${currentId}';`);
  assert.equal((await request('/auth/v1/logout?scope=local', currentToken, {})).status, 204);
  assert.equal((await request(endpoint, currentToken, denyBody)).status, 401);
  assert.equal(sql(`select count(*) from public.csa061_role_audit where actor_id='${currentId}';`), auditBefore);
  assert.equal(sql(`select count(*) from auth.sessions where id='${sessionId}';`), '0');
  console.log('PASS: real Edge/Auth TOTP, forged/direct RPC denial, audited idempotency, role/session revocation, MFA downgrade, expiry, logout and concurrent admin handoff.');
}
main().catch(() => { console.error(`Role API smoke failed at ${stage}; private response data omitted.`); process.exitCode = 1; });
