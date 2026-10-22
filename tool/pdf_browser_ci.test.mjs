// Existing tool:test CI discovery runs this after the normal Flutter checks.
// No workflow/settings changes or hosted credentials are required.
import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { pdfBrowserRuntimeStatus } from './pdf_browser_runtime.mjs';

const runtime = pdfBrowserRuntimeStatus();

test('protected PDF reader uses the actual bundled renderer in Chrome', {
  skip: runtime.skip ? runtime.reason : false, timeout: 200000,
}, async () => {
  await import('./prepare_pdf_browser.mjs');
  const result = await new Promise(resolve => {
    const child = spawn('flutter', ['test', '--no-pub', '--platform', 'chrome', '--timeout', '60s', '--reporter', 'expanded',
      'test/browser/protected_pdf_reader.browser.dart'], {
      cwd: fileURLToPath(new URL('../', import.meta.url)), detached: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let output = '', timedOut = false;
    const capture = chunk => { output = (output + chunk).slice(-100000); };
    child.stdout.on('data', capture); child.stderr.on('data', capture);
    const deadline = setTimeout(() => {
      timedOut = true;
      try { process.kill(-child.pid, 'SIGKILL'); } catch { /* already exited */ }
    }, 190000);
    child.on('error', error => { clearTimeout(deadline); resolve({ code: -1, output: error.message }); });
    child.on('close', code => { clearTimeout(deadline); resolve({ code: timedOut ? -1 : code, output }); });
  });
  assert.equal(result.code, 0, result.output);
});
