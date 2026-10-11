import test from 'node:test';
import assert from 'node:assert/strict';
import { createWorker } from './worker.mjs';
const notice = { id:'event-id',event_key:'bank_review:submission-id',recipient_user_id:'buyer-id',lease_token:'lease-id',notification_type:'bank_transfer_rejected',safe_payload:{order_id:'order-id',public_rejection_reason:'Please resubmit.',private_notes:'PRIVATE',storage_path:'PRIVATE'} };
function harness(options={}) {
 const calls=[]; const worker=createWorker({enabled:options.enabled??true,
 store:{claim:async()=>{calls.push(['claim']);return options.rows??[notice];},complete:async(...args)=>{calls.push(['complete',...args]);return options.ack??true;}},
 resolveRecipient:async user=>{calls.push(['recipient',user]);return options.recipient??'student@example.test';},
 deliver:async message=>{calls.push(['deliver',message]);if(options.failure) throw new Error('PRIVATE provider token');return {accepted:true};},
 }); return {worker,calls};
}
test('default release gate claims nothing',async()=>{let calls=0;const worker=createWorker({store:{claim:()=>calls++}});assert.deepEqual(await worker(),{disabled:true});assert.equal(calls,0);});
test('rejection email uses current trusted recipient and safe text only',async()=>{const {worker,calls}=harness();assert.deepEqual(await worker(),{sent:1,failed:0,stale:0});const mail=calls.find(c=>c[0]==='deliver')[1];assert.equal(mail.to,'student@example.test');assert.match(mail.text,/Please resubmit/);assert.equal(JSON.stringify(mail).includes('PRIVATE'),false);assert.match(mail.idempotencyKey,/^[a-f0-9]{64}$/);assert.deepEqual(calls.at(-1),['complete','event-id','lease-id',true]);});
test('retry uses stable provider idempotency across new leases',async()=>{const a=harness(),b=harness({rows:[{...notice,lease_token:'new-lease'}]});await a.worker();await b.worker();assert.equal(a.calls.find(c=>c[0]==='deliver')[1].idempotencyKey,b.calls.find(c=>c[0]==='deliver')[1].idempotencyKey);});
test('provider error marks only outbox failure and never logs secrets',async()=>{const {worker,calls}=harness({failure:true});assert.deepEqual(await worker(),{sent:0,failed:1,stale:0});assert.deepEqual(calls.at(-1),['complete','event-id','lease-id',false]);});
test('lost lease acknowledged as stale rather than sent',async()=>{const {worker}=harness({ack:false});assert.deepEqual(await worker(),{sent:0,failed:0,stale:1});});
test('unknown type fails without sending arbitrary payload',async()=>{const {worker,calls}=harness({rows:[{...notice,notification_type:'unknown'}]});assert.deepEqual(await worker(),{sent:0,failed:1,stale:0});assert.equal(calls.some(c=>c[0]==='deliver'),false);});
test('recipient header injection is denied',async()=>{const {worker,calls}=harness({recipient:'student@example.test\r\nBcc: victim@example.test'});assert.deepEqual(await worker(),{sent:0,failed:1,stale:0});assert.equal(calls.some(c=>c[0]==='deliver'),false);});
test('unconfirmed provider response is a delivery failure',async()=>{const calls=[];const worker=createWorker({enabled:true,store:{claim:async()=>[notice],complete:async(...a)=>{calls.push(a);return true;}},resolveRecipient:async()=> 'student@example.test',deliver:async()=>({accepted:false})});assert.equal((await worker()).failed,1);assert.equal(calls[0][2],false);});
test('all supported status notifications have fixed email templates',async()=>{for(const type of ['payment_verified','bank_transfer_approved','bank_transfer_rejected','enrollment_revoked','enrollment_changed']) {const {worker,calls}=harness({rows:[{...notice,notification_type:type}]});assert.equal((await worker()).sent,1);assert.ok(calls.find(c=>c[0]==='deliver')[1].subject);}});
test('delivery timeout marks safe retry even when provider ignores cancellation',async()=>{const calls=[];let signal;const worker=createWorker({enabled:true,deliveryTimeoutMs:5,store:{claim:async()=>[notice],complete:async(...a)=>{calls.push(a);return true;}},resolveRecipient:async()=> 'student@example.test',deliver:async mail=>{signal=mail.signal;await new Promise(r=>setTimeout(r,50));return {accepted:true};}});assert.equal((await worker()).failed,1);assert.equal(signal.aborted,true);assert.equal(calls[0][2],false);});
