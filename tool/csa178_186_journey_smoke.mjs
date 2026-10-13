import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { createHash, createHmac, randomBytes, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { createHandler as orderHandler } from '../supabase/functions/create-checkout-order/handler.mjs';
import { createHandler as initializeHandler } from '../supabase/functions/initialize-checkout/handler.mjs';
import { createHandler as webhookHandler } from '../supabase/functions/payment-provider-webhook/handler.mjs';
import { createHandler as receiptHandler } from '../supabase/functions/upload-bank-receipt/handler.mjs';
import { createHandler as reviewHandler } from '../supabase/functions/admin-review-bank-transfer/handler.mjs';

const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfWQAAAAASUVORK5CYII=', 'base64');
export const fixtureInspector = Object.freeze({ policyReference: 'synthetic-exact-png-only', timeoutMs: 1000,
  inspect: async ({ bytes, mime, size, sha256 }) => ({ safe: Buffer.from(bytes).equals(png), parseable: Buffer.from(bytes).equals(png),
    encrypted: false, withinResourceLimits: size === png.length, mime, size, sha256, policyReference: 'synthetic-exact-png-only' }) });
function totp(secret) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  const bits = [...secret.replace(/=+$/, '').toUpperCase()].map(c => alphabet.indexOf(c).toString(2).padStart(5, '0')).join('');
  const key = Buffer.from(bits.match(/.{8}/g).map(b => parseInt(b, 2)));
  const counter = Buffer.alloc(8); counter.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000)));
  const hash = createHmac('sha1', key).update(counter).digest(), offset = hash[19] & 15;
  return ((hash.readUInt32BE(offset) & 0x7fffffff) % 1000000).toString().padStart(6, '0');
}

