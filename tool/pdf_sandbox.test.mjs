import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { Readable } from 'node:stream';
import { createSandboxGenerator } from '../infra/pdf-sandbox/generator.mjs';
import { createWorkerHandler } from '../infra/pdf-sandbox/handler.mjs';
import { createSandboxWorker, createAdmittedSandboxWorker } from '../infra/pdf-sandbox/runtime.mjs';
import { runPdfJob } from './pdf_worker.mjs';
import { oneJobSdkFetch } from '../infra/pdf-sandbox/transport.mjs';
import { verifyHosted } from '../infra/pdf-sandbox/verify_hosted.mjs';

const image = `acendra-pdf@sha256:${'a'.repeat(64)}`;
const source = Buffer.from('%PDF-1.7 synthetic source');
const output = Buffer.from('%PDF-1.7 synthetic marked derivative');
const identity = { display_name: 'Synthetic Student', license_id: '27100000-0000-4000-8000-000000000001',
  source_sha256: createHash('sha256').update(source).digest('hex'), policy_id: '14000000-0000-4000-8000-000000000002' };
const failed = promise => assert.rejects(promise, error => error.message === 'PDF_GENERATION_FAILED');
function fixture(options = {}) {
  const calls = [];
  const sandbox = {
    image: options.wrongImage ? 'default:latest' : image,
    persistent: options.persistent ?? false,
    currentSession: () => ({ networkPolicy: options.networkPolicy ?? 'deny-all' }),
    async mkDir(path, opts) { calls.push(['mkdir', path, opts]); },
    async writeFiles(files, opts) { calls.push(['write', files, opts]); if (options.writeError) throw Error('PRIVATE'); },
    async runCommand(args) { calls.push(['run', args]); return { exitCode: options.commandFailure || (options.generationFailure && args.args[0] === '--generate') ? 1 : 0 }; },
    async readFile(file, opts) { calls.push(['read', file, opts]); if (options.readError) throw Error('PRIVATE'); return options.missing ? null : Readable.from(options.chunks ?? [output]); },
    async stop(opts) { calls.push(['stop', opts]); if (options.stopError) throw Error('PRIVATE'); return { status: options.stillRunning ? 'running' : 'stopped', ...(options.snapshot ? { snapshot: {} } : {}) }; },
  };
  const create = async args => { calls.push(['create', args]); return sandbox; };
  return { calls, sandbox, generate: createSandboxGenerator({ image, create }) };
}

test('fresh sandbox denies networking and persistence before uploading private inputs', async () => {
  const { calls, generate } = fixture();
  assert.deepEqual(await generate(source, identity), output);
  const config = calls[0][1];
  assert.equal(config.image, image);
  assert.equal(config.persistent, false);
  assert.equal(config.networkPolicy, 'deny-all');
  assert.deepEqual(config.ports, []);
  assert.deepEqual(config.mounts, {});
  assert.deepEqual(config.env, {});
  assert.ok(config.signal instanceof AbortSignal);
  assert.ok(config.timeout <= 90000);
  const commands = calls.filter(c => c[0] === 'run').map(c => c[1]);
  assert.deepEqual(commands.map(c => c.args), [['--check'], ['--generate']]);
  for (const command of commands) {
    assert.equal(command.sudo, false);
    assert.deepEqual(command.env, {});
    assert.ok(command.timeoutMs <= 65000);
  }
  assert.ok(calls.findIndex(c => c[0] === 'run') < calls.findIndex(c => c[0] === 'write'));
  const files = calls.find(c => c[0] === 'write')[1];
  assert.deepEqual(JSON.parse(files[1].content.toString()), identity);
  assert.equal(files[0].mode, 0o600);
  assert.equal(calls.at(-1)[0], 'stop');
});

