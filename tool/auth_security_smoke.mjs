// Real Auth integration in the task-owned disposable CI stack. Never hosted.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { randomBytes } from 'node:crypto';
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
export async function authSecuritySmoke() {
  pinLocalDockerEndpoint(dockerEnv, args => spawnSync('docker', args, { env: dockerEnv, encoding: 'utf8' }));
  const base = `http://127.0.0.1:${layout.portBase}`;
  const config = JSON.parse(fs.readFileSync(path.join(root, 'config/development.local.json'), 'utf8'));
  assert.equal(config.SUPABASE_URL, base);
  const key = config.SUPABASE_PUBLISHABLE_KEY;
  const items = JSON.parse(docker(['inspect', ...docker(['ps', '-q', '--filter', `network=${layout.projectId}-loopback`]).split(/\s+/).filter(Boolean)]));
  const db = items.find(item => item.Name === `/supabase_db_${layout.projectId}`);
  assert.ok(db, 'Expected task-owned database');
  const sql = statement => docker(['exec', db.Id, 'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-qAt', '-c', statement]);
  async function request(route, body, token, method = 'POST') {
    const response = await fetch(base + '/auth/v1' + route, {
      method, headers: { apikey: key, 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(30000),
    });
    return { status: response.status, data: response.status === 204 ? null : await response.json() };
  }
  stage = 'disabled anonymous and weak password signup';
  assert.ok((await request('/signup', {})).status >= 400);
  const email = `auth-security-${randomBytes(8).toString('hex')}@example.com`;
  assert.equal((await request('/signup', { email, password: 'short' })).status, 422);
  // Synthetic account in this disposable stack: prove the approved minimum
  // is accepted without digit/case/symbol requirements, after rejecting five.
  const password = 'aaaaaa';
  stage = 'signup cannot issue session before email confirmation';
  const signup = await request('/signup', { email, password });
  assert.equal(signup.status, 200);
  assert.match(signup.data.id, /^[0-9a-f-]{36}$/);
  assert.ok(!signup.data.access_token);
  const id = signup.data.id;
  const unconfirmed = await request('/token?grant_type=password', { email, password });
  assert.equal(unconfirmed.status, 400);
  assert.equal(unconfirmed.data.error_code, 'email_not_confirmed');

  stage = 'actual one-time email confirmation';
  // Read only this synthetic user's provider-generated hash inside the
  // disposable fixture. Exercises verify/consumption, not email deliverability.
  const confirmation = sql(`select confirmation_token from auth.users where id='${id}';`);
  assert.ok(confirmation.length > 0);
  const verified = await request('/verify', { type: 'signup', token_hash: confirmation });
  assert.equal(verified.status, 200);
  assert.ok(verified.data.access_token && verified.data.refresh_token);
  assert.ok((await request('/verify', { type: 'signup', token_hash: confirmation })).status >= 400);

  stage = 'generic invalid credentials and bounded token lifetime';
  const invalid = await request('/token?grant_type=password', { email, password: password + 'wrong' });
  const missing = await request('/token?grant_type=password', { email: `missing-${randomBytes(6).toString('hex')}@example.com`, password });
  assert.equal(invalid.status, 400);
  assert.equal(missing.status, invalid.status);
  assert.equal(invalid.data.error_code, 'invalid_credentials');
  assert.equal(missing.data.error_code, invalid.data.error_code);
  const login = await request('/token?grant_type=password', { email, password });
  assert.equal(login.status, 200);
  assert.ok(login.data.expires_in > 0 && login.data.expires_in <= 900);
  const claims = JSON.parse(Buffer.from(login.data.access_token.split('.')[1], 'base64url'));
  assert.ok(claims.exp - claims.iat <= 900);
  assert.match(claims.session_id, /^[0-9a-f-]{36}$/);
  stage = 'older session password change requires reauthentication';
  sql(`update auth.sessions set created_at=now()-interval '2 days' where id='${claims.session_id}';`);
  const passwordChange = await request('/user', { password: randomBytes(24).toString('hex') + 'Aa!1' }, login.data.access_token, 'PUT');
  assert.equal(passwordChange.status, 400);
  assert.equal(passwordChange.data.error_code, 'reauthentication_needed');
  sql(`update auth.sessions set created_at=now() where id='${claims.session_id}';`);

  stage = 'password recovery token and mail throttle';
  assert.equal((await request('/recover', { email })).status, 200);
  assert.equal((await request('/recover', { email })).status, 429);
  const expiredRecovery = sql(`select recovery_token from auth.users where id='${id}';`);
  sql(`update auth.users set recovery_sent_at=now()-interval '11 minutes' where id='${id}';`);
  assert.ok((await request('/verify', { type: 'recovery', token_hash: expiredRecovery })).status >= 400);
  assert.equal((await request('/recover', { email })).status, 200);
  const recovery = sql(`select recovery_token from auth.users where id='${id}';`);
  assert.ok(recovery.length > 0);
  const recovered = await request('/verify', { type: 'recovery', token_hash: recovery });
  assert.equal(recovered.status, 200);
  assert.ok(recovered.data.access_token);
  assert.ok((await request('/verify', { type: 'recovery', token_hash: recovery })).status >= 400);

  stage = 'rotation and logout revoke provider session';
  const rotated = await request('/token?grant_type=refresh_token', { refresh_token: login.data.refresh_token });
  assert.equal(rotated.status, 200);
  assert.ok(rotated.data.refresh_token !== login.data.refresh_token);
  assert.equal((await request('/logout?scope=local', undefined, rotated.data.access_token)).status, 204);
  assert.ok((await request('/token?grant_type=refresh_token', { refresh_token: rotated.data.refresh_token })).status >= 400);
  assert.ok([401,403].includes((await request('/user', undefined, rotated.data.access_token, 'GET')).status));
  console.log('PASS: real email-confirmation and recovery token consumption/expiry, weak/anonymous rejection, generic invalid credentials, password reauthentication, mail throttle, short JWT, refresh rotation and local logout.');
}
export async function runAuthSecuritySmoke() {
  try { await authSecuritySmoke(); }
  catch { throw new Error(`Auth security smoke failed at ${stage}; private request/response data omitted.`); }
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  runAuthSecuritySmoke().catch(error => { console.error(error.message); process.exitCode = 1; });
}
