// Build a minimal, credential-free image context. Never send the repository root
// as Docker/VCR context: it can contain local .env and private verification files.
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../../', import.meta.url));
mkdirSync(path.join(root, 'build'), { recursive: true });
// A fresh directory cannot inherit a stale credential/document from a prior run.
const target = mkdtempSync(path.join(root, 'build/pdf-sandbox-context-'));
const files = new Map([
  ...['Dockerfile', 'launch', 'sandbox_job.py', 'install_font.py', 'requirements-linux.lock']
    .map(name => [name, `infra/pdf-sandbox/${name}`]),
  ['requirements.txt', 'tool/pdf_watermark/requirements.txt'],
  ...['watermark.py', 'supervisor.py'].map(name => [`pdf_watermark/${name}`, `tool/pdf_watermark/${name}`]),
]);
mkdirSync(target, { recursive: true });
const manifest = {};
for (const [name, source] of files) {
  const destination = path.join(target, name);
  mkdirSync(path.dirname(destination), { recursive: true });
  copyFileSync(path.join(root, source), destination);
  manifest[name] = createHash('sha256').update(readFileSync(destination)).digest('hex');
}
writeFileSync(path.join(target, 'CONTEXT-MANIFEST.json'), JSON.stringify(manifest, null, 2) + '\n');
writeFileSync(path.join(target, '.dockerignore'), ['**', ...[...files.keys()].map(name => `!${name}`),
  '!pdf_watermark/', '!CONTEXT-MANIFEST.json'].join('\n') + '\n');
console.log(`Prepared ${files.size} allowlisted source files; no credentials or documents copied.\n${target}`);
