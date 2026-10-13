import test from 'node:test';
import assert from 'node:assert/strict';
import { samplesSummary,nativeTarget,benchmarkSQL,parseMeasurements } from './csa197_benchmark.mjs';
test('CSA197 reports nearest-rank P95 and even median',()=>{
  assert.deepEqual(samplesSummary([4,1,3,2]),{count:4,median_ms:2.5,p95_ms:4});
  assert.throws(()=>samplesSummary([])); assert.throws(()=>samplesSummary([NaN]));
});
test('CSA197 native mode refuses unacknowledged and non-disposable targets',()=>{
  assert.throws(()=>nativeTarget({CSA197_PORT:'5432'}));
  assert.throws(()=>nativeTarget({CSA197_DISPOSABLE:'csa197_benchmark',CSA197_DATABASE:'postgres',CSA197_PORT:'5432'}));
  for(const port of ['0','65536','5432;drop','remote']) assert.throws(()=>nativeTarget({CSA197_DISPOSABLE:'csa197_benchmark',CSA197_DATABASE:'csa197_benchmark',CSA197_PORT:port}));
  assert.equal(nativeTarget({CSA197_DISPOSABLE:'csa197_benchmark',CSA197_DATABASE:'csa197_benchmark',CSA197_PORT:'60011'})[1],'127.0.0.1');
});
test('CSA197 SQL rolls back synthetic fixtures and retains RLS checks',()=>{
  const sql=benchmarkSQL(); assert.ok(sql.startsWith('begin;')); assert.ok(sql.endsWith('rollback;\n'));
  assert.match(sql,/set local role authenticated/); assert.match(sql,/Cross-user order exposure/);
  assert.equal((sql.match(/EXPLAIN \(ANALYZE/g)||[]).length,63);
  assert.doesNotMatch(sql,/disable.*row level security|session_replication_role/i);
});
test('CSA197 incomplete measurement output fails closed',()=>assert.throws(()=>parseMeasurements('')));
test('CSA197 parses complete EXPLAIN reports and excludes warm-up',()=>{
  let output='';
  for(const name of ['catalog','orders','enrollments']) for(let i=0;i<21;i++) {
    output+=`CSA197:${name}:${i}\n${JSON.stringify([{'Execution Time':i===0?1000:2,'Planning Time':1,Plan:{'Node Type':'Limit'}}])}\n`;
  }
  const measured=parseMeasurements(output);
  assert.equal(measured.catalog.count,20); assert.equal(measured.catalog.p95_ms,2);
  assert.equal(measured.orders.plan['Node Type'],'Limit');
});
