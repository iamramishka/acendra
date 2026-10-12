import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const enabled = process.env.ACENDRA_CSA155_DB_TEST === '1';
test('CSA-155 dependency-pending: real PostgreSQL learning progress persistence', {
  skip: enabled ? false : 'Requires committed CSA-127/133 RPCs and opt-in disposable PostgreSQL; no mocked persistence',
  timeout: 30000,
}, t => {
  const port = process.env.ACENDRA_CSA155_PG_PORT ?? process.env.ACENDRA_FINANCIAL_PG_PORT;
  assert.match(port ?? '', /^\d{4,5}$/);
  assert.ok(Number(port) >= 1024 && Number(port) <= 65535);
  const command = process.env.ACENDRA_CSA155_PSQL ?? process.env.ACENDRA_FINANCIAL_PSQL ?? 'psql';
  const args = ['-X', '-h', '127.0.0.1', '-p', port, '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-qAt'];
  const run = input => spawnSync(command, args, { input, encoding: 'utf8', timeout: 20000, env: process.env });
  const prerequisite = run("select to_regprocedure('public.csa133_save_progress(uuid,boolean,integer,numeric,integer)') is not null and to_regprocedure('public.csa133_read_progress(uuid)') is not null;");
  assert.equal(prerequisite.status, 0, prerequisite.stderr);
  if (prerequisite.stdout.trim() !== 't') {
    t.skip('Committed CSA-133 save/read RPC dependency is absent in target database; persistence unverified');
    return;
  }
  const result = run(readFileSync(new URL('./csa155_progress.sql', import.meta.url), 'utf8'));
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(result.stdout, /^not ok/m);
  const checks = result.stdout.split(/\r?\n/).filter(line => /^ok \d+ - /.test(line));
  assert.equal(checks.length, 14, result.stdout);
  for (const check of checks) t.diagnostic(check);
});
