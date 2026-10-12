import test from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPairSync,verify} from 'node:crypto';
import {signPlayback} from './signer.mjs';
import {createHandler} from './handler.mjs';
const {privateKey,publicKey}=generateKeyPairSync('rsa',{modulusLength:2048});
test('Mux RS256 signature independently verifies and expiry clamps',async()=>{
 const token=await signPlayback({playbackId:'signedPlayback',keyId:'key123',privateKey:privateKey.export({type:'pkcs8',format:'pem'}),now:1000,expiresAt:1200});
 const [h,p,s]=token.split('.'); assert.deepEqual(JSON.parse(Buffer.from(h,'base64url')),{alg:'RS256',typ:'JWT'});
 assert.deepEqual(JSON.parse(Buffer.from(p,'base64url')),{sub:'signedPlayback',aud:'v',kid:'key123',exp:1200});
 assert(verify('RSA-SHA256',Buffer.from(`${h}.${p}`),publicKey,Buffer.from(s,'base64url')));
});
test('signer rejects expired grant and invalid playback identifiers',async()=>{
 for(const x of [{expiresAt:1000},{playbackId:'../evil'}]) await assert.rejects(signPlayback({playbackId:'signedPlayback',keyId:'key123',privateKey:'bad',now:1000,expiresAt:1200,...x}));
});
test('deployed default denies before network or signer',async()=>{
 const h=createHandler({env:()=>'',fetch:()=>{throw Error('network');}}); assert.equal((await h(new Request('https://test',{method:'POST'}))).status,503);
});
const user='11111111-1111-1111-1111-111111111111',lesson='22222222-2222-2222-2222-222222222222',session='33333333-3333-3333-3333-333333333333';
const jwt=claims=>'Bearer '+Buffer.from('{}').toString('base64url')+'.'+Buffer.from(JSON.stringify({sub:user,role:'authenticated',session_id:session,aal:'aal1',exp:1400,...claims})).toString('base64url')+'.signature';
const req=(claims={},body={lesson_id:lesson})=>new Request('https://test',{method:'POST',headers:{Authorization:jwt(claims),'Content-Type':'application/json'},body:JSON.stringify(body)});
const env=()=> 'configured';
test('verified exact token forwarded; authorization expiry and playback used',async()=>{
 let calls=0;
 const h=createHandler({env,enabled:true,clock:()=>1000,sign:async args=>{assert.equal(args.expiresAt,1150);return 'signed';},fetch:async(url,opts)=>{
 calls++; if(calls===1){assert.equal(opts.headers.Authorization,jwt());return Response.json({id:user,is_anonymous:false});}
 assert.deepEqual(JSON.parse(opts.body),{p_actor:user,p_session_id:session,p_aal:'aal1',p_lesson:lesson,p_token_exp:1400});return Response.json({lesson_id:lesson,playback_id:'playback123',expires_at:1150});
 }});const r=await h(req());assert.equal(r.status,200);assert.match((await r.json()).data.playback_url,/playback123/);assert.equal(calls,2);
});
for(const claims of [{sub:session},{role:'service_role'},{session_id:'bad'},{aal:'aal3'},{exp:1000}])test('reject invalid verified claims '+JSON.stringify(claims),async()=>{
 let calls=0; const h=createHandler({env,enabled:true,clock:()=>1000,fetch:async()=>{calls++;return Response.json({id:user});}});assert.equal((await h(req(claims))).status,401);assert.equal(calls,1);
});
test('denied entitlement never invokes signer',async()=>{
 let calls=0;const h=createHandler({env,enabled:true,clock:()=>1000,sign:()=>{throw Error('must not sign');},fetch:async()=>++calls===1?Response.json({id:user}):Response.json({code:'42501'},{status:403})});assert.equal((await h(req())).status,403);
});
test('caller cannot choose course, user, playback or expiry',async()=>{const h=createHandler({env,enabled:true,fetch:()=>{throw Error('network');}});assert.equal((await h(req({}, {lesson_id:lesson,playback_id:'evil'}))).status,400);});
for(const grant of [{expires_at:1500},{expires_at:999},{lesson_id:session},{playback_id:'../evil'}])test('reject malformed grant '+JSON.stringify(grant),async()=>{
 let calls=0;const h=createHandler({env,enabled:true,clock:()=>1000,fetch:async()=>++calls===1?Response.json({id:user}):Response.json({lesson_id:lesson,playback_id:'playback123',expires_at:1200,...grant})});assert.equal((await h(req())).status,503);
});
test('web preflight allows configured origin and rejects foreign origin before Auth',async()=>{
 const h=createHandler({env:name=>name==='ACENDRA_VIDEO_ALLOWED_ORIGINS'?'https://web.test':'configured',enabled:true,fetch:()=>{throw Error('no Auth');}});
 const good=await h(new Request('https://test',{method:'OPTIONS',headers:{Origin:'https://web.test','Access-Control-Request-Method':'POST','Access-Control-Request-Headers':'authorization, content-type'}}));assert.equal(good.status,204);assert.equal(good.headers.get('Access-Control-Allow-Origin'),'https://web.test');
 assert.equal((await h(new Request('https://test',{method:'POST',headers:{Origin:'https://evil.test'}}))).status,403);
});
