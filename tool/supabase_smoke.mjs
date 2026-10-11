// Real Supabase integration checks on an ephemeral Linux runner. No hosted keys.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { randomBytes } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createLayout } from './local_supabase.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dev = createLayout(root, 'dev', process.env.ACENDRA_LOCAL_PORT_BASE);
const test = createLayout(root, 'test', process.env.ACENDRA_LOCAL_PORT_BASE);

function docker(args) {
  const result = spawnSync('docker', args, { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
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
    headers: { apikey: key, ...(token ? { Authorization: `Bearer ${token}` } : {}), 'Content-Type': 'application/json' },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(30000),
  });
  return { status: response.status, body: await response.json() };
}

async function main() {
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
  const signup = await request(base, key, '/auth/v1/signup', {
    method: 'POST', body: { email: `foundation-${randomBytes(6).toString('hex')}@example.com`, password: randomBytes(24).toString('hex') + 'Aa!1' },
  });
  assert.equal(signup.status, 200, 'Real synthetic Auth signup');
  assert.ok(signup.body.user?.id && signup.body.access_token, 'Expected local signup session');
  const token = signup.body.access_token;
  const authenticated = await request(base, key, '/rest/v1/user_roles?select=id', { token });
  assert.equal(authenticated.status, 403, 'Authenticated role history access must be denied');
  assert.equal(authenticated.body.code, '42501');
  const storage = await request(base, key, '/storage/v1/bucket', { token });
  assert.equal(storage.status, 200, 'Real Storage API is reachable');
  assert.deepEqual(storage.body, [], 'Synthetic student has no visible buckets');
  console.log('PASS: real Auth/Storage/API smoke checks, public export, loopback ports and independent volumes/databases.');
}

main().catch(() => { console.error('Supabase foundation smoke check failed; no private response data logged.'); process.exitCode = 1; });
