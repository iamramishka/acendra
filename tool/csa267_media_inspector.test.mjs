import test from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
// Existing Linux CI discovers tool/*.test.mjs. Isolate pinned parser dependencies
// in a disposable venv instead of changing the runner's global Python packages.
test('media parser runs real Linux-limited children with pinned dependencies',
 {skip:process.platform!=='linux'||process.env.CI!=='true',timeout:240000},()=>{
 const directory=fs.mkdtempSync(path.join(os.tmpdir(),'acendra-media-inspector-'));
 const execute=(exe,args)=>{
  const result=spawnSync(exe,args,{cwd:root,encoding:'utf8',timeout:180000,maxBuffer:1024*1024});
  assert.equal(result.status,0,(result.stdout??'')+'\n'+(result.stderr??''));
 };
 try{
  execute('python3',['-m','venv',directory]);
  const python=path.join(directory,'bin','python');
  execute(python,['-m','pip','install','--disable-pip-version-check','--no-input','-r','tool/media_inspector/requirements.txt']);
  execute(python,['-m','unittest','discover','-s','tool/media_inspector','-p','test_*.py','-v']);
 }finally{
  const target=fs.realpathSync(directory),parent=fs.realpathSync(os.tmpdir());
  assert.equal(path.dirname(target),parent);assert.ok(path.basename(target).startsWith('acendra-media-inspector-'));
  fs.rmSync(target,{recursive:true,force:true});
 }
});
