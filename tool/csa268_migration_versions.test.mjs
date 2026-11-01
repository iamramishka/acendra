import test from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';

test('every migration has a unique Supabase ledger version', () => {
  const versions = new Map();
  for (const name of readdirSync(new URL('../supabase/migrations/', import.meta.url)).filter(name => name.endsWith('.sql'))) {
    const match = /^(\d{14})_.+\.sql$/.exec(name);
    assert.ok(match, `invalid migration filename: ${name}`);
    const version = match[1];
    assert.equal(versions.has(version), false, `duplicate Supabase migration version ${version}: ${versions.get(version)} and ${name}`);
    versions.set(version, name);
  }
});
