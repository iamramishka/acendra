import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';

const nginx = readFileSync(new URL('../server/nginx.conf', import.meta.url), 'utf8');
const policy = nginx.match(/add_header Content-Security-Policy "([^"]+)" always;/)?.[1];
assert.ok(policy, 'use the enforced production policy');
const directives = new Map(policy.split(';').map(value => value.trim().split(/\s+/))
  .filter(([name]) => name).map(([name, ...sources]) => [name, sources]));

test('protected playback permits only the Mux media boundary and blob media', () => {
  // Mux documents changing CDN subdomains, so allow its HTTPS host boundary
  // without permitting arbitrary media hosts or analytics/upload services.
  assert.deepEqual(directives.get('media-src'), ["'self'", 'blob:', 'https://*.mux.com']);
  assert.ok(directives.get('connect-src')?.includes('https://*.mux.com'), 'HLS fetches need Mux');
  assert.ok(directives.get('worker-src')?.includes('blob:'), 'retain playback blob workers');
  for (const name of ['media-src', 'connect-src']) {
    const sources = directives.get(name);
    for (const broad of ['*', 'https:', 'http:', 'https://*', 'https://*.litix.io', 'https://storage.googleapis.com']) {
      assert.ok(!sources.includes(broad), `${name} must not allow ${broad}`);
    }
  }
});

const chrome = [process.env.ACENDRA_CSP_CHROME,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser']
  .find(candidate => candidate && existsSync(candidate));

test('browser allows Mux and blob playback while blocking unrelated media and fetches', {
  skip: !chrome && 'Chrome/Chromium unavailable; set ACENDRA_CSP_CHROME to run browser verification',
  timeout: 100000,
}, async () => {
  const hosts = ['stream.mux.com', 'cdn.mux.com', 'unrelated.invalid',
    'stream.mux.com.evil.invalid', 'evilmux.com'];
  const html = `<!doctype html><html><body><pre id="result">pending</pre><script>
    fetch('/started', { method: 'POST' });
    const violations = [];
    document.addEventListener('securitypolicyviolation', event => {
      violations.push({ directive: event.effectiveDirective, url: event.blockedURI });
    });
    for (const host of ${JSON.stringify(hosts)}) {
      const url = 'https://' + host + '/synthetic.mp4';
      fetch(url).catch(() => {});
      const video = document.createElement('video');
      video.src = url; document.body.append(video); video.load();
    }
    const video = document.createElement('video');
    video.src = URL.createObjectURL(new Blob([], { type: 'video/mp4' }));
    document.body.append(video); video.load();
    setTimeout(() => fetch('/results', {
      method: 'POST', body: JSON.stringify(violations),
    }), 1000);
  </script></body></html>`;
  let completeResult;
  const received = new Promise(resolveResult => { completeResult = resolveResult; });
  let reportStarted;
  const started = new Promise(resolveStarted => { reportStarted = resolveStarted; });
  let phase = 'launch';
  const server = createServer((request, response) => {
    if (request.method === 'POST' && request.url === '/started') {
      phase = 'script-started';
      response.writeHead(204, { Connection: 'close' });
      response.end();
      reportStarted();
      return;
    }
    if (request.method === 'POST' && request.url === '/results') {
      let body = '';
      request.on('data', chunk => {
        body += chunk;
        if (body.length > 65536) request.destroy();
      });
      request.on('end', () => {
        phase = 'result-received';
        response.writeHead(204, { Connection: 'close' });
        response.end();
        completeResult(body);
      });
      return;
    }
    if (request.url !== '/') {
      response.writeHead(404); response.end(); return;
    }
    phase = 'page-served';
    response.writeHead(200, { 'Content-Type': 'text/html', 'Content-Security-Policy': policy });
    response.end(html);
  });
  await new Promise(resolveListen => server.listen(0, '127.0.0.1', resolveListen));
  const profile = mkdtempSync(join(tmpdir(), 'acendra-csp-test-'));
  let child;
  let timer;
  try {
    child = spawn(chrome, ['--headless=new', '--disable-gpu', '--no-sandbox',
      '--disable-dev-shm-usage',
      '--disable-background-timer-throttling', '--disable-renderer-backgrounding',
      '--disable-backgrounding-occluded-windows',
      '--no-first-run', '--disable-background-networking', '--disable-extensions',
      '--no-proxy-server', `--user-data-dir=${profile}`,
      // All synthetic external destinations resolve locally, even if allowed
      // by CSP. No Mux media, credentials or external network is involved.
      '--host-resolver-rules=MAP * 127.0.0.1',
      `http://127.0.0.1:${server.address().port}`], { windowsHide: true });
    let stderr = '';
    child.stdout.resume();
    child.stderr.on('data', data => { stderr += data; });
    const earlyExit = new Promise((_, reject) => {
      child.once('error', reject);
      child.once('close', code => {
        reject(new Error(`Chrome exited before reporting CSP results (${code}): ${stderr}`));
      });
    });
    // Wait for an actual browser result rather than Chrome's best-effort DOM
    // dump, which may be empty when virtual time advances during startup.
    const deadline = (milliseconds, label) => new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error(`CSP browser ${label} timed out at phase ${phase}`)), milliseconds);
    });
    // Give process startup its own bounded budget under aggregate CI load;
    // the script must then produce its result within a separate 20 seconds.
    await Promise.race([started, earlyExit, deadline(60000, 'startup')]);
    clearTimeout(timer);
    const result = await Promise.race([received, earlyExit, deadline(20000, 'execution')]);
    const violations = JSON.parse(result);
    for (const host of hosts.slice(0, 2)) {
      assert.ok(!violations.some(item => item.url === `https://${host}/synthetic.mp4`),
        `${host} unexpectedly blocked: ${result}`);
    }
    assert.ok(!violations.some(item => item.url === 'blob' || item.url.startsWith('blob:')),
      `blob blocked: ${result}`);
    for (const host of hosts.slice(2)) {
      for (const directive of ['media-src', 'connect-src']) {
        assert.ok(violations.some(item => item.directive === directive &&
          item.url === `https://${host}/synthetic.mp4`), `${directive} must block ${host}: ${result}`);
      }
    }
  } finally {
    clearTimeout(timer);
    if (child && child.exitCode === null) {
      const stopped = new Promise(resolveExit => child.once('close', resolveExit));
      child.kill();
      await stopped;
    }
    server.closeAllConnections();
    await new Promise(resolveClose => server.close(resolveClose));
    // Only remove the unique profile created above, inside the OS temp folder.
    assert.equal(resolve(profile).startsWith(resolve(tmpdir()) + '\\') ||
      resolve(profile).startsWith(resolve(tmpdir()) + '/'), true);
    rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 });
  }
});
