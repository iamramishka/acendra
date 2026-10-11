// Real Supabase integration checks on an ephemeral Linux runner. No hosted keys.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { randomBytes, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';
import { runAuthSecuritySmoke } from './auth_security_smoke.mjs';
import { runReceiptStorageSmoke } from './csa108_storage_smoke.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dev = createLayout(root, 'dev', process.env.ACENDRA_LOCAL_PORT_BASE);
const test = createLayout(root, 'test', process.env.ACENDRA_LOCAL_PORT_BASE);
const dockerEnv = { ...process.env };

function docker(args) {
  const result = spawnSync('docker', args, { env: dockerEnv, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  // Inspect/exec diagnostics can contain private local keys; never echo them.
  if (result.status !== 0) throw new Error('Task-owned Docker inspection failed.');
  return result.stdout.trim();
}

function containers(layout) {
  const ids = docker(['ps', '-q', '--filter', `network=${layout.projectId}-loopback`]).split(/\s+/).filter(Boolean);
  assert.ok(ids.length > 0, 'Expected task-owned running containers');
  return JSON.parse(docker(['inspect', ...ids]));
}

function dbContainer(items, layout) {
  const db = items.find(item => item.Name === `/supabase_db_${layout.projectId}`);
  assert.ok(db, 'Expected task-owned PostgreSQL container');
  return db.Id;
}

function sql(id, statement) {
  return docker(['exec', id, 'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-qAt', '-c', statement]);
}

async function request(base, key, route, { token, method = 'GET', body } = {}) {
  const response = await fetch(base + route, {
    method,
    headers: { apikey: key, ...(token ? { Authorization: `Bearer ${token}` } : {}), 'Content-Type': 'application/json', Prefer: 'return=representation' },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(30000),
  });
  return { status: response.status, body: await response.json() };
}

async function main() {
  pinLocalDockerEndpoint(dockerEnv, args => spawnSync('docker', args, { env: dockerEnv, encoding: 'utf8' }));
  const config = JSON.parse(fs.readFileSync(path.join(root, 'config/development.local.json'), 'utf8'));
  assert.deepEqual(Object.keys(config).sort(), ['APP_ENV', 'SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_URL']);
  assert.equal(config.SUPABASE_URL, `http://127.0.0.1:${dev.portBase}`);
  const devItems = containers(dev);
  const testItems = containers(test);
  for (const item of [...devItems, ...testItems]) {
    for (const bindings of Object.values(item.NetworkSettings.Ports || {})) {
      for (const binding of bindings || []) {
        assert.equal(binding.HostIp, '127.0.0.1', 'Published service ports must bind only loopback');
      }
    }
  }
  const devVolumes = new Set(devItems.flatMap(item => item.Mounts.filter(m => m.Type === 'volume').map(m => m.Name)));
  const testVolumes = new Set(testItems.flatMap(item => item.Mounts.filter(m => m.Type === 'volume').map(m => m.Name)));
  assert.ok(devVolumes.size > 0 && testVolumes.size > 0, 'Expected persistent local volumes');
  assert.ok([...devVolumes].every(name => !testVolumes.has(name)), 'Stacks must not share data volumes');
  const devDb = dbContainer(devItems, dev);
  const testDb = dbContainer(testItems, test);
  sql(devDb, 'create schema csa_foundation_probe; create table csa_foundation_probe.marker(id int); insert into csa_foundation_probe.marker values (1);');
  assert.equal(sql(testDb, "select count(*) from pg_namespace where nspname = 'csa_foundation_probe';"), '0');
  assert.equal(sql(testDb, 'select count(*) from public.roles;'), '4');

  const base = config.SUPABASE_URL;
  const key = config.SUPABASE_PUBLISHABLE_KEY;
  const health = await request(base, key, '/auth/v1/health');
  assert.equal(health.status, 200, 'Real Auth health endpoint');
  const anonymous = await request(base, key, '/rest/v1/profiles?select=id');
  assert.ok([401, 403].includes(anonymous.status), 'Anonymous profile access must be denied');
  assert.equal(anonymous.body.code, '42501');
  const email = `foundation-${randomBytes(6).toString('hex')}@example.com`;
  const password = randomBytes(24).toString('hex') + 'Aa!1';
  const signup = await request(base, key, '/auth/v1/signup', {
    method: 'POST', body: { email, password },
  });
  assert.equal(signup.status, 200, 'Real synthetic Auth signup');
  assert.ok(signup.body.id && !signup.body.access_token, 'Signup must wait for email confirmation');
  const studentId = signup.body.id;
  assert.match(studentId, /^[0-9a-f-]{36}$/);
  // This API/RLS fixture confirms only its own synthetic user via the operator.
  // The separate Auth security smoke exercises the actual verification token.
  sql(devDb, `update auth.users set email_confirmed_at=now() where id='${studentId}';`);
  const login = await request(base, key, '/auth/v1/token?grant_type=password', {
    method: 'POST', body: { email, password },
  });
  assert.equal(login.status, 200);
  assert.ok(login.body.access_token);
  const token = login.body.access_token;
  // Cross-user denial remains valid when CSA-060/061 later allow own-row reads.
  const foreignId = randomUUID();
  sql(devDb, `insert into auth.users(id) values ('${foreignId}'); insert into public.profiles(id,display_name) values ('${foreignId}','Synthetic foreign student') on conflict (id) do update set display_name=excluded.display_name; insert into public.user_roles(user_id,role_id) select '${foreignId}',id from public.roles where code='student';`);
  const ownProfile = await request(base, key, '/rest/v1/profiles?select=id,display_name,locale', { token });
  assert.equal(ownProfile.status, 200);
  assert.equal(ownProfile.body.length, 1, 'Student sees only their signup profile');
  assert.equal(ownProfile.body[0].id, studentId);
  const ownUpdate = await request(base, key, `/rest/v1/profiles?id=eq.${studentId}`, {
    token, method: 'PATCH', body: { display_name: 'Synthetic own student', locale: 'en' },
  });
  assert.equal(ownUpdate.status, 200);
  assert.equal(ownUpdate.body[0].display_name, 'Synthetic own student');
  const foreignUpdate = await request(base, key, `/rest/v1/profiles?id=eq.${foreignId}`, {
    token, method: 'PATCH', body: { display_name: 'Foreign intrusion' },
  });
  assert.equal(foreignUpdate.status, 200);
  assert.deepEqual(foreignUpdate.body, [], 'Cross-user update returns no foreign row');
  assert.equal(sql(devDb, `select display_name from public.profiles where id='${foreignId}';`), 'Synthetic foreign student');
  const protectedUpdate = await request(base, key, `/rest/v1/profiles?id=eq.${studentId}`, {
    token, method: 'PATCH', body: { avatar_path: 'forged/private/path' },
  });
  assert.equal(protectedUpdate.status, 403, 'Avatar storage references cannot be browser-controlled');
  assert.equal(protectedUpdate.body.code, '42501');
  const authenticated = await request(base, key, `/rest/v1/user_roles?select=id&user_id=eq.${foreignId}`, { token });
  if (authenticated.status === 403) assert.equal(authenticated.body.code, '42501');
  else {
    assert.equal(authenticated.status, 200, 'Expected RLS-filtered response or permission denial');
    assert.deepEqual(authenticated.body, [], 'Student cannot read foreign role history');
  }
  const elevatedRole = sql(devDb, "select id from public.roles where code='super_admin';");
  const assignment = await request(base, key, '/rest/v1/user_roles', {
    token, method: 'POST', body: { user_id: studentId, role_id: elevatedRole },
  });
  assert.equal(assignment.status, 403, 'Student cannot directly assign an elevated role');
  assert.equal(assignment.body.code, '42501');
  const storage = await request(base, key, '/storage/v1/bucket', { token });
  assert.equal(storage.status, 200, 'Real Storage API is reachable');
  assert.deepEqual(storage.body, [], 'Synthetic student has no visible buckets');
  await runReceiptStorageSmoke({ root, layout: dev, env: dockerEnv, sql: statement => sql(devDb,statement), base, key, token, studentId,
    storageContainer: devItems.find(item => item.Name === `/supabase_storage_${dev.projectId}`) });
  console.log('PASS: real Auth/Storage/API smoke checks, public export, loopback ports and independent volumes/databases.');
  await runAuthSecuritySmoke();
}

main().catch(error => {
  console.error(/^(Auth security|Receipt Storage) smoke failed at /.test(error.message) ? error.message : 'Supabase foundation smoke check failed; no private response data logged.');
  process.exitCode = 1;
});
