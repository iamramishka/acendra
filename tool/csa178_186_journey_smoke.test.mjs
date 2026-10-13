import test from 'node:test';
import assert from 'node:assert/strict';
import { runJourneySmoke, fixtureInspector } from './csa178_186_journey_smoke.mjs';
test('journey refuses external and another local stack before fixture mutation', async () => {
  let mutations = 0;
  for (const base of ['https://example.invalid', 'http://127.0.0.1:58010']) {
    await assert.rejects(runJourneySmoke({ base, layout: { portBase: 58000 }, sql: () => mutations++ }),
      { message: 'Journey smoke failed at local target guard; private diagnostics suppressed.' });
  }
  assert.equal(mutations, 0);
});
test('synthetic inspector does not claim arbitrary bytes parseable', async () => {
  const result = await fixtureInspector.inspect({ bytes: Buffer.from('not a receipt'), mime: 'image/png', size: 13, sha256: 'fixture' });
  assert.equal(result.safe, false); assert.equal(result.parseable, false); assert.equal(result.withinResourceLimits, false);
});
