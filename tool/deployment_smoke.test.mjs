import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
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
