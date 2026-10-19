import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { reportingEnabled } from '../supabase/functions/_shared/reporting-activation.mjs';
import { createHandler } from '../supabase/functions/admin-payment-list/handler.mjs';

const flag = 'ACENDRA_ADMIN_PAYMENT_LIST_ENABLED';
const enabled = values => reportingEnabled(name => values[name], flag);
test('reporting requires explicit server opt-in and an exact allowed origin', () => {
  for (const value of [undefined, '', 'false', 'TRUE', '1']) {
    assert.equal(enabled({[flag]:value, ACENDRA_ADMIN_ALLOWED_ORIGINS:'https://acendra.example'}), false);
  }
  assert.equal(enabled({[flag]:'true'}), false);
  assert.equal(enabled({[flag]:'true', ACENDRA_ADMIN_ALLOWED_ORIGINS:'https://acendra.example'}), true);
});
test('malformed, wildcard and nonlocal cleartext origins cannot activate reporting', () => {
  for (const origin of ['*', 'null', 'https://example.com/path', 'https://example.com/', 'http://example.com', 'https://user:pass@example.com', 'https://example.com,', 'https://example.com, *']) {
    assert.equal(enabled({[flag]:'true', ACENDRA_ADMIN_ALLOWED_ORIGINS:origin}), false, origin);
  }
  assert.equal(enabled({[flag]:'true', ACENDRA_ADMIN_ALLOWED_ORIGINS:'http://127.0.0.1:8080'}), true);
});
test('payment list and settlement reporting can be released independently', () => {
  const env = name => ({[flag]:'true', ACENDRA_ADMIN_ALLOWED_ORIGINS:'https://acendra.example'})[name];
  assert.equal(reportingEnabled(env, 'ACENDRA_ADMIN_SETTLEMENT_REPORTING_ENABLED'), false);
});
test('enabled release path still requires authentication before any privileged fetch', async () => {
  const values = {[flag]:'true', ACENDRA_ADMIN_ALLOWED_ORIGINS:'https://acendra.example'};
  const env = name => values[name];
  const handler = createHandler({env, enabled:reportingEnabled(env, flag), fetch:() => { throw Error('unexpected fetch'); }});
  const result = await handler(new Request('https://function.invalid', {method:'POST', headers:{Origin:'https://acendra.example','Content-Type':'application/json'}, body:'{}'}));
  assert.equal(result.status, 401);
  assert.equal((await result.json()).error.code, 'AUTH_REQUIRED');
  assert.equal(result.headers.get('Cache-Control'), 'no-store');
});
test('all deployable reporting entrypoints use their server release switches', () => {
  for (const [name, flagName] of [['admin-payment-list',flag], ['admin-dashboard-stats','ACENDRA_ADMIN_SETTLEMENT_REPORTING_ENABLED'], ['admin-financial-report','ACENDRA_ADMIN_SETTLEMENT_REPORTING_ENABLED']]) {
    const source = readFileSync(new URL(`../supabase/functions/${name}/index.ts`,import.meta.url),'utf8');
    assert.ok(source.includes(`reportingEnabled(env, '${flagName}')`));
    assert.doesNotMatch(source, /enabled\s*:\s*true/);
  }
});
