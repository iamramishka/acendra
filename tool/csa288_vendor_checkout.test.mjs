import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = fileURLToPath(new URL('../', import.meta.url));
const vendor = 'web/vendor/mux-player';

test('Git checkout preserves pinned Mux distribution and license bytes with any autocrlf mode', () => {
  const fixture = mkdtempSync(path.join(tmpdir(), 'acendra-csa288-checkout-'));
  const git = (cwd, args, options = {}) => execFileSync('git', ['-C', cwd, ...args], {
    maxBuffer: 16 * 1024 * 1024,
    stdio: ['ignore', 'pipe', 'pipe'],
    ...options,
  });
  try {
    // The immutable blobs are the reviewed inputs. Do not normalize the bundle
    // or weaken its integrity hash to accommodate the current host's checkout.
    const files = git(root, ['ls-tree', '-r', '--name-only', 'HEAD', '--', vendor], { encoding: 'utf8' })
      .trim().split('\n').filter(file => !file.endsWith('/.gitattributes'));
    const originals = new Map(files.map(file => [file, git(root, ['show', `HEAD:${file}`])]));
    for (const [file, bytes] of originals) {
      const target = path.join(fixture, file);
      mkdirSync(path.dirname(target), { recursive: true });
      writeFileSync(target, bytes);
    }
    const attributes = path.join(vendor, '.gitattributes');
    if (existsSync(path.join(root, attributes))) {
      writeFileSync(path.join(fixture, attributes), readFileSync(path.join(root, attributes)));
    }
    git(fixture, ['init', '--quiet']);
    git(fixture, ['-c', 'core.autocrlf=false', 'add', '--', vendor]);
    const manifest = JSON.parse(originals.get(`${vendor}/integrity.json`).toString('utf8'));
    for (const mode of ['true', 'input', 'false']) {
      const checkout = path.join(fixture, `checkout-${mode}`);
      git(fixture, ['-c', `core.autocrlf=${mode}`, 'checkout-index', '--all', `--prefix=${checkout.replaceAll('\\', '/')}/`]);
      const bundle = readFileSync(path.join(checkout, vendor, 'mux-player.js'));
      assert.equal(createHash('sha256').update(bundle).digest('hex'), manifest.sha256, `bundle integrity with core.autocrlf=${mode}`);
      for (const [file, bytes] of originals) {
        assert.deepEqual(readFileSync(path.join(checkout, file)), bytes, `${file} with core.autocrlf=${mode}`);
      }
    }
  } finally {
    rmSync(fixture, { recursive: true, force: true });
  }
});
