import test from 'node:test';
import assert from 'node:assert/strict';
import {assessHeaders} from './csa187_headers.mjs';
const secure = () => new Headers({
 'content-security-policy': "default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'",
 'x-content-type-options': 'nosniff',
 'referrer-policy': 'strict-origin-when-cross-origin',
 'permissions-policy': 'camera=(), microphone=()',
 'strict-transport-security': 'max-age=31536000',
});
test('accepts explicit restrictive response policy', () => assert.deepEqual(assessHeaders(secure(), 'https://example.test'), []));
test('report-only CSP does not satisfy enforcement', () => {
 const h = secure(); h.set('content-security-policy-report-only', h.get('content-security-policy')); h.delete('content-security-policy');
 assert.ok(assessHeaders(h, 'https://example.test').includes('missing enforced CSP'));
});
test('flags inline script and missing object denial', () => {
 const h = secure(); h.set('content-security-policy', "default-src *; script-src 'unsafe-inline'; base-uri 'self'; frame-ancestors 'self'");
 const result = assessHeaders(h, 'https://example.test');
 assert.ok(result.includes('broad script execution policy')); assert.ok(result.includes('object embedding not denied'));
});
test('loopback HTTP does not pretend to verify HSTS', () => {
 const h = secure(); h.delete('strict-transport-security');
 assert.deepEqual(assessHeaders(h, 'http://127.0.0.1'), []);
 assert.ok(assessHeaders(h, 'https://example.test').includes('missing HSTS'));
});
test('first duplicate CSP directive wins and mixed none does not restrict objects', () => {
 const h = secure(); h.set('content-security-policy', "default-src 'self'; script-src 'unsafe-inline'; script-src 'self'; object-src 'none' *; base-uri 'self'; frame-ancestors 'none' *");
 const result = assessHeaders(h, 'https://example.test');
 assert.ok(result.includes('broad script execution policy'));
 assert.ok(result.includes('object embedding not denied'));
 assert.ok(result.includes('frame embedding not restricted'));
});
test('scheme-wide script sources, wildcard hosts, base URL overrides and malformed permissions fail', () => {
 for (const scripts of ['https:', 'https://*', '*']) {
  const h = secure(); h.set('content-security-policy', `default-src 'self'; script-src ${scripts}; object-src 'none'; base-uri *; frame-ancestors 'none'`);
  h.set('permissions-policy','nonsense');
  const result = assessHeaders(h,'https://example.test');
  assert.ok(result.includes('broad script execution policy'));
  assert.ok(result.includes('base URL overrides not restricted'));
  assert.ok(result.includes('camera/microphone permissions not explicitly denied'));
 }
});
test('empty script directive blocks execution but compatibility remains separate', () => {
 const h=secure(); h.set('content-security-policy', "default-src 'self'; script-src; object-src 'none'; base-uri 'none'; frame-ancestors 'none'");
 assert.deepEqual(assessHeaders(h,'https://example.test'),[]);
});
test('remote HTTP and malformed HSTS never pass transport checks', () => {
 assert.ok(assessHeaders(secure(),'http://example.test').includes('remote target requires HTTPS'));
 for (const hsts of ['max-age=1.5','xmax-age=123','max-age=0','max-age=-1']) {
  const h=secure(); h.set('strict-transport-security',hsts);
  assert.ok(assessHeaders(h,'https://example.test').includes('missing HSTS'));
 }
});
