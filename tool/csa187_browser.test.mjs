import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

// Existing Flutter CI runs tool/*.test.mjs after installing Flutter. Supabase CI
// has no Flutter runtime and explicitly skips this browser-only check.
const flutter = spawnSync('flutter', ['--version'], { encoding: 'utf8', windowsHide: true,
  timeout: 30000, shell: process.platform === 'win32' });
const hosted = process.env.CI === 'true' && process.platform === 'linux';
test('CSA187 hostile text stays literal in actual Chrome widgets and DOM', {
  skip: !hosted || flutter.error?.code === 'ENOENT', timeout: 180000,
}, () => {
  assert.equal(flutter.status, 0, 'Installed Flutter runtime must be usable');
  const result = spawnSync('flutter', ['test', '--no-pub', '--platform', 'chrome', '--reporter', 'json',
    'test/security/csa187_malicious_text_test.dart'], {
    encoding: 'utf8', timeout: 170000,
    env: { ...process.env, CHROME_EXECUTABLE: process.env.CHROME_EXECUTABLE || '/usr/bin/google-chrome' },
  });
  assert.equal(result.status, 0, `Browser security test failed: ${result.stdout?.slice(-6000)} ${result.stderr?.slice(-2000)}`);
  const events = result.stdout.split(/\r?\n/).filter(line => line.startsWith('{')).map(line => JSON.parse(line));
  assert.ok(events.some(event => event.type === 'done' && event.success === true), 'Browser reporter must confirm successful completion');
  const names = new Map(events.filter(event => event.type === 'testStart').map(event => [event.test.id, event.test.name]));
  const passed = events.filter(event => event.type === 'testDone' && event.result === 'success' && !event.skipped &&
    /^(course metadata and search|profile metadata) preserves? literal /.test(names.get(event.testID) ?? ''));
  assert.equal(passed.length, 6, 'All six malicious-text scenarios must execute in Chrome');
});
