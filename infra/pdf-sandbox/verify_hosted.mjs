// NOT a deployment command. Requires separate approval for exactly two synthetic
// jobs after a reviewed image exists. Never reads a real course or Supabase queue.
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { createSandboxGenerator } from './generator.mjs';
import { oneJobSdkFetch } from './transport.mjs';

const EXPECTED_SOURCE = 'bb92e30c9085af92ff3feecf07c71bfe7c756dba2dd27310e3b2f9018afb9411';
const target = new URL('../../build/com020-readiness/sandbox-trial/', import.meta.url);

export async function verifyHosted({ env = name => process.env[name], create } = {}) {
  if (env('PDF_SANDBOX_TRIAL_APPROVED') !== 'two-synthetic-jobs') throw Error('PDF_SANDBOX_TRIAL_APPROVAL_REQUIRED');
  if (!/^team_[A-Za-z0-9]+$/.test(env('VERCEL_TEAM_ID') ?? '') ||
      !/^prj_[A-Za-z0-9]+$/.test(env('VERCEL_PROJECT_ID') ?? '') ||
      !env('VERCEL_TOKEN') || !env('PDF_SANDBOX_REGION')) throw Error('PDF_SANDBOX_TRIAL_SCOPE_REQUIRED');
  // The fixture hash is compiled into the trial, so substituting a real student
  // document at this path cannot send it to Vercel.
  const source = await readFile(new URL('source.pdf', target));
  if (source.length > 16384 || createHash('sha256').update(source).digest('hex') !== EXPECTED_SOURCE) throw Error('PDF_SANDBOX_SYNTHETIC_FIXTURE_REQUIRED');
  const generate = createSandboxGenerator({ image: env('PDF_SANDBOX_IMAGE'),
    region: env('PDF_SANDBOX_REGION'), create: create ?? (async options => {
      const { Sandbox } = await import('@vercel/sandbox');
      return Sandbox.create({ ...options, fetch: oneJobSdkFetch(), token: env('VERCEL_TOKEN'),
        teamId: env('VERCEL_TEAM_ID'), projectId: env('VERCEL_PROJECT_ID') });
    }) });
  const report = [];
  for (const [index, name] of ['Synthetic Student A', 'අමල් தமிழ்'].entries()) {
    const bytes = await generate(source, { display_name: name,
      license_id: `27100000-0000-4000-8000-00000000000${index + 1}`,
      policy_id: '14000000-0000-4000-8000-000000000002', source_sha256: EXPECTED_SOURCE });
    await mkdir(target, { recursive: true });
    await writeFile(new URL(`student-${index + 1}.pdf`, target), bytes);
    report.push({ synthetic_student: index + 1, bytes: bytes.length,
      sha256: createHash('sha256').update(bytes).digest('hex') });
  }
  await writeFile(new URL('results.json', target), JSON.stringify(report, null, 2) + '\n');
  return report;
}

if (process.argv[1] && import.meta.url === (await import('node:url')).pathToFileURL(process.argv[1]).href) {
  try { await verifyHosted(); process.stdout.write('PDF_SYNTHETIC_TRIAL_COMPLETED\n'); }
  catch { process.stderr.write('PDF_SYNTHETIC_TRIAL_NOT_COMPLETED\n'); process.exitCode = 1; }
}
