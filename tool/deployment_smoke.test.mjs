import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const workflow = readFileSync(new URL('../.github/workflows/deploy-production.yml', import.meta.url), 'utf8');
const smoke = workflow.split('      - name: Smoke test')[1]
  .split('      - name: Summary')[0].split('        run: |')[1]
  .replace(/^          /gm, '').replace(/\r/g, '');
const bash = process.platform === 'win32' && existsSync('C:/Program Files/Git/bin/bash.exe')
  ? 'C:/Program Files/Git/bin/bash.exe' : 'bash';
const headers = 'HTTP/2 200\nServer: nginx\nStrict-Transport-Security: max-age=63072000\nX-Content-Type-Options: nosniff\nX-Frame-Options: DENY\n';

function runSmoke(overrides = {}) {
  // Exercise the workflow's actual script under the runner's fail-fast options.
  // No network requests or production credentials are used.
  const mocks = `
sleep() { :; }
curl() {
  if [[ "$*" == *-sI* ]]; then printf '%s' "$TEST_HEADERS";
  elif [[ "$*" == *--no-location* ]]; then printf '%s' "$TEST_HTTP";
  else printf '%s' "$TEST_HTTPS"; return "$TEST_CURL_EXIT"; fi
}
`;
  return spawnSync(bash, ['-e', '-o', 'pipefail', '-c', mocks + smoke], {
    encoding: 'utf8',
    env: { ...process.env, TEST_HEADERS: headers, TEST_HTTP: '301',
      TEST_HTTPS: '200', TEST_CURL_EXIT: '0', ...overrides },
  });
}

test('healthy HTTPS response without a server version passes under pipefail', () => {
  const result = runSmoke();
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /Smoke test passed/);
});

for (const [name, overrides, message] of [
  ['missing HSTS', { TEST_HEADERS: headers.replace(/^Strict-Transport-Security:.*\n/m, '') }, /Missing Strict-Transport-Security/],
  ['missing nosniff', { TEST_HEADERS: headers.replace(/^X-Content-Type-Options:.*\n/m, '') }, /Missing X-Content-Type-Options/],
  ['missing frame protection', { TEST_HEADERS: headers.replace(/^X-Frame-Options:.*\n/m, '') }, /Missing X-Frame-Options/],
  ['server version exposed', { TEST_HEADERS: headers.replace('Server: nginx', 'Server: nginx/1.28.3') }, /discloses Nginx version/],
  ['HTTP does not redirect', { TEST_HTTP: '200' }, /does not redirect/],
  ['HTTPS unavailable', { TEST_HTTPS: '000', TEST_CURL_EXIT: '7' }, /HTTPS not live/],
]) {
  test(`smoke test rejects ${name} with its diagnostic`, () => {
    const result = runSmoke(overrides);
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stdout, message);
  });
}

// ---- Nginx config rollout (review findings on PR 177) ----------------------
const setupSsl = readFileSync(new URL('../server/setup-ssl.sh', import.meta.url), 'utf8').replace(/\r/g, '');
const deployStep = workflow.split('      - name: Upload release and Nginx config to server')[1]
  .split('      - name: Smoke test')[0].replace(/\r/g, '');
const remoteScript = deployStep.split('bash -s << EOF\n')[1].split('\n          EOF')[0]
  .replace(/^          /gm, '').replace(/\$\{RELEASE_DIR\}/g, 'REL');
const SITE = '/etc/nginx/sites-available/acendra';

function runRemote({ nginxTestExit = 0, siteExists = true } = {}) {
  const dir = mkdtempSync(join(tmpdir(), 'acendra-remote-'));
  const log = join(dir, 'calls.log');
  const site = join(dir, 'site');
  if (siteExists) writeFileSync(site, 'x');
  const script = remoteScript.replaceAll(`[ -f ${SITE} ]`, '[ -f "$SITE_FILE" ]');
  const mocks = `
sudo() { echo "sudo $*" >> "$LOG"; if [[ "$*" == *"nginx -t"* ]]; then return "$NGINX_RC"; fi; }
ln() { echo "ln $*" >> "$LOG"; }
mv() { echo "mv $*" >> "$LOG"; }
ls() { :; }
`;
  const result = spawnSync(bash, ['-e', '-o', 'pipefail', '-c', mocks + script], {
    encoding: 'utf8',
    env: { ...process.env, LOG: log, SITE_FILE: site, NGINX_RC: String(nginxTestExit) },
  });
  const calls = existsSync(log) ? readFileSync(log, 'utf8').trim().split('\n').filter(Boolean) : [];
  rmSync(dir, { recursive: true, force: true });
  return { ...result, calls };
}

test('no step stages the Nginx config in world-writable /tmp', () => {
  for (const [name, text] of [['workflow', workflow], ['setup-ssl.sh', setupSsl]]) {
    assert.doesNotMatch(text, /\/tmp\/acendra-nginx\.conf/, name);
  }
});

test('Nginx config is validated before the release symlink is switched', () => {
  const { status, calls } = runRemote();
  assert.equal(status, 0);
  const idx = (needle) => calls.findIndex((c) => c.includes(needle));
  assert.ok(idx('nginx -t') >= 0, 'nginx -t must run');
  assert.ok(idx('nginx -t') < idx('mv -T'), 'config test must precede the symlink switch');
  assert.ok(idx('mv -T') < idx('systemctl reload nginx'), 'reload follows the switch');
});

test('a rejected Nginx config is rolled back and the release is not switched', () => {
  const { status, calls, stderr } = runRemote({ nginxTestExit: 1 });
  assert.notEqual(status, 0);
  assert.ok(calls.some((c) => /install .*sites-available\/acendra\.bak .*sites-available\/acendra$/.test(c)),
    `previous config must be restored: ${calls.join(' | ')}`);
  assert.ok(!calls.some((c) => c.startsWith('ln ') || c.startsWith('mv ')), 'symlink must not switch');
  assert.ok(!calls.some((c) => c.includes('systemctl reload')), 'must not reload with a rejected config');
  assert.match(stderr, /restoring previous config/i);
});

test('without a provisioned site file the deploy only switches and reloads', () => {
  const { status, calls } = runRemote({ siteExists: false });
  assert.equal(status, 0);
  assert.ok(!calls.some((c) => c.includes('install') || c.includes('nginx -t')));
  assert.ok(calls.some((c) => c.includes('mv -T')));
});

test('every sudo command the deploy runs has an exact sudoers rule', () => {
  const rules = [...setupSsl.matchAll(/NOPASSWD: (.+)$/gm)]
    .map((m) => m[1].replaceAll('$NGINX_SITE', SITE).replace('/bin/systemctl', 'systemctl').replaceAll('$DEPLOY_DIR', '/var/www/acendra/.deploy').trim());
  const used = [...remoteScript.matchAll(/^\s*(?:if ! )?sudo (.+?)(?:; then)?$/gm)].map((m) => m[1].trim());
  assert.ok(used.length >= 4, `expected sudo calls, got ${used.join(' | ')}`);
  for (const cmd of used) assert.ok(rules.includes(cmd), `no sudoers rule for: ${cmd}\nrules: ${rules.join('\n')}`);
});
