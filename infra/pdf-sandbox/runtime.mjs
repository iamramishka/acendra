import { createSandboxGenerator } from './generator.mjs';
import { createWorkerHandler } from './handler.mjs';
import { createWorkerRuntime } from '../../tool/pdf_worker_runtime.mjs';
import { runPdfJob } from '../../tool/pdf_worker.mjs';
import { oneJobSdkFetch } from './transport.mjs';

// Lazy initialization: disabled operation needs no secrets and cannot claim work.
// No HTTP route or scheduler is installed by importing this module.
export function createSandboxWorker({ env = name => process.env[name] } = {}) {
  if (env('PDF_SANDBOX_WORKER_ENABLED') !== 'true') return createWorkerHandler();
  // A reviewed distributed admission adapter is required before live operation.
  // This local prototype intentionally provides no permissive deployment default.
  throw Error('PDF_SANDBOX_ADMISSION_REQUIRED');
}

export function createAdmittedSandboxWorker({ env, admit } = {}) {
  if (typeof env !== 'function' || env('PDF_SANDBOX_WORKER_ENABLED') !== 'true') return createWorkerHandler();
  if (typeof admit !== 'function') throw Error('PDF_SANDBOX_ADMISSION_REQUIRED');
  if (!env('PDF_SANDBOX_REGION')) throw Error('PDF_SANDBOX_REGION_REQUIRED');
  const generate = createSandboxGenerator({ image: env('PDF_SANDBOX_IMAGE'),
    region: env('PDF_SANDBOX_REGION'), create: async options => {
      const { Sandbox } = await import('@vercel/sandbox');
      return Sandbox.create({ ...options, fetch: oneJobSdkFetch() });
    } });
  const runtime = createWorkerRuntime({ env, generate });
  return createWorkerHandler({ enabled: true, secret: env('PDF_SANDBOX_CONTROL_SECRET'),
    run: () => admit(() => runPdfJob(runtime)) });
}
