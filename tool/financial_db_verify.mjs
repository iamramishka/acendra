import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
for (const [args, env] of [
  [['tool/local_supabase.mjs', 'test', 'test'], process.env],
  [['--test', 'tool/financial_concurrency.test.mjs', 'tool/csa101_105_concurrency.test.mjs'], {
    ...process.env, ACENDRA_FINANCIAL_CONCURRENCY: '1', ACENDRA_FINANCIAL_PROFILE: 'test',
    // The verification command always selects its task-owned Docker database.
    ACENDRA_FINANCIAL_PG_PORT: '',
  }],
]) {
  const result = spawnSync(process.execPath, args, { cwd: root, env, stdio: 'inherit' });
  if (result.error || result.status !== 0) {
    process.exitCode = result.status || 1;
    break;
  }
}