// Production handlers are mounted only in a test-local HTTP server. Auth/RPC/Storage
// use the real disposable stack. Provider responses, bank credit and inspector are
// explicitly synthetic: this does not establish live provider or production readiness.
export async function runJourneySmoke({ root, layout, env, sql, base, key, containers }) {
  let stage = 'local target guard', server;
  try {
    assert.equal(base, `http://127.0.0.1:${layout.portBase}`);
    const statusResult = spawnSync(process.execPath, [path.join(root, 'node_modules/supabase/dist/supabase.js'),
      'status', '--output', 'json', '--workdir', layout.workdir, '--network-id', `${layout.projectId}-loopback`], { env, encoding: 'utf8' });
    assert.equal(statusResult.status, 0);
    const status = JSON.parse(statusResult.stdout); assert.equal(status.API_URL, base);
    stage = 'legacy local handler credential availability';
    const fields = containers.flatMap(c => c.Config?.Env ?? []);
    const field = n => fields.find(v => v.startsWith(n + '='))?.slice(n.length + 1);
    // Handler REST calls use the internal legacy JWT, never an opaque secret in Bearer.
    const service = status.SERVICE_ROLE_KEY || field('SERVICE_KEY') || field('SUPABASE_SERVICE_ROLE_KEY');
    assert.equal(service?.split('.').length, 3);
    stage = 'synthetic bank fixture setup';
    const bank = randomUUID(), version = randomUUID();
    sql(`insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name,currency_code)
      values('${version}','${bank}',1,'Synthetic bank','Synthetic owner','TEST-ONLY','Synthetic branch','LKR');`);
    const config = { SUPABASE_URL: base, SUPABASE_ANON_KEY: key, SUPABASE_SERVICE_ROLE_KEY: service, ACENDRA_CHECKOUT_BANK_VERSION_ID: version };
    const getEnv = n => config[n];
    const provider = { ready: true, environment: 'sandbox', merchantId: '123456', merchantSecret: 'synthetic-secret', appId: 'synthetic-app',
      appSecret: 'synthetic-app-secret', returnUrl: 'https://example.test/return', cancelUrl: 'https://example.test/cancel', notifyUrl: 'https://example.test/notify' };
    let providerAttempt;
    const transport = async (url, opts) => {
      if (url.startsWith(base + '/')) return fetch(url, opts);
      if (url === 'https://sandbox.payhere.lk/merchant/v1/oauth/token') return Response.json({ token_type: 'Bearer', access_token: 'synthetic-token' });
      if (url === `https://sandbox.payhere.lk/merchant/v1/payment/search?order_id=${providerAttempt}`) return Response.json({ status: 1, data: [{
        payment_id: '9007199254740993', order_id: providerAttempt, status: 'RECEIVED', currency: 'LKR', amount: '123.45',
        amount_detail: { currency: 'LKR', exchange_from: 'LKR', exchange_to: 'LKR', exchange_rate: '1', gross: '123.45' } }] });
      throw new Error('Unexpected outbound request');
    };
    const routes = {
      '/order': orderHandler({ env: getEnv, onlineCheckoutEnabled: true }),
      '/initialize': initializeHandler({ env: getEnv, onlineCheckoutEnabled: true, paymentConfig: provider }),
      '/webhook': webhookHandler({ env: getEnv, onlinePaymentsEnabled: true, providerConfig: provider, fetch: transport }),
      '/receipt': receiptHandler({ env: getEnv, receiptUploadsEnabled: true, inspector: fixtureInspector }),
      '/review': reviewHandler({ env: getEnv, bankReviewEnabled: true }),
      '/default-webhook': webhookHandler({ env: getEnv }), '/default-review': reviewHandler({ env: getEnv }),
    };
    server = createServer(async (req, res) => {
      try {
        const chunks = []; let size = 0;
        for await (const chunk of req) { size += chunk.length; assert.ok(size <= 6 * 1024 * 1024); chunks.push(chunk); }
        const handler = routes[req.url]; assert.ok(handler);
        const response = await handler(new Request(`http://127.0.0.1:61410${req.url}`, { method: req.method, headers: req.headers,
          ...(req.method !== 'GET' ? { body: Buffer.concat(chunks) } : {}) }));
        res.writeHead(response.status, Object.fromEntries(response.headers)); res.end(Buffer.from(await response.arrayBuffer()));
      } catch { res.writeHead(500, { 'Content-Type': 'application/json' }); res.end(JSON.stringify({ error: { code: 'TEST_TRANSPORT_FAILURE' } })); }
    });
    await new Promise((resolve, reject) => { server.once('error', reject); server.listen(61410, '127.0.0.1', resolve); });
    const http = async (route, token, body, extra = {}) => {
      const response = await fetch('http://127.0.0.1:61410' + route, { method: 'POST', headers: { 'Content-Type': 'application/json',
        'Idempotency-Key': randomUUID(), ...(token ? { Authorization: 'Bearer ' + token } : {}), ...extra },
        body: body instanceof Uint8Array || body instanceof URLSearchParams ? body : JSON.stringify(body), signal: AbortSignal.timeout(30000) });
      const bodyResult = await response.json();
      const safeCodes = new Set(['AUTH_REQUIRED','FORBIDDEN','INVALID_REQUEST','INVALID_IDEMPOTENCY_KEY','SERVICE_UNAVAILABLE','ORDER_CREATION_FAILED','BANK_CHECKOUT_UNAVAILABLE','TEST_TRANSPORT_FAILURE']);
      stage += ` status=${response.status}` + (safeCodes.has(bodyResult?.error?.code) ? ` code=${bodyResult.error.code}` : '');
      return { status: response.status, body: bodyResult };
    };
    const api = async (route, token, body, method = 'POST') => {
      const r = await fetch(base + route, { method, headers: { apikey: key, 'Content-Type': 'application/json',
        ...(token ? { Authorization: 'Bearer ' + token } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(30000) });
      return { status: r.status, body: r.status === 204 ? null : await r.json() };
    };
    const signup = async () => {
      const email = `journey-${randomBytes(8).toString('hex')}@example.com`, password = randomBytes(24).toString('hex') + 'Aa!1';
      const r = await api('/auth/v1/signup', undefined, { email, password }); assert.equal(r.status, 200);
      const id = r.body.user?.id ?? r.body.id; assert.match(id, /^[0-9a-f-]{36}$/);
      sql(`update auth.users set email_confirmed_at=coalesce(email_confirmed_at,now()) where id='${id}'`);
      const login = await api('/auth/v1/token?grant_type=password', undefined, { email, password }); assert.equal(login.status, 200);
      return { id, token: login.body.access_token };
    };
    stage = 'real Auth buyer peer and finance MFA';
    const buyer = await signup(), peer = await signup(), finance = await signup();
    sql(`insert into public.user_roles(user_id,role_id) select '${finance.id}',id from public.roles where code='finance_admin'`);
    const factor = await api('/auth/v1/factors', finance.token, { factor_type: 'totp', friendly_name: 'Synthetic journey TOTP' }); assert.equal(factor.status, 200);
    const challenge = await api(`/auth/v1/factors/${factor.body.id}/challenge`, finance.token, {}); assert.equal(challenge.status, 200);
    const verified = await api(`/auth/v1/factors/${factor.body.id}/verify`, finance.token, { challenge_id: challenge.body.id, code: totp(factor.body.totp.secret) });
    assert.equal(verified.status, 200); finance.token = verified.body.access_token;
    const course = randomUUID(), section = randomUUID(), lesson = randomUUID();
    sql(`insert into public.courses(id,slug,title,price_minor,status,published_at) values('${course}','journey-${course}','Synthetic journey',12345,'published',now());
      insert into public.course_sections(id,course_id,title,position,is_published) values('${section}','${course}','Synthetic',0,true);
      insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values('${lesson}','${section}','Synthetic text','text',0,true);`);
    const claims = JSON.parse(Buffer.from(buyer.token.split('.')[1], 'base64url').toString());
    assert.match(claims.session_id, /^[0-9a-f-]{36}$/);
    const sessionAal = sql(`select coalesce(aal::text,'null') from auth.sessions where id='${claims.session_id}' and user_id='${buyer.id}'`);
    stage = 'real buyer session assurance=' + (['aal1','aal2','null',''].includes(sessionAal) ? sessionAal || 'missing' : 'unexpected');
    assert.equal(sessionAal, claims.aal);
    const entitlement = async (user, value) => { const r = await api('/rest/v1/rpc/csa117_verify_entitlement', user.token, { p_course: course }); assert.equal(r.status, 200); assert.equal(r.body, value); };
    stage = 'bank order and real receipt Storage without premature access';
    stage = 'bank order HTTP creation';
    const bankOrder = await http('/order', buyer.token, { course_id: course, payment_method: 'bank_transfer' }); assert.equal(bankOrder.status, 201);
    const order = bankOrder.body.data.order_id;
    stage = 'pending bank entitlement HTTP denial';
    await entitlement(buyer, false);
    stage = 'foreign receipt HTTP denial';
    const foreignReceipt = await http('/receipt', peer.token, png, { 'Content-Type': 'image/png', 'X-Order-Id': order, 'X-Receipt-Name': 'fixture.png' }); assert.equal(foreignReceipt.status, 403);
    stage = 'owner receipt HTTP upload';
    const uploaded = await http('/receipt', buyer.token, png, { 'Content-Type': 'image/png', 'X-Order-Id': order, 'X-Receipt-Name': 'fixture.png' }); assert.equal(uploaded.status, 201);
    stage = 'submitted receipt pending entitlement';
    assert.equal(uploaded.body.data.order_status, 'pending_verification'); await entitlement(buyer, false);
    stage = 'pending receipt progress HTTP denial';
    assert.equal((await api('/rest/v1/rpc/csa133_save_progress', buyer.token, { p_lesson: lesson, p_completed: true })).status, 403);
    const review = { submission_id: uploaded.body.data.submission_id, decision: 'approve', verified_credit: { bank_credit_confirmed: true,
      destination_account_id: bank, bank_transaction_id: 'synthetic-' + randomUUID(), amount_minor: '12345', currency: 'LKR',
      settled_at: new Date(Date.now() - 1000).toISOString(), source: 'bank_statement', order_reference: sql(`select order_number from public.orders where id='${order}'`) } };
    stage = 'effective reviewer denial and synthetic credit approval';
    assert.equal((await http('/review', buyer.token, review)).status, 403);
    assert.equal((await http('/default-review', finance.token, review)).status, 503);
    const reviewKey = randomUUID(); const accepted = await http('/review', finance.token, review, { 'Idempotency-Key': reviewKey }); assert.equal(accepted.status, 200);
    assert.equal((await http('/review', finance.token, review, { 'Idempotency-Key': reviewKey })).status, 200);
    assert.equal(sql(`select count(*) from public.enrollment_grants where user_id='${buyer.id}' and course_id='${course}'`), '1');
    await entitlement(buyer, true); await entitlement(peer, false);
    stage = 'online initialization forged callback and synthetic retrieved settlement';
    const online = await http('/order', peer.token, { course_id: course, payment_method: 'online' }); assert.equal(online.status, 201);
    const customer = { first_name: 'Synthetic', last_name: 'Buyer', phone: '+94770000000', address: 'Synthetic', city: 'Synthetic', country: 'Sri Lanka' };
    const init = await http('/initialize', peer.token, { order_id: online.body.data.order_id, customer }); assert.equal(init.status, 201); providerAttempt = init.body.data.attempt_id;
    await entitlement(peer, false);
    const form = new URLSearchParams({ merchant_id: '123456', order_id: providerAttempt, payment_id: '9007199254740993', payhere_amount: '123.45', payhere_currency: 'LKR', status_code: '2', md5sig: '0'.repeat(32) });
    assert.equal((await http('/webhook', undefined, form, { 'Content-Type': 'application/x-www-form-urlencoded' })).status, 400); await entitlement(peer, false);
    const md5 = v => createHash('md5').update(v).digest('hex').toUpperCase();
    form.set('md5sig', md5('123456' + providerAttempt + '123.45LKR2' + md5(provider.merchantSecret)));
    assert.equal((await http('/default-webhook', undefined, form, { 'Content-Type': 'application/x-www-form-urlencoded' })).status, 503);
    assert.equal((await http('/webhook', undefined, form, { 'Content-Type': 'application/x-www-form-urlencoded' })).status, 200);
    assert.equal((await http('/webhook', undefined, form, { 'Content-Type': 'application/x-www-form-urlencoded' })).status, 200);
    await entitlement(peer, true);
    stage = 'two entitled students real progress HTTP isolation';
    const save = async (user, completed) => { const r = await api('/rest/v1/rpc/csa133_save_progress', user.token, { p_lesson: lesson, p_completed: completed }); assert.equal(r.status, 200); };
    await save(buyer, true); await save(peer, false);
    for (const [user, value] of [[buyer, true], [peer, false]]) {
      const r = await api('/rest/v1/rpc/csa133_read_progress', user.token, { p_course: course }); assert.equal(r.status, 200); assert.equal(r.body.length, 1); assert.equal(r.body[0].is_completed, value);
      const foreign = user === buyer ? peer : buyer;
      const orders = await api(`/rest/v1/orders?buyer_id=eq.${foreign.id}&select=id`, user.token, undefined, 'GET'); assert.equal(orders.status, 200); assert.deepEqual(orders.body, []);
    }
    assert.equal(sql(`select count(*) from public.enrollment_grants where user_id='${peer.id}' and course_id='${course}'`), '1');
    console.log('PASS: real HTTP/Auth/MFA/RPC/receipt Storage bank and online handler integration, pending/forged access denial, idempotent settlement and two-entitled-student progress isolation; provider/credit/inspection evidence synthetic.');
  } catch { throw new Error('Journey smoke failed at ' + stage + '; private diagnostics suppressed.'); }
  finally { if (server?.listening) await new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }); }
}
