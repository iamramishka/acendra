import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

// Regression guard for explicit controls. Real CLI/Auth behavior is exercised
// by auth_security_smoke.mjs; these checks do not substitute for provider tests.
const source = fs.readFileSync(new URL('../supabase/config.toml', import.meta.url), 'utf8');
function section(name) {
  const start = source.indexOf('[' + name + ']');
  assert.ok(start >= 0, 'Missing Auth security section: ' + name);
  return source.slice(start + name.length + 2).split(/\n\s*\[/, 1)[0];
}
function setting(name, key) {
  const value = section(name).match(new RegExp('^' + key + '\\s*=\\s*([^#\\r\\n]+)', 'm'))?.[1]?.trim();
  assert.ok(value !== undefined, 'Missing explicit security setting: ' + name + '.' + key);
  return value;
}
test('email ownership and password changes require provider verification', () => {
  for (const key of ['enable_confirmations', 'double_confirm_changes', 'secure_password_change']) {
    assert.equal(setting('auth.email', key), 'true', key);
  }
});
test('access tokens are short lived and refresh tokens rotate', () => {
  assert.ok(Number(setting('auth', 'jwt_expiry')) <= 900);
  assert.equal(setting('auth', 'enable_refresh_token_rotation'), 'true');
  assert.ok(Number(setting('auth', 'refresh_token_reuse_interval')) <= 10);
});
test('public signup cannot use anonymous or manually linked identities', () => {
  assert.equal(setting('auth', 'enable_signup'), 'true');
  assert.equal(setting('auth', 'enable_anonymous_sign_ins'), 'false');
  assert.equal(setting('auth', 'enable_manual_linking'), 'false');
});

test('password policy matches the owner-approved six-character rule without strength groups', () => {
  assert.equal(Number(setting('auth', 'minimum_password_length')), 6);
  assert.equal(setting('auth', 'password_requirements'), '""');
});
test('email tokens are bounded and repeated mail requests are throttled', () => {
  assert.equal(setting('auth.email', 'max_frequency'), '"1m"');
  assert.ok(Number(setting('auth.email', 'otp_expiry')) <= 600);
  for (const key of ['email_sent', 'sign_in_sign_ups', 'token_refresh', 'token_verifications']) {
    assert.ok(Number(setting('auth.rate_limit', key)) > 0);
  }
});
test('privileged TOTP is enabled and redirects have no wildcard', () => {
  assert.equal(setting('auth.mfa.totp', 'enroll_enabled'), 'true');
  assert.equal(setting('auth.mfa.totp', 'verify_enabled'), 'true');
  assert.equal(setting('functions.admin-assign-user-role', 'verify_jwt'), 'true');
  assert.ok(!setting('auth', 'additional_redirect_urls').includes('*'));
});
