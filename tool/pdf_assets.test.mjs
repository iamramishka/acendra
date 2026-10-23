import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

test('same-origin PDF renderer assets match the pinned distribution', () => {
  const root = new URL('../web/vendor/pdfjs/', import.meta.url);
  const manifest = JSON.parse(readFileSync(new URL('integrity.json', root), 'utf8'));
  assert.equal(manifest.version, '6.4.299');
  for (const required of ['pdf.min.js', 'pdf.worker.min.js', 'LICENSE']) {
    assert.ok(manifest.files[required]);
  }
  for (const [file, expected] of Object.entries(manifest.files)) {
    assert.ok(!file.includes('..') && !file.startsWith('/'));
    const actual = createHash('sha256').update(readFileSync(new URL(file, root))).digest('hex');
    assert.equal(actual, expected, file);
  }
});
