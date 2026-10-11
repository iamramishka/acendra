// Run only against the task-owned disposable development stack on hosted CI.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createHmac, randomBytes, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
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
    return { status: result.status, data: await result.json() };
  }
  async function signup() {
    const result = await request('/auth/v1/signup', undefined, {
      email: `role-${randomBytes(8).toString('hex')}@example.com`, password: randomBytes(24).toString('hex') + 'Aa!1' });
    assert.equal(result.status, 200);
    assert.ok(result.data.access_token && result.data.user?.id);
    return { id: result.data.user.id, token: result.data.access_token };
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
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get('Access-Control-Allow-Origin'), 'http://127.0.0.1:8080');
  const deniedOrigin = await fetch(base + endpoint, { method: 'OPTIONS', headers: {
    Origin: 'https://unapproved.example', 'Access-Control-Request-Method': 'POST',
  }, signal: AbortSignal.timeout(30000) });
  assert.equal(deniedOrigin.status, 403);
  assert.equal(deniedOrigin.headers.get('Access-Control-Allow-Origin'), null);
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
  console.log('PASS: real Edge/Auth TOTP, forged/direct RPC denial, audited idempotency, revocation and concurrent admin handoff.');
}
main().catch(() => { console.error(`Role API smoke failed at ${stage}; private response data omitted.`); process.exitCode = 1; });
