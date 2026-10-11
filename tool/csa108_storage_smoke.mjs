// Real transport against the task-owned disposable CI stack. Synthetic inspection
// evidence tests transport only; no production scanner readiness is asserted.
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
export async function runReceiptStorageSmoke({ root, layout, env, sql, base, key, token, studentId }) {
  let stage = 'local credentials';
  try {
    assert.equal(base, `http://127.0.0.1:${layout.portBase}`);
    const result = spawnSync(process.execPath, [path.join(root,'node_modules/supabase/dist/supabase.js'),
      'status','--output','json','--workdir',layout.workdir], {env,encoding:'utf8'});
    assert.equal(result.status,0);
    const status = JSON.parse(result.stdout);
    assert.equal(status.API_URL,base);
    const service = status.SERVICE_ROLE_KEY;
    assert.ok(typeof service === 'string' && service.length > 20);
    const bytes = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfWQAAAAASUVORK5CYII=','base64');
    const digest = createHash('sha256').update(bytes).digest('hex');
    const session = JSON.parse(Buffer.from(token.split('.')[1],'base64url')).session_id;
    assert.match(session,/^[0-9a-f-]{36}$/);
    const course=randomUUID(),bank=randomUUID(),version=randomUUID();
    sql(`insert into public.courses(id,slug,title,price_minor,status,published_at) values('${course}','receipt-${course}','Synthetic transport',10000,'published',now());
      insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name,currency_code)
      values('${version}','${bank}',1,'Synthetic bank','Synthetic owner','TEST-ONLY','Synthetic branch','LKR');`);
    const order=JSON.parse(sql(`select public.csa098_create_checkout_order('${studentId}','${session}','aal1','${randomUUID()}','${course}','bank_transfer','${version}')`)).data.order_id;
    const upload=JSON.parse(sql(`select public.csa108_prepare_receipt('${studentId}','${session}','aal1','${randomUUID()}','${order}','${digest}',${bytes.length},'image/png','png')`));
    assert.match(upload.object_path,/^[0-9a-f/.-]+$/);
    const route='/storage/v1/object/bank-receipts/'+upload.object_path;
    const call=(route,method,bearer,body,extra={})=>fetch(base+route,{method,headers:{apikey:key,...(bearer?{Authorization:'Bearer '+bearer}:{}),...extra},body,redirect:'error',signal:AbortSignal.timeout(30000)});
    stage='first upload and metadata lifecycle';
    const first=await call(route,'POST',service,bytes,{'Content-Type':'image/png','x-upsert':'false'});
    assert.ok(first.ok);
    stage='private readback';
    const read=await call(route,'GET',service);
    assert.equal(read.status,200); assert.equal(read.headers.get('Content-Type'),'image/png');
    assert.deepEqual(Buffer.from(await read.arrayBuffer()),bytes);
    stage='duplicate and unreserved path denial';
    const duplicate=await call(route,'POST',service,bytes,{'Content-Type':'image/png','x-upsert':'false'});
    assert.ok([400,409].includes(duplicate.status));
    const error=await duplicate.json();
    assert.ok(error.error==='Duplicate'||error.code==='ResourceAlreadyExists'||String(error.statusCode)==='409');
    assert.equal((await call('/storage/v1/object/bank-receipts/'+randomUUID()+'.png','POST',service,bytes,{'Content-Type':'image/png'})).ok,false);
    stage='student and anonymous denial';
    for(const bearer of [undefined,token]) {
      assert.equal((await call(route,'GET',bearer)).ok,false);
      assert.equal((await call('/storage/v1/object/public/bank-receipts/'+upload.object_path,'GET',bearer)).ok,false);
      assert.equal((await call(route,'POST',bearer,bytes,{'Content-Type':'image/png'})).ok,false);
      const list=await call('/storage/v1/object/list/bank-receipts','POST',bearer,JSON.stringify({prefix:studentId}),{'Content-Type':'application/json'});
      if(list.ok) assert.deepEqual(await list.json(),[]);
    }
    stage='finalized immutability';
    sql(`select public.csa109_finalize_receipt('${studentId}','${session}','aal1','${upload.upload_id}','${digest}',${bytes.length},'image/png','synthetic-transport-only')`);
    assert.equal((await call(route,'POST',service,bytes,{'Content-Type':'image/png','x-upsert':'true'})).ok,false);
    assert.equal((await call('/storage/v1/object/bank-receipts','DELETE',service,JSON.stringify({prefixes:[upload.object_path]}),{'Content-Type':'application/json'})).ok,false);
    const preserved=await call(route,'GET',service);
    assert.equal(preserved.status,200); assert.deepEqual(Buffer.from(await preserved.arrayBuffer()),bytes);
    assert.equal(sql(`select status from public.orders where id='${order}'`),'pending_verification');
    console.log('PASS: real private receipt upload/readback, duplicate handling, direct-access denial and finalized evidence preservation.');
  } catch { throw new Error('Receipt Storage smoke failed at '+stage+'; private diagnostics suppressed.'); }
}
