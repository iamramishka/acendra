// Exercise the real non-root Linux supervisor in the existing tooling CI job.
// Windows unit checks remain separate; no production runtime is provisioned.
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

test('pinned watermark worker runs under the real non-root Linux supervisor', {
  skip: process.platform !== 'linux' || process.env.CI !== 'true',
  timeout: 240000,
}, () => {
  assert.notEqual(process.getuid(), 0, 'Worker verification must run unprivileged');
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const environment = { PATH: process.env.PATH, HOME: process.env.HOME,
    LANG: 'C.UTF-8', PYTHONNOUSERSITE: '1' };
  const directory = mkdtempSync(path.join(tmpdir(), 'acedra-pdf-verify-'));
  const run = (command, args, limit = 60000) => {
    const result = spawnSync(command, args, { cwd: root, env: environment,
      encoding: 'utf8', timeout: limit, maxBuffer: 4 * 1024 * 1024 });
    assert.equal(result.error, undefined, 'Isolated worker verification command failed');
    assert.equal(result.status, 0, 'Isolated worker verification command exited unsuccessfully');
    return result.stdout + result.stderr;
  };
  run('python3', ['-m', 'venv', directory]);
  const python = path.join(directory, 'bin', 'python');
  run(python, ['-m', 'pip', 'install', '--disable-pip-version-check',
    '-r', 'tool/pdf_watermark/requirements.txt'], 120000);
  // Expected rejected child processes can print diagnostics between the test
  // name and its 'ok'. Inspect unittest outcomes instead of parsing that layout.
  const verification = `
import unittest
class VerifiedResult(unittest.TextTestResult):
    succeeded = set()
    def addSuccess(self, case):
        self.succeeded.add(case.id())
        super().addSuccess(case)
suite = unittest.defaultTestLoader.discover('tool/pdf_watermark')
result = unittest.TextTestRunner(verbosity=2, resultclass=VerifiedResult).run(suite)
required = {
    'test_watermark.LinuxSupervisorTests.test_real_confined_generation_and_rejection',
    'test_watermark.LinuxSupervisorTests.test_wall_timeout_kills_child_and_cleans_up',
}
if not result.wasSuccessful() or not required.issubset(result.succeeded):
    raise SystemExit(1)
print('PDF_LINUX_CONFINEMENT_VERIFIED')
`;
  const report = run(python, ['-c', verification]);
  assert.match(report, /PDF_LINUX_CONFINEMENT_VERIFIED/,
    'The actual Linux confinement and timeout tests must execute, not skip');
});
