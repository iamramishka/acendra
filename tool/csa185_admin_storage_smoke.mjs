import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

export function assertStorageDenied(response) {
  assert.ok([400, 401, 403, 404].includes(response.status), 'Expected explicit Storage denial, not transport/server failure');
}

// Transport/policy acceptance only. No claim of approved image inspection.
export async function runAdminStorageSmoke({ root, layout, env, sql, base, key, token, containers }) {
  let stage = 'task-owned local credentials';
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
    const course = randomUUID(), lesson = randomUUID();
    const names = [`${course}/thumbnails/${randomUUID()}.png`, `${course}/${lesson}/${randomUUID()}.png`];
    const bytes = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfWQAAAAASUVORK5CYII=', 'base64');
    const call = (route, method, bearer, body, extra = {}) => fetch(base + '/storage/v1/' + route, {
      method, headers: { apikey: bearer === service ? service : key,
        ...(bearer && !bearer.startsWith('sb_secret_') ? { Authorization: 'Bearer ' + bearer } : {}), ...extra },
      body, redirect: 'error', signal: AbortSignal.timeout(30000),
    });
    stage = 'private bucket configuration';
    assert.equal(sql("select public::text from storage.buckets where id='course-media'"), 'false');
    let transportComplete = false;
    try {
      for (const name of names) {
        const route = 'object/course-media/' + name;
        stage = 'trusted synthetic image upload and byte readback';
        assert.ok((await call(route, 'POST', service, bytes, { 'Content-Type': 'image/png', 'x-upsert': 'false' })).ok);
        const read = await call(route, 'GET', service);
        assert.equal(read.status, 200);
        assert.equal(read.headers.get('content-type'), 'image/png');
        assert.deepEqual(Buffer.from(await read.arrayBuffer()), bytes);
        stage = 'anonymous/student read public signed list write and deletion denial';
        for (const bearer of [undefined, token]) {
          assertStorageDenied(await call(route, 'GET', bearer));
          assertStorageDenied(await call('object/public/course-media/' + name, 'GET', bearer));
          assertStorageDenied(await call('object/sign/course-media/' + name, 'POST', bearer, JSON.stringify({ expiresIn: 60 }), { 'Content-Type': 'application/json' }));
          assertStorageDenied(await call(route, 'POST', bearer, bytes, { 'Content-Type': 'image/png', 'x-upsert': 'true' }));
          assertStorageDenied(await call('object/course-media/' + `${course}/${randomUUID()}.png`, 'POST', bearer, bytes, { 'Content-Type': 'image/png' }));
          const list = await call('object/list/course-media', 'POST', bearer, JSON.stringify({ prefix: course }), { 'Content-Type': 'application/json' });
          if (list.ok) assert.deepEqual(await list.json(), []);
          else assertStorageDenied(list);
          const deletion = await call('object/course-media', 'DELETE', bearer, JSON.stringify({ prefixes: [name] }), { 'Content-Type': 'application/json' });
          if (deletion.ok) assert.deepEqual(await deletion.json(), []);
          else assertStorageDenied(deletion);
          const preserved = await call(route, 'GET', service);
          assert.equal(preserved.status, 200);
          assert.deepEqual(Buffer.from(await preserved.arrayBuffer()), bytes);
        }
      }
      transportComplete = true;
    } finally {
      if (transportComplete) stage = 'exact synthetic object cleanup';
      const cleanup = await call('object/course-media', 'DELETE', service, JSON.stringify({ prefixes: names }), { 'Content-Type': 'application/json' });
      assert.ok(cleanup.ok);
      for (const name of names) assertStorageDenied(await call('object/course-media/' + name, 'GET', service));
    }
    console.log('PASS: real private thumbnail/lesson-image readback, anonymous/student direct/public/signed/list/write/delete denial and exact synthetic cleanup.');
  } catch { throw new Error('Admin Storage smoke failed at ' + stage + '; private diagnostics suppressed.'); }
}
