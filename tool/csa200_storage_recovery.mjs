import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const pdfPath = /^originals\/[0-9a-f-]{36}\/v[1-9][0-9]*\.pdf$/;

// Validate the entire archive before returning any restoration plan.
export function validateArchive(archive, expectedPaths, expectedTombstones) {
  assert.equal(archive?.version, 1);
  assert.equal(archive.bucket, 'course-pdfs');
  assert.ok(Array.isArray(archive.objects) && Array.isArray(archive.tombstones));
  assert.equal(archive.objects.length, expectedPaths.length);
  const seen = new Set();
  for (const item of archive.objects) {
    assert.ok(pdfPath.test(item.name) && expectedPaths.includes(item.name) && !seen.has(item.name));
    seen.add(item.name);
    assert.equal(item.mime, 'application/pdf');
    assert.ok(typeof item.data === 'string' && /^[A-Za-z0-9+/]*={0,2}$/.test(item.data));
    const bytes = Buffer.from(item.data, 'base64');
    assert.equal(bytes.toString('base64'), item.data);
    assert.ok(Number.isSafeInteger(item.size) && item.size > 0 && item.size <= 1024 * 1024);
    assert.equal(bytes.length, item.size);
    assert.equal(digest(bytes), item.sha256);
  }
  assert.equal(new Set(archive.tombstones).size, archive.tombstones.length);
  for (const name of archive.tombstones) assert.ok(seen.has(name));
  assert.deepEqual([...archive.tombstones].sort(), [...expectedTombstones].sort());
  return archive.objects.filter(item => !archive.tombstones.includes(item.name));
}

export async function runStorageRecoverySmoke({ root, layout, env, sql, base, key, token, containers }) {
  let stage = 'local target guard';
  let scratch;
  let call;
  let remove;
  const names = [0, 1, 2].map(() => `originals/${randomUUID()}/v1.pdf`);
  const started = performance.now();
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
    const service = status.SECRET_KEY || status.SERVICE_ROLE_KEY || field('SERVICE_KEY') || field('SUPABASE_SERVICE_ROLE_KEY') ||
      field('SUPABASE_SECRET_KEY') || (secrets ? Object.values(JSON.parse(secrets))[0] : undefined);
    assert.ok(typeof service === 'string' && service.length > 20);
    call = (route, method, bearer, body, extra = {}) => fetch(base + '/storage/v1/' + route, {
      method, headers: { apikey: bearer === service ? service : key,
        ...(bearer && !bearer.startsWith('sb_secret_') ? { Authorization: 'Bearer ' + bearer } : {}), ...extra },
      body, redirect: 'error', signal: AbortSignal.timeout(30000),
    });
    remove = prefixes => call('object/course-pdfs', 'DELETE', service, JSON.stringify({ prefixes }), { 'Content-Type': 'application/json' });
    const count = () => sql(`select count(*) from storage.objects where bucket_id='course-pdfs' and name in (${names.map(name => `'${name}'`).join(',')})`);
    assert.equal(sql("select public::text from storage.buckets where id='course-pdfs'"), 'false');
    const archive = { version: 1, bucket: 'course-pdfs', objects: [], tombstones: [names[2]] };
    stage = 'upload and capture actual private bytes';
    for (const [index, name] of names.entries()) {
      const source = Buffer.from(`%PDF-1.4\n% Synthetic recovery ${index}\n%%EOF\n`);
      assert.ok((await call('object/course-pdfs/' + name, 'POST', service, source, { 'Content-Type': 'application/pdf', 'x-upsert': 'false' })).ok);
      const read = await call('object/course-pdfs/' + name, 'GET', service);
      assert.equal(read.status, 200);
      const bytes = Buffer.from(await read.arrayBuffer());
      assert.deepEqual(bytes, source);
      archive.objects.push({ name, mime: 'application/pdf', size: bytes.length, sha256: digest(bytes), data: bytes.toString('base64') });
    }
    assert.equal(count(), '3');
    scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'acendra-csa200-api-'));
    const archivePath = path.join(scratch, 'private-backup.json');
    fs.writeFileSync(archivePath, JSON.stringify(archive), { mode: 0o600 });
    stage = 'archive verification before loss';
    validateArchive(JSON.parse(fs.readFileSync(archivePath, 'utf8')), names, [names[2]]);
    stage = 'exact object loss and metadata absence';
    assert.ok((await remove(names)).ok);
    assert.equal(count(), '0');
    for (const name of names) assert.equal((await call('object/course-pdfs/' + name, 'GET', service)).ok, false);
    stage = 'durable archive and tombstone restoration';
    const loaded = JSON.parse(fs.readFileSync(archivePath, 'utf8'));
    const restore = validateArchive(loaded, names, [names[2]]);
    assert.equal(restore.length, 2);
    for (const item of restore) {
      assert.ok((await call('object/course-pdfs/' + item.name, 'POST', service, Buffer.from(item.data, 'base64'),
        { 'Content-Type': item.mime, 'x-upsert': 'false' })).ok);
      const read = await call('object/course-pdfs/' + item.name, 'GET', service);
      assert.equal(read.status, 200);
      assert.equal(digest(Buffer.from(await read.arrayBuffer())), item.sha256);
      const metadata = JSON.parse(sql(`select metadata from storage.objects where bucket_id='course-pdfs' and name='${item.name}'`));
      assert.equal(Number(metadata.size), item.size);
      assert.equal(metadata.mimetype, item.mime);
    }
    assert.equal(count(), '2');
    assert.equal((await call('object/course-pdfs/' + names[2], 'GET', service)).ok, false);
    assert.equal(sql(`select count(*) from storage.objects where bucket_id='course-pdfs' and name='${names[2]}'`), '0');
    stage = 'restored authorization boundaries';
    for (const item of restore) for (const bearer of [undefined, token]) {
      assert.equal((await call('object/course-pdfs/' + item.name, 'GET', bearer)).ok, false);
      assert.equal((await call('object/public/course-pdfs/' + item.name, 'GET', bearer)).ok, false);
      assert.equal((await call('object/sign/course-pdfs/' + item.name, 'POST', bearer, JSON.stringify({ expiresIn: 60 }), { 'Content-Type': 'application/json' })).ok, false);
    }
    stage = 'exact fixture cleanup';
    assert.ok((await remove(names)).ok);
    assert.equal(count(), '0');
    console.log(`PASS: actual disposable Storage archive/loss/restore, 2 byte digests and metadata, 1 tombstone, restored access denial; elapsed_ms=${Math.round(performance.now() - started)}; cloud recovery unverified.`);
  } catch { throw new Error('Storage recovery smoke failed at ' + stage + '; private diagnostics suppressed.'); }
  finally {
    if (remove) {
      const cleanup = await remove(names);
      if (!cleanup.ok) throw new Error('Storage recovery exact fixture cleanup failed; private diagnostics suppressed.');
    }
    if (scratch) fs.rmSync(scratch, { recursive: true, force: true });
  }
}
