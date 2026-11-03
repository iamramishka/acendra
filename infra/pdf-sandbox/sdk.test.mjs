import test from 'node:test';
import assert from 'node:assert/strict';
import { Sandbox } from '@vercel/sandbox';
import { oneJobSdkFetch } from './transport.mjs';

test('pinned SDK preserves isolated create options and decodes stopped metadata with patched Zod', async () => {
  const requests = [];
  const image = `acendra-pdf@sha256:${'a'.repeat(64)}`;
  const session = { id: 'ses_synthetic', memory: 2048, vcpus: 1, region: 'iad1',
    timeout: 90000, status: 'running', requestedAt: 1, createdAt: 1, updatedAt: 1,
    cwd: '/vercel/sandbox', networkPolicy: { mode: 'deny-all' } };
  const metadata = { name: 'pdf-synthetic', persistent: false, image,
    currentSessionId: session.id, createdAt: 1, updatedAt: 1, status: 'running' };
  // The actual SDK runs against an in-memory provider transport. No cloud VM,
  // real account credentials, OIDC refresh or production network is involved.
  const sandbox = await Sandbox.create({ token: 'synthetic-sdk-token',
    teamId: 'team_synthetic', projectId: 'prj_synthetic', image,
    persistent: false, networkPolicy: 'deny-all', ports: [], mounts: {}, env: {},
    resources: { vcpus: 1 }, timeout: 90000, signal: AbortSignal.timeout(5000),
    fetch: oneJobSdkFetch(async (url, options) => {
      requests.push({ url: String(url), options });
      assert.equal(options.redirect, 'error');
      if (String(url).includes('/ses_synthetic/stop')) {
        return Response.json({ session: { ...session, status: 'stopped' }, sandbox: { ...metadata, status: 'stopped' } });
      }
      assert.ok(String(url).includes('/v3/sandboxes'));
      return Response.json({ sandbox: metadata, session, routes: [] });
    }),
  });
  const sent = JSON.parse(requests[0].options.body);
  assert.equal(sent.persistent, false);
  assert.deepEqual(sent.networkPolicy, { mode: 'deny-all' });
  assert.deepEqual(sent.ports, []);
  assert.deepEqual(sent.env, {});
  assert.equal(sent.image, image);
  assert.equal(sandbox.persistent, false);
  assert.equal(sandbox.image, image);
  assert.equal(sandbox.currentSession().networkPolicy, 'deny-all');
  const stopped = await sandbox.stop({ signal: AbortSignal.timeout(5000) });
  assert.equal(stopped.status, 'stopped');
  assert.equal(stopped.snapshot, undefined);
  assert.equal(requests.length, 2);
});

test('an ambiguous create response cannot make SDK issue a second VM creation', async () => {
  let attempts = 0;
  await assert.rejects(Sandbox.create({ token: 'synthetic-sdk-token',
    teamId: 'team_synthetic', projectId: 'prj_synthetic', persistent: false,
    networkPolicy: 'deny-all', signal: AbortSignal.timeout(3000),
    fetch: oneJobSdkFetch(async () => { attempts++; return Response.json({}, { status: 503 }); }),
  }));
  assert.equal(attempts, 1);
});