for (const config of [{ persistent: true }, { networkPolicy: 'allow-all' }, { wrongImage: true }]) {
  test(`unsafe sandbox metadata fails before document upload: ${JSON.stringify(config)}`, async () => {
    const { calls, generate } = fixture(config);
    await failed(generate(source, identity));
    assert.equal(calls.some(c => c[0] === 'write'), false);
    assert.equal(calls.at(-1)[0], 'stop');
  });
}

for (const options of [{ commandFailure: true }, { generationFailure: true }, { writeError: true }, { readError: true }, { missing: true },
  { chunks: [Buffer.alloc(0)] }, { chunks: [Buffer.from('not a PDF')] }, { stopError: true }, { snapshot: true }, { stillRunning: true }]) {
  test(`failed generation or cleanup never returns bytes: ${JSON.stringify(options)}`, async () => {
    const { calls, generate } = fixture(options);
    await failed(generate(source, identity));
    assert.equal(calls.at(-1)[0], 'stop');
  });
}

test('oversized output is cancelled and never returned', async () => {
  const { generate, sandbox } = fixture();
  let destroyed = false;
  sandbox.readFile = async () => new Readable({ read() { this.push(Buffer.alloc(50 * 1024 * 1024 + 1)); },
    destroy(error, cb) { destroyed = true; cb(error); } });
  await failed(generate(source, identity));
  assert.equal(destroyed, true);
});

test('a cancelled output read destroys the stream and still stops its sandbox', async () => {
  const { generate, sandbox, calls } = fixture();
  const cancellation = new AbortController();
  let destroyed = false;
  sandbox.readFile = async () => new Readable({ read() { cancellation.abort(); },
    destroy(error, callback) { destroyed = true; callback(error); } });
  await failed(generate(source, identity, { signal: cancellation.signal }));
  assert.equal(destroyed, true);
  assert.equal(calls.at(-1)[0], 'stop');
  assert.equal(calls.at(-1)[1].signal.aborted, false);
});

test('controller rejects a second simultaneous wakeup and recovers after completion', async () => {
  let complete;
  const handler = createWorkerHandler({ enabled: true, secret,
    run: () => new Promise(resolve => { complete = resolve; }) });
  const first = handler(request());
  assert.equal((await handler(request())).status, 409);
  complete({ state: 'idle' });
  assert.equal((await first).status, 200);
});

test('untrusted identity extras, bad digest and excessive input never create a sandbox', async () => {
  for (const [bytes, data] of [[source, { ...identity, trusted_font_path: '/evil' }],
    [source, { ...identity, source_sha256: '0'.repeat(64) }], [Buffer.alloc(0), identity],
    [source, { ...identity, display_name: 'student\nPRIVATE' }], [source, { ...identity, policy_id: 'unknown' }]]) {
    const { calls, generate } = fixture();
    await failed(generate(bytes, data));
    assert.equal(calls.length, 0);
  }
  for (const invalid of ['', 'latest', 'my-image:latest', 'https://unsafe/image', `${image}?secret=1`]) {
    assert.throws(() => createSandboxGenerator({ image: invalid, create: async () => {} }));
  }
});

const secret = 'synthetic-controller-secret-000000000000000000';
const request = (options = {}) => new Request('https://example.invalid/private/pdf-worker', {
  method: 'POST', headers: { authorization: `Bearer ${secret}` }, ...options,
});
test('controller is disabled by default, authenticated and body-free before queue access', async () => {
  let ran = 0;
  const run = async () => { ran++; return { state: 'idle' }; };
  assert.equal((await createWorkerHandler({ secret, run })(request())).status, 503);
  const handler = createWorkerHandler({ enabled: true, secret, run });
  assert.equal((await handler(request({ method: 'GET' }))).status, 405);
  assert.equal((await handler(request({ headers: {} }))).status, 401);
  assert.equal((await handler(request({ headers: { authorization: 'Bearer wrong' } }))).status, 401);
  assert.equal((await handler(request({ body: '{"display_name":"evil"}' }))).status, 400);
  assert.equal(ran, 0);
  const response = await handler(request());
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { state: 'idle' });
  assert.equal(response.headers.get('cache-control'), 'no-store');
});
test('controller hides resource IDs and all unexpected private errors', async () => {
  const done = createWorkerHandler({ enabled: true, secret, run: async () => ({ state: 'completed', resource_id: 'PRIVATE' }) });
  assert.deepEqual(await (await done(request())).json(), { state: 'completed' });
  const error = createWorkerHandler({ enabled: true, secret, run: async () => { throw Error('PRIVATE-token-path-name'); } });
  const response = await error(request());
  assert.equal(response.status, 503);
  assert.equal((await response.text()).includes('PRIVATE'), false);
  assert.throws(() => createWorkerHandler({ enabled: true, secret: 'weak', run: async () => {} }));
});

