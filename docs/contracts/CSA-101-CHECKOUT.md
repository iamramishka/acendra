# CSA-101 checkout initialization contract

Status: IN_REVIEW. Owner: CODEX. Date: 2026-10-11. Coordination issue #76.

POST /functions/v1/initialize-checkout. Verified authenticated non-anonymous
Supabase session; Idempotency-Key 1–128 ASCII letters, digits, dot/underscore/
colon/hyphen. JSON maximum 4096 bytes accepts exactly:

    {"order_id":"UUID","customer":{"first_name":"...","last_name":"...",
      "phone":"...","address":"...","city":"...","country":"..."}}

Every contact field is required, nonblank, at most 200 characters, no control
characters; phone additionally meets adapter format. Email is derived from
verified Auth user, never accepted in body. Contact fields are user-supplied
billing metadata only, passed to the provider form without database persistence
or logging. Country is contact information, not approval of territories.
Client actor, price, currency, merchant, provider environment/status are rejected.

Default deployment returns 503 ONLINE_CHECKOUT_UNAVAILABLE before Auth/RPC.
No environment variable can enable it. This preserves the owner's deferred
CSA-100 sandbox acceptance gate. Synthetic tests inject explicit enablement and
trusted paymentConfig; deployed index supplies neither. Future real enablement
requires separate reviewed code and successful sandbox acceptance.

Underlying enabled collaborator validates trusted PayHere configuration and
customer before creating an attempt. It verifies the exact bearer token with
Auth, binds returned user to authenticated token sub/session_id/aal, then calls
service-only csa101_initialize_checkout(p_actor UUID,p_session_id UUID,p_aal text,
p_key text,p_order UUID,p_merchant text,p_environment text). SQL exclusively
owned by CSA-104/105 worker rechecks current account/session and ownership,
online method, pending order, exact positive stored LKR terms and serializes
principal/key and order access. Existing active matching-scope attempt is reused
for another key; changed order or scope conflicts. Returned shape:

    {replayed:boolean,order_id:UUID,attempt:{attemptId:UUID,orderId:UUID,
      method:"online",provider:"payhere",merchantId:string,environment:string,
      currency:"LKR",amountMinor:decimalString,title:storedTitle}}

PayHere orderId is attempt UUID text, allowing precise callback routing; outer
order_id is internal order UUID. Handler verifies both identities and adapter
validates stored scope and exact money before generating hosted form/hash.
Response 201 new or 200 retry:

    {data:{order_id,attempt_id,status:"pending_payment",checkout:{action,fields}},
     meta:{contract_version:"v1",request_id}}

Checkout fields contain server-configured destinations and generated checksum,
never merchant secret/OAuth credentials. Price uses adapter BigInt formatting.
The response never means payment verified or entitlement granted. Provider
callback and authenticated retrieval/finalization remain separate consumers.

Safe errors: 400 INVALID_REQUEST/INVALID_IDEMPOTENCY_KEY/INVALID_CUSTOMER;
401 AUTH_REQUIRED; 403 ORIGIN_FORBIDDEN/PREFLIGHT_FORBIDDEN/FORBIDDEN;
404 ORDER_NOT_FOUND; 405 METHOD_NOT_ALLOWED; 409 CHECKOUT_CONFLICT/
ORDER_NOT_PAYABLE; 413 INVALID_REQUEST; 503 SERVICE_UNAVAILABLE/
ONLINE_CHECKOUT_UNAVAILABLE. No database/provider bodies or PII are logged.
Responses no-store. Origins use existing ACENDRA_CHECKOUT_ALLOWED_ORIGINS
allowlist with local development default; narrow declared preflight headers.
Auth/RPC requests have 15-second deadlines. Retry with the same key after timeout:
a committed attempt may exist; SQL idempotency prevents a new one.

No new dependencies. Synthetic boundary tests verify these surfaces; live
provider, database integration, CI and review are separate recorded gates.
