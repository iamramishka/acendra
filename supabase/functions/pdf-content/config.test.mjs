import test from 'node:test';
import assert from 'node:assert/strict';
import { deliveryEnabled } from './config.mjs';
for (const value of [undefined, '', 'false', 'TRUE', '1', 'true']) {
  test(`delivery activation requires explicit exact opt-in: ${value}`, () => {
    assert.equal(deliveryEnabled(name => name === 'PDF_DELIVERY_ENABLED' ? value : undefined), value === 'true');
  });
}
