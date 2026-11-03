// The SDK normally retries POST creation on transient errors. A lost response
// must not create additional VMs behind a bounded single-job admission grant.
export function oneJobSdkFetch(fetchImpl = globalThis.fetch) {
  let attemptedCreate = false;
  return async (input, options = {}) => {
    const url = new URL(String(input));
    if (url.origin !== 'https://vercel.com' || !url.pathname.startsWith('/api/')) {
      const error = Error('PDF_SANDBOX_TRANSPORT_FAILED');
      error.name = 'AbortError';
      throw error;
    }
    if (options.method === 'POST' && /^\/api\/v[23]\/sandboxes$/.test(url.pathname)) {
      if (attemptedCreate) {
        const error = Error('PDF_SANDBOX_CREATE_NOT_RETRIED');
        error.name = 'AbortError';
        throw error;
      }
      attemptedCreate = true;
    }
    return fetchImpl(input, { ...options, redirect: 'error' });
  };
}
