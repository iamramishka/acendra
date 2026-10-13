import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { validateArchive, assertDeniedStatus } from './csa200_storage_recovery.mjs';

test('server errors, redirects and successful reads cannot count as denial', () => {
  for (const status of [400, 401, 403, 404]) assert.doesNotThrow(() => assertDeniedStatus(status));
  for (const status of [200, 206, 302, 429, 500, 503]) assert.throws(() => assertDeniedStatus(status));
});

function fixture() {
  const names = [0, 1].map(() => `originals/${randomUUID()}/v1.pdf`);
  const bytes = Buffer.from('%PDF synthetic recovery');
  return { names, archive: { version: 1, bucket: 'course-pdfs', tombstones: [names[1]],
    objects: names.map(name => ({ name, mime: 'application/pdf', size: bytes.length,
      sha256: createHash('sha256').update(bytes).digest('hex'), data: bytes.toString('base64') })) } };
}
test('valid archive restore plan excludes tombstoned bytes before upload', () => {
  const { names, archive } = fixture();
  assert.deepEqual(validateArchive(archive, names, [names[1]]).map(item => item.name), [names[0]]);
});
test('byte corruption anywhere in archive fails before a restoration plan exists', () => {
  const { names, archive } = fixture();
  archive.objects[1].data = Buffer.from('changed bytes').toString('base64');
  assert.throws(() => validateArchive(archive, names, [names[1]]));
});
test('unbound path, duplicate object, missing object and unknown tombstone rejected', () => {
  for (const mutate of [
    a => { a.objects[0].name = '../escape.pdf'; },
    a => { a.objects[1].name = a.objects[0].name; },
    a => { a.objects.pop(); },
    a => { a.tombstones.push('originals/' + randomUUID() + '/v1.pdf'); },
    a => { a.tombstones = []; },
  ]) {
    const { names, archive } = fixture(); mutate(archive);
    assert.throws(() => validateArchive(archive, names, [names[1]]));
  }
});
test('metadata corruption, wrong bucket and invalid archive format fail closed', () => {
  for (const mutate of [a => { a.objects[0].size++; }, a => { a.objects[0].mime = 'text/html'; },
    a => { a.bucket = 'public'; }, a => { a.version = 2; }, a => { a.objects[0].data += '!'; }]) {
    const { names, archive } = fixture(); mutate(archive);
    assert.throws(() => validateArchive(archive, names, [names[1]]));
  }
});
