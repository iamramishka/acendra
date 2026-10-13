import { readFileSync } from 'node:fs';
const root = new URL('../', import.meta.url);
const queries = [];
const pub = readFileSync(new URL('pubspec.lock', root), 'utf8');
for (const match of pub.matchAll(/^  ([\w]+):\r?\n([\s\S]*?)(?=^  [\w]+:|^sdks:)/gm)) {
  const version = match[2].match(/version: "([^"]+)"/);
  if (version && /source: hosted/.test(match[2])) queries.push({package:{ecosystem:'Pub',name:match[1]},version:version[1]});
}
for (const line of readFileSync(new URL('tool/pdf_watermark/requirements.txt', root),'utf8').split(/\r?\n/)) {
  const match = line.match(/^([\w-]+)==([^\s#]+)$/);
  if(match) queries.push({package:{ecosystem:'PyPI',name:match[1]},version:match[2]});
}
const lock = JSON.parse(readFileSync(new URL('package-lock.json',root),'utf8'));
for(const [path, value] of Object.entries(lock.packages)) {
  if(path && value.version) queries.push({package:{ecosystem:'npm',name:path.split('node_modules/').at(-1)},version:value.version});
}
const response = await fetch('https://api.osv.dev/v1/querybatch',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({queries}),signal:AbortSignal.timeout(60000)});
if (!response.ok) throw new Error(`OSV HTTP ${response.status}`);
const body = await response.json();
if (!Array.isArray(body.results) || body.results.length !== queries.length) throw new Error('Incomplete OSV response');
const findings = body.results.flatMap((result,index)=>(result.vulns ?? []).map(v=>({ ...queries[index],id:v.id,modified:v.modified })));
console.log(JSON.stringify({date:new Date().toISOString(),counts:Object.fromEntries(['Pub','PyPI','npm'].map(e=>[e,queries.filter(q=>q.package.ecosystem===e).length])),findings},null,2));
process.exitCode = findings.length ? 1 : 0;
