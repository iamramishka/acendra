import {spawnSync} from 'node:child_process';

// The tooling suite also runs in the Supabase job, which has no Flutter SDK.
export function pdfBrowserRuntimeStatus({platform = process.platform, env = process.env, probe = spawnSync} = {}) {
  if (platform !== 'linux' || env.CI !== 'true') {
    return {skip: true, reason: 'Hosted Linux browser verification only.'};
  }
  const result = probe('flutter', ['--version'], {
    encoding: 'utf8', timeout: 30000, maxBuffer: 100000, windowsHide: true,
  });
  if (result.error?.code === 'ENOENT') {
    return {skip: true, reason: 'Flutter SDK is not installed in this CI job.'};
  }
  if (result.error || result.status !== 0) {
    throw new Error('Installed Flutter runtime is unusable; browser verification cannot run.');
  }
  return {skip: false};
}
