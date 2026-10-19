// Server-side release switches, independent of client feature flags. Enabling
// requires an explicit origin allowlist; handlers still enforce auth/role/MFA.
export function reportingEnabled(env, flag) {
  if (env(flag) !== 'true') return false;
  const origins = env('ACENDRA_ADMIN_ALLOWED_ORIGINS');
  if (typeof origins !== 'string' || origins.trim() === '') return false;
  return origins.split(',').every(value => {
    const origin = value.trim();
    try {
      const url = new URL(origin);
      return url.origin === origin && !url.username && !url.password &&
        (url.protocol === 'https:' || (url.protocol === 'http:' &&
          ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)));
    } catch { return false; }
  });
}
