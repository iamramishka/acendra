import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

// Only the disposable task-owned local stack is allowed. Never log credentials.
export async function runPdfStorageSmoke({ root, layout, env, sql, base, key, token, containers }) {
  let stage = 'local credentials';
  try {
    assert.equal(base, `http://127.0.0.1:${layout.portBase}`);
    const result = spawnSync(process.execPath, [path.join(root, 'node_modules/supabase/dist/supabase.js'),
      'status', '--output', 'json', '--workdir', layout.workdir, '--network-id', `${layout.projectId}-loopback`], { env, encoding: 'utf8' });
    assert.equal(result.status, 0);
    const status = JSON.parse(result.stdout);
    assert.equal(status.API_URL, base);
    const values = containers.flatMap(item => item.Config?.Env ?? []);
    const field = name => values.find(value => value.startsWith(name + '='))?.slice(name.length + 1);
    const secrets = field('SUPABASE_SECRET_KEYS');
    const service = status.SECRET_KEY || status.SERVICE_ROLE_KEY || field('SERVICE_KEY') ||
      field('SUPABASE_SERVICE_ROLE_KEY') || field('SUPABASE_SECRET_KEY') ||
      (secrets ? Object.values(JSON.parse(secrets))[0] : undefined);
    assert.ok(typeof service === 'string' && service.length > 20);
    const asset = randomUUID();
    const names = [`originals/${asset}/v1.pdf`, `derivatives/${asset}/v1/${randomUUID()}/${randomUUID()}.pdf`];
    const bytes = Buffer.from('%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF\n');
    const call = (route, method, bearer, body, extra = {}) => fetch(base + '/storage/v1/' + route, {
      method, headers: { apikey: bearer === service ? service : key,
        ...(bearer && !bearer.startsWith('sb_secret_') ? { Authorization: 'Bearer ' + bearer } : {}), ...extra },
      body, redirect: 'error', signal: AbortSignal.timeout(30000),
    });
    stage = 'private configuration';
    assert.equal(sql("select public::text from storage.buckets where id='course-pdfs'"), 'false');
    try {
      for (const name of names) {
        const route = 'object/course-pdfs/' + name;
        stage = 'trusted upload and private readback';
        assert.ok((await call(route, 'POST', service, bytes, { 'Content-Type': 'application/pdf', 'x-upsert': 'false' })).ok);
        const read = await call(route, 'GET', service);
        assert.equal(read.status, 200);
        assert.equal(read.headers.get('content-type'), 'application/pdf');
        assert.deepEqual(Buffer.from(await read.arrayBuffer()), bytes);
        stage = 'client download upload list signed URL and public denial';
        for (const bearer of [undefined, token]) {
          assert.equal((await call(route, 'GET', bearer)).ok, false);
          assert.equal((await call('object/public/course-pdfs/' + name, 'GET', bearer)).ok, false);
          assert.equal((await call(route, 'POST', bearer, bytes, { 'Content-Type': 'application/pdf' })).ok, false);
          assert.equal((await call('object/sign/course-pdfs/' + name, 'POST', bearer, JSON.stringify({ expiresIn: 60 }), { 'Content-Type': 'application/json' })).ok, false);
          const list = await call('object/list/course-pdfs', 'POST', bearer, JSON.stringify({ prefix: '' }), { 'Content-Type': 'application/json' });
          if (list.ok) assert.deepEqual(await list.json(), []);
          const deletion = await call('object/course-pdfs', 'DELETE', bearer, JSON.stringify({ prefixes: [name] }), { 'Content-Type': 'application/json' });
          if (deletion.ok) assert.deepEqual(await deletion.json(), []);
          const stillPresent = await call(route, 'GET', service);
          assert.equal(stillPresent.status, 200);
          assert.deepEqual(Buffer.from(await stillPresent.arrayBuffer()), bytes);
        }
        stage = 'trusted replacement denial';
        assert.equal((await call(route, 'POST', service, bytes, { 'Content-Type': 'application/pdf', 'x-upsert': 'true' })).ok, false);
        const preserved = await call(route, 'GET', service);
        assert.equal(preserved.status, 200);
        assert.deepEqual(Buffer.from(await preserved.arrayBuffer()), bytes);
      }
      stage = 'invalid identity and MIME denial';
      assert.equal((await call('object/course-pdfs/private.pdf', 'POST', service, bytes, { 'Content-Type': 'application/pdf' })).ok, false);
      assert.equal((await call(`object/course-pdfs/originals/${asset}/v2.pdf`, 'POST', service, bytes, { 'Content-Type': 'image/png' })).ok, false);
    } finally {
      // Exact UUID paths created by this run; no bucket deletion or prefix sweep.
      const cleanup = await call('object/course-pdfs', 'DELETE', service, JSON.stringify({ prefixes: names }), { 'Content-Type': 'application/json' });
      assert.ok(cleanup.ok, 'Synthetic PDF cleanup failed');
    }
    console.log('PASS: private PDF lifecycle, byte readback, direct/signed/public denial, immutable versions and synthetic cleanup.');
  } catch { throw new Error('PDF Storage smoke failed at ' + stage + '; private diagnostics suppressed.'); }
}
