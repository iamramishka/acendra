import test from 'node:test';
import assert from 'node:assert/strict';
import { pdfxCompatibleTask } from '../web/pdfjs_compat.js';

test('pdfx document cleanup closes its PDF.js loading task exactly once', async () => {
  const document = { numPages: 4 };
  let calls = 0;
  const task = {
    promise: Promise.resolve(document),
    async destroy() { assert.equal(this, task); calls++; },
  };
  const adapted = pdfxCompatibleTask(task);
  assert.equal(await adapted.promise, document);
  await document.destroy();
  await document.destroy();
  await adapted.destroy();
  assert.equal(calls, 1);
});

test('cancelling before a late document resolves cannot close its worker twice', async () => {
  let resolve;
  let calls = 0;
  const task = {
    promise: new Promise(done => { resolve = done; }),
    async destroy() { calls++; },
  };
  const adapted = pdfxCompatibleTask(task);
  await adapted.destroy();
  resolve({ numPages: 1 });
  const document = await adapted.promise;
  await document.destroy();
  assert.equal(calls, 1);
});

test('opening and cleanup failures remain observable', async () => {
  const opening = pdfxCompatibleTask({
    promise: Promise.reject(new Error('opening failed')),
    destroy: async () => {},
  });
  await assert.rejects(opening.promise, /opening failed/);
  let calls = 0;
  const closing = pdfxCompatibleTask({
    promise: Promise.resolve({}),
    async destroy() { calls++; throw new Error('cleanup failed'); },
  });
  const document = await closing.promise;
  await assert.rejects(document.destroy(), /cleanup failed/);
  await assert.rejects(closing.destroy(), /cleanup failed/);
  assert.equal(calls, 1);
});
