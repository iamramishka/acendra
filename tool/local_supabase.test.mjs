import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createLayout, renderConfig, publicClientConfig, allowedCommand, isLocalDockerEndpoint, prepareSnapshot } from './local_supabase.mjs';

test('worktrees and dev/test have different IDs, volumes and ports', () => {
  const dev = createLayout('C:/worktrees/task-a', 'dev');
  const again = createLayout('C:/worktrees/task-a', 'dev');
  const other = createLayout('C:/worktrees/task-b', 'dev');
  const tests = createLayout('C:/worktrees/task-a', 'test');
  assert.deepEqual(dev, again);
  assert.notEqual(dev.projectId, other.projectId);
  assert.notEqual(dev.projectId, tests.projectId);
  assert.equal(tests.portBase, dev.portBase + 10);
  assert.notEqual(dev.workdir, tests.workdir);
});

test('invalid profiles and unsafe ports are rejected', () => {
  for (const profile of ['production', '../dev', '', 'staging']) {
    assert.throws(() => createLayout('/worktree', profile));
  }
  for (const port of ['0', '65530', '58000x', '1.5']) {
    assert.throws(() => createLayout('/worktree', 'dev', port));
  }
});

test('config rendering changes only explicit local project and service ports', () => {
  const source = 'project_id = "acendra-local"\nport = 54321\nport = 54322\nshadow_port = 54320\ninspector_port = 8083\nsite_url = "http://127.0.0.1:8080"\n';
  const layout = createLayout('/worktree', 'dev', '58000');
  const output = renderConfig(source, layout);
  assert.match(output, new RegExp(`project_id = "${layout.projectId}"`));
  assert.match(output, /port = 58000\nport = 58001\nshadow_port = 58002/);
  assert.match(output, /inspector_port = 58009/);
  assert.match(output, /site_url = "http:\/\/127.0.0.1:8080"/);
});

test('wrapper rejects hosted targets and arbitrary CLI commands', () => {
  for (const command of ['link', 'push', '--linked', 'db-url', 'deploy']) {
    assert.throws(() => allowedCommand(command));
  }
  assert.equal(allowedCommand('test'), 'test');
});

test('Docker must use a local socket, not a remote endpoint', () => {
  assert.ok(isLocalDockerEndpoint('npipe:////./pipe/docker_engine'));
  assert.ok(isLocalDockerEndpoint('unix:///var/run/docker.sock'));
  assert.ok(!isLocalDockerEndpoint('tcp://remote-server:2376'));
  assert.ok(!isLocalDockerEndpoint('ssh://remote-server'));
  assert.ok(!isLocalDockerEndpoint('npipe:////remote-server/pipe/docker_engine'));
});

test('generated Flutter config contains only local public values', () => {
  const localUrl = 'http://127.0.0.1:58000';
  const safe = publicClientConfig({ API_URL: localUrl, PUBLISHABLE_KEY: 'sb_publishable_fixture', SECRET_KEY: 'never-export', JWT_SECRET: 'never-export' }, localUrl);
  assert.deepEqual(safe, { APP_ENV: 'development', SUPABASE_URL: localUrl, SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_fixture' });
  assert.ok(!JSON.stringify(safe).includes('never-export'));
  assert.throws(() => publicClientConfig({ API_URL: 'https://example.supabase.co', PUBLISHABLE_KEY: 'sb_publishable_fixture' }, localUrl));
  assert.throws(() => publicClientConfig({ API_URL: localUrl, ANON_KEY: 'sb_secret_fixture' }, localUrl));
});

test('snapshot copies SQL inputs without hosted links, credentials or stage checks', t => {
  const worktree = fs.mkdtempSync(path.join(os.tmpdir(), 'acendra-tool-test-'));
  t.after(() => fs.rmSync(worktree, { recursive: true, force: true }));
  for (const dir of ['migrations', 'tests/database', '.temp', 'stage_checks']) {
    fs.mkdirSync(path.join(worktree, 'supabase', dir), { recursive: true });
  }
  const fixture = (name, value) => fs.writeFileSync(path.join(worktree, 'supabase', name), value);
  fixture('config.toml', 'project_id = "acendra-local"\nport = 54321\n');
  fixture('seed.sql', '-- synthetic only');
  fixture('migrations/001.sql', 'select 1;');
  fixture('tests/database/example.sql', 'select 1;');
  fixture('tests/database/private.env', 'SECRET=never-copy');
  fixture('.temp/project-ref', 'hosted-project');
  fixture('stage_checks/initial.sql', 'select 1;');
  const layout = createLayout(worktree, 'test');
  prepareSnapshot(worktree, layout);
  const snapshot = path.join(layout.workdir, 'supabase');
  assert.ok(fs.existsSync(path.join(snapshot, 'migrations/001.sql')));
  assert.ok(fs.existsSync(path.join(snapshot, 'tests/database/example.sql')));
  for (const excluded of ['.temp/project-ref', 'stage_checks/initial.sql', 'tests/database/private.env']) {
    assert.ok(!fs.existsSync(path.join(snapshot, excluded)));
  }
  fs.unlinkSync(path.join(worktree, 'supabase/migrations/001.sql'));
  fs.unlinkSync(path.join(worktree, 'supabase/tests/database/example.sql'));
  prepareSnapshot(worktree, layout);
  assert.ok(!fs.existsSync(path.join(snapshot, 'migrations/001.sql')));
  assert.ok(!fs.existsSync(path.join(snapshot, 'tests/database/example.sql')));
});