test('runtime imports without SDK credentials and refuses enabled operation without distributed admission', async () => {
  const disabled = createSandboxWorker({ env: () => undefined });
  assert.equal((await disabled(request())).status, 503);
  assert.throws(() => createSandboxWorker({ env: name => name === 'PDF_SANDBOX_WORKER_ENABLED' ? 'true' : undefined }), /ADMISSION_REQUIRED/);
  assert.throws(() => createAdmittedSandboxWorker({ env: () => 'true' }), /ADMISSION_REQUIRED/);
});

test('real queue seam completes immutable output only after sandbox cleanup', async () => {
  for (const stopError of [false, true]) {
    const { generate, calls } = fixture({ stopError });
    const resource = '27100000-0000-4000-8000-000000000002';
    const asset = '27100000-0000-4000-8000-000000000003';
    const job = { resource_id: resource, lease_token: '27100000-0000-4000-8000-000000000004',
      bucket: 'course-pdfs', source_path: `originals/${asset}/v1.pdf`, size_bytes: source.length,
      source_digest: identity.source_sha256, display_name: identity.display_name, license_id: identity.license_id,
      object_path: `derivatives/${asset}/v1/${identity.license_id}/${identity.policy_id}.pdf` };
    const runtime = { generate, rpc: async name => { calls.push([name]); return name === 'csa148_claim_pdf_job' ? job : true; },
      storage: { download: async () => source, exists: async () => false,
        upload: async ({ bytes, upsert }) => { assert.deepEqual(Buffer.from(bytes), output); assert.equal(upsert, false); calls.push(['upload']); return { created: true }; } } };
    if (stopError) {
      await assert.rejects(runPdfJob(runtime), error => error.message === 'PDF_JOB_FAILED');
      assert.equal(calls.some(c => c[0] === 'upload' || c[0] === 'csa148_complete_pdf_job'), false);
    } else {
      assert.equal((await runPdfJob(runtime)).state, 'completed');
      assert.ok(calls.findIndex(c => c[0] === 'stop') < calls.findIndex(c => c[0] === 'upload'));
      assert.equal(calls.at(-1)[0], 'csa148_complete_pdf_job');
    }
  }
});

test('SDK transport refuses redirects, alternate destinations and repeat creates', async () => {
  let requests = 0;
  const fetch = oneJobSdkFetch(async (_url, options) => {
    requests++;
    assert.equal(options.redirect, 'error');
    return Response.json({});
  });
  await assert.rejects(fetch('https://untrusted.invalid/api/v3/sandboxes', { method: 'POST' }));
  assert.equal(requests, 0);
  await fetch('https://vercel.com/api/v3/sandboxes', { method: 'POST' });
  await assert.rejects(fetch('https://vercel.com/api/v3/sandboxes', { method: 'POST' }));
  assert.equal(requests, 1);
  await fetch('https://vercel.com/api/v2/sandboxes/sessions/synthetic/stop', { method: 'POST' });
  assert.equal(requests, 2);
});

test('hosted verification is default-off before files, credentials or SDK access', async () => {
  let created = false;
  await assert.rejects(verifyHosted({ env: () => undefined, create: async () => { created = true; } }), /APPROVAL_REQUIRED/);
  assert.equal(created, false);
});
