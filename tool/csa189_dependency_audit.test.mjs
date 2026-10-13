import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { inventory, findingsFrom } from './csa189_dependency_audit.mjs';

const pub = 'packages:\n  example:\n    source: hosted\n    version: "1.2.3"\nsdks:\n';
const pip = 'pypdf==6.10.0\n';
const npm = { packages: { '': {}, 'node_modules/example': { version: '1.2.3' } } };
test('locked inventory includes each ecosystem and current manifests', () => {
  assert.equal(inventory(pub, pip, npm).length, 3);
  const root = new URL('../', import.meta.url);
  const actual = inventory(readFileSync(new URL('pubspec.lock', root), 'utf8'),
    readFileSync(new URL('tool/pdf_watermark/requirements.txt', root), 'utf8'),
    JSON.parse(readFileSync(new URL('package-lock.json', root), 'utf8')));
  for (const ecosystem of ['Pub', 'PyPI', 'npm']) assert.ok(actual.some(q => q.package.ecosystem === ecosystem));
});
test('hosted Pub entry missing a version is rejected even alongside a valid entry', () => {
  assert.throws(() => inventory(pub.replace('sdks:', '  omitted:\n    source: hosted\nsdks:'), pip, npm), /Pub/);
});
test('Python requirements cannot silently omit unpinned, remote or conditional dependencies', () => {
  for (const extra of ['reportlab>=4', '-r other.txt', 'https://example.invalid/pkg.whl', 'uharfbuzz==0.53.3; sys_platform == "linux"']) {
    assert.throws(() => inventory(pub, pip + extra, npm), /Python/);
  }
  assert.equal(inventory(pub, '# comment\n\npypdf==6.10.0 # pinned\n', npm).length, 3);
});
test('npm lock entries with missing version and empty ecosystems fail explicitly', () => {
  assert.throws(() => inventory(pub, pip, { packages: { ...npm.packages, 'node_modules/omitted': {} } }), /npm/);
  assert.throws(() => inventory('packages:\nsdks:\n', pip, npm), /Incomplete/);
});
test('OSV results preserve known findings and reject incomplete or malformed responses', () => {
  const queries = inventory(pub, pip, npm);
  assert.deepEqual(findingsFrom({ results: [{}, { vulns: [{ id: 'GHSA-test', modified: 'date' }] }, {}] }, queries),
    [{ ...queries[1], id: 'GHSA-test', modified: 'date' }]);
  for (const results of [[], [{}, {}, { error: 'service failure' }], [{}, null, {}], [{}, { vulns: {} }, {}], [{}, { vulns: [{}] }, {}]]) {
    assert.throws(() => findingsFrom({ results }, queries), /OSV/);
  }
});
