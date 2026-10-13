import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function inventory(pub, pip, lock) {
  const queries = [];
  for (const match of pub.matchAll(/^  ([\w]+):\r?\n([\s\S]*?)(?=^  [\w]+:|^sdks:)/gm)) {
    const source = match[2].match(/^    source: (hosted|sdk|git|path)\s*$/m);
    if (!source) throw new Error('Invalid Pub package source');
    // Non-hosted entries remain outside the documented advisory coverage.
    if (source[1] !== 'hosted') continue;
    const version = match[2].match(/^    version: ["']([^"'\s]+)["']\s*$/m);
    if (!version) throw new Error('Missing or invalid hosted Pub version');
    queries.push({package:{ecosystem:'Pub',name:match[1]},version:version[1]});
  }
  for (const line of pip.split(/\r?\n/)) {
    const requirement = line.replace(/\s+#.*$/, '').trim();
    if (!requirement || requirement.startsWith('#')) continue;
    const match = requirement.match(/^([\w.-]+)==([A-Za-z0-9.+!_-]+)$/);
    if (!match) throw new Error('Unsupported Python requirement; exact unconditional pins required');
    queries.push({package:{ecosystem:'PyPI',name:match[1]},version:match[2]});
  }
  if (!lock?.packages || typeof lock.packages !== 'object' || Array.isArray(lock.packages)) throw new Error('Invalid npm lock inventory');
  for (const [path, value] of Object.entries(lock.packages)) {
    if (!path) continue;
    const name = path.split('node_modules/').at(-1);
    if (!path.includes('node_modules/') || !name || typeof value?.version !== 'string' || !value.version.trim() || value.link) {
      throw new Error('Missing or unsupported npm locked package version');
    }
    queries.push({package:{ecosystem:'npm',name},version:value.version});
  }
  if (!queries.some(q => q.package.ecosystem === 'Pub') || !queries.some(q => q.package.ecosystem === 'PyPI') || !queries.some(q => q.package.ecosystem === 'npm')) throw new Error('Incomplete package inventory');
  return queries;
}

export function findingsFrom(body, queries) {
  if (!Array.isArray(body?.results) || body.results.length !== queries.length) throw new Error('Incomplete OSV response');
  if (body.results.some(result => !result || typeof result !== 'object' || Array.isArray(result) || result.error ||
    (result.vulns !== undefined && (!Array.isArray(result.vulns) || result.vulns.some(v => typeof v?.id !== 'string' || !v.id.trim()))))) {
    throw new Error('Invalid OSV result');
  }
  return body.results.flatMap((result,index)=>(result.vulns ?? []).map(v=>({ ...queries[index],id:v.id,modified:v.modified })));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = new URL('../', import.meta.url);
  const queries = inventory(readFileSync(new URL('pubspec.lock', root), 'utf8'),
    readFileSync(new URL('tool/pdf_watermark/requirements.txt', root), 'utf8'),
    JSON.parse(readFileSync(new URL('package-lock.json', root), 'utf8')));
  const response = await fetch('https://api.osv.dev/v1/querybatch',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({queries}),signal:AbortSignal.timeout(60000)});
  if (!response.ok) throw new Error(`OSV HTTP ${response.status}`);
  const findings = findingsFrom(await response.json(), queries);
  console.log(JSON.stringify({date:new Date().toISOString(),counts:Object.fromEntries(['Pub','PyPI','npm'].map(e=>[e,queries.filter(q=>q.package.ecosystem===e).length])),findings},null,2));
  process.exitCode = findings.length ? 1 : 0;
}
