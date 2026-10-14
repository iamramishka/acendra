import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const hosted = process.env.GITHUB_ACTIONS === 'true' && process.platform === 'linux';
test('CSA188 hosted history and release asset credential scan', { skip: !hosted, timeout: 600000 }, async () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'csa188-'));
  try {
    const url = 'https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz';
    const response = await fetch(url, { signal: AbortSignal.timeout(60000) });
    assert.equal(response.status, 200, 'Pinned scanner download failed');
    const bytes = Buffer.from(await response.arrayBuffer());
    assert.equal(createHash('sha256').update(bytes).digest('hex'),
      '551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb', 'Scanner checksum mismatch');
    const archive = path.join(dir, 'scanner.tar.gz');
    writeFileSync(archive, bytes);
    assert.equal(spawnSync('tar', ['-xzf', archive, '-C', dir, 'gitleaks'], { stdio: 'ignore' }).status, 0);
    const shallow = spawnSync('git', ['rev-parse', '--is-shallow-repository'], { encoding: 'utf8' });
    assert.equal(shallow.status, 0);
    if (shallow.stdout.trim() === 'true') {
      assert.equal(spawnSync('git', ['fetch', '--unshallow', 'origin'], { stdio: 'ignore', timeout: 120000 }).status, 0,
        'Full history unavailable; history scan not accepted');
    }
    for (const mode of ['history', 'assets']) {
      const result = spawnSync(process.execPath, ['tool/csa188_hosted_scan.mjs', mode, path.join(dir, 'gitleaks')],
        { encoding: 'utf8', timeout: 250000 });
      assert.equal(result.status, 0, `${mode} scan failed; findings withheld`);
      const metadata = JSON.parse(result.stdout.trim());
      assert.equal(metadata.passed, true);
      if (mode === 'assets') assert.match(metadata.mainDartJsSha256, /^[a-f0-9]{64}$/);
    }
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
