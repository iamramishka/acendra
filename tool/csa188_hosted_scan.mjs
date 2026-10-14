import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, realpathSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Invoke only with a checksum-verified Gitleaks executable supplied by CI.
// Scanner stdout/stderr can contain findings: never forward either stream.
const root = realpathSync(path.join(path.dirname(fileURLToPath(import.meta.url)), '..'));
const [mode, executable] = process.argv.slice(2);
if (!['history', 'assets'].includes(mode) || !executable) {
  throw new Error('Usage: node tool/csa188_hosted_scan.mjs <history|assets> <verified-gitleaks-path>');
}
const scanner = realpathSync(executable);
if (!statSync(scanner).isFile()) throw new Error('Scanner must be a verified executable file');
const target = mode === 'history' ? root : path.join(root, 'build', 'web');
const bundle = path.join(target, 'main.dart.js');
if (mode === 'assets' && (!existsSync(bundle) || !statSync(bundle).isFile())) {
  throw new Error('Release JavaScript bundle missing; asset acceptance not executed');
}
const args = [mode === 'history' ? 'git' : 'dir', target,
  '--redact=100', '--no-banner', '--exit-code', '1'];
if (mode === 'history') args.push('--log-opts=--all');
const result = spawnSync(scanner, args, {
  cwd: root, stdio: 'ignore', shell: false, windowsHide: true, timeout: 240000,
});
if (result.error || result.signal || result.status !== 0) {
  // Error objects can include executable arguments; report no raw diagnostics.
  console.error(JSON.stringify({ mode, passed: false,
    reason: result.error ? 'scanner execution failed' : result.signal ? 'scanner interrupted' : 'scanner rejected input',
    exitCode: result.status }));
  process.exitCode = 1;
} else {
  console.log(JSON.stringify({ mode, passed: true,
    ...(mode === 'assets' ? { mainDartJsSha256: createHash('sha256').update(readFileSync(bundle)).digest('hex') } : {}),
    coverage: mode === 'history' ? 'available checkout refs; shallow checkout may omit earlier history' : 'this build/web directory',
    limitation: 'Pattern scan only; does not verify managed logs or a differently configured release.' }));
}
