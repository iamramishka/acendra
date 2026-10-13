import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {randomBytes} from 'node:crypto';

const scanner = process.env.CSA188_GITLEAKS;
function run(root, mode) {
 return spawnSync('powershell', ['-NoProfile', '-File', 'tool/csa188_scan.ps1', '-GitleaksPath', scanner, '-Mode', mode, '-RepositoryPath', root], {encoding:'utf8', windowsHide:true});
}
test('asset scan refuses absent build and detects synthetic credential without emitting it', {skip: !scanner}, () => {
 const root = fs.mkdtempSync(path.join(os.tmpdir(), 'csa188-test-'));
 try {
  fs.mkdirSync(path.join(root,'build','web'), {recursive:true});
  assert.notEqual(run(root,'assets').status,0);
  const credential = ['ghp', '_', randomBytes(27).toString('base64').replace(/[+/]/g, 'x')].join('');
  fs.writeFileSync(path.join(root,'build','web','main.dart.js'), `const token = "${credential}";`);
  const result = run(root,'assets');
  assert.notEqual(result.status,0);
  assert.match(result.stdout,/github-pat/);
  assert.ok(!(result.stdout + result.stderr).includes(credential));
  fs.writeFileSync(path.join(root,'build','web','main.dart.js'),'console.log("synthetic public bundle");');
  assert.equal(run(root,'assets').status,0);
 } finally { fs.rmSync(root, {recursive:true, force:true}); }
});
