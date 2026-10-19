import test from 'node:test';
import assert from 'node:assert/strict';
import { inspectionRuntime, MEDIA_POLICY } from './inspection.mjs';
const input={bytes:new Uint8Array([1,2,3]),mime:'image/png',size:3,sha256:'a'.repeat(64),policyReference:MEDIA_POLICY.reference};
const settings={ACENDRA_MEDIA_INSPECTOR_URL:'https://inspector.invalid/inspect',ACENDRA_MEDIA_INSPECTOR_KEY:'k'.repeat(32),ACENDRA_MEDIA_POLICY:MEDIA_POLICY.reference};
test('missing/unreviewed/unsafe configuration leaves uploads disabled',()=>{
 for(const overrides of [{ACENDRA_MEDIA_POLICY:''},{ACENDRA_MEDIA_INSPECTOR_KEY:''},{ACENDRA_MEDIA_INSPECTOR_URL:'http://remote.invalid/inspect'},{ACENDRA_MEDIA_INSPECTOR_URL:'https://user:pass@remote.invalid/inspect'},{ACENDRA_MEDIA_POLICY:'unknown'}])
 assert.deepEqual(inspectionRuntime(k=>({...settings,...overrides})[k]),{});
});
test('inspection uses private binary transport and byte-bound verdict',async()=>{
 const runtime=inspectionRuntime(k=>settings[k],async(url,opts)=>{
 assert.equal(url,settings.ACENDRA_MEDIA_INSPECTOR_URL);assert.equal(opts.redirect,'error');
 assert.equal(opts.headers['X-Media-SHA256'],input.sha256);assert.equal(opts.body,input.bytes);
 return Response.json({...input,bytes:undefined,safe:true,parseable:true,encrypted:false,withinResourceLimits:true});
 });
 assert.equal(runtime.policy.reference,MEDIA_POLICY.reference);
 const result=await runtime.inspector(input);assert.equal(result.safe,true);assert.equal(result.bytes,undefined);
});
test('oversized/scanner-unavailable verdict fails closed',async()=>{
 for(const response of [()=>new Response('x'.repeat(4097)),()=>new Response('',{status:503})]){
 const runtime=inspectionRuntime(k=>settings[k],async()=>response());
 await assert.rejects(runtime.inspector(input));
 }
});
