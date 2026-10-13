import { pathToFileURL } from 'node:url';

// Observe the actual response. Never synthesize headers in a local test server.
export function assessHeaders(headers, url) {
  const failures = [];
  const csp = headers.get('content-security-policy') ?? '';
  const directives = new Map();
  for (const [key,...values] of csp.split(';').map(s => s.trim().split(/\s+/)).filter(a => a[0])) {
    if (!directives.has(key.toLowerCase())) directives.set(key.toLowerCase(), values);
  }
  if (!csp) failures.push('missing enforced CSP');
  for (const directive of ['default-src', 'script-src', 'object-src', 'base-uri', 'frame-ancestors']) {
    if (!directives.has(directive)) failures.push(`missing CSP ${directive}`);
  }
  const scripts = directives.get('script-src') ?? [];
  if (scripts.some(v => v.includes('*') || ["'unsafe-inline'", "'unsafe-eval'"].includes(v) || /^[a-z][a-z0-9+.-]*:$/i.test(v))) failures.push('broad script execution policy');
  if (!["'self'", "'none'"].includes(directives.get('base-uri')?.join(' '))) failures.push('base URL overrides not restricted');
  if (directives.get('object-src')?.join(' ') !== "'none'") failures.push('object embedding not denied');
  if (!["'none'", "'self'"].includes(directives.get('frame-ancestors')?.join(' '))) failures.push('frame embedding not restricted');
  if (headers.get('x-content-type-options')?.toLowerCase() !== 'nosniff') failures.push('missing nosniff');
  if (!['no-referrer', 'strict-origin', 'strict-origin-when-cross-origin', 'same-origin'].includes(headers.get('referrer-policy'))) failures.push('missing restrictive referrer policy');
  const permissions = headers.get('permissions-policy') ?? '';
  if (!permissions) failures.push('missing permissions policy');
  else if (!['camera', 'microphone'].every(feature => permissions.split(',').some(value => value.trim() === `${feature}=()`))) failures.push('camera/microphone permissions not explicitly denied');
  const target = new URL(url);
  const loopback = ['127.0.0.1','localhost','[::1]'].includes(target.hostname);
  if (target.protocol !== 'https:' && !loopback) failures.push('remote target requires HTTPS');
  if (target.protocol === 'https:' && !(headers.get('strict-transport-security') ?? '').split(';').some(value => /^max-age\s*=\s*[1-9]\d*$/i.test(value.trim()))) failures.push('missing HSTS');
  return failures;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const url = process.argv[2];
  if (!url) throw new Error('Usage: node tool/csa187_headers.mjs <authorized-target-url>');
  const response = await fetch(url, {redirect: 'error', signal: AbortSignal.timeout(15000)});
  const failures = assessHeaders(response.headers, url);
  // Output only status and policy findings, never cookies or header values.
  console.log(JSON.stringify({status: response.status, failures}));
  process.exitCode = response.ok && !failures.length ? 0 : 1;
}
