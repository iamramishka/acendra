# CSA-098 trusted order creation

Implementation contract, 2026-10-11. Requirements: approved CSA-004/006/008.

POST `/functions/v1/create-checkout-order`, verified authenticated non-anonymous
user session. Header `Idempotency-Key`: 1–128 ASCII letters, digits, `. _ : -`.
JSON accepts exactly `course_id` UUID and `payment_method` (`online` or
`bank_transfer`). Client prices, roles, actors, statuses and destination IDs are
rejected. Body maximum 4096 bytes.

Response 201 for creation, 200 for same principal/key/request replay:
`{data:{order_id,order_number,course:{id,title},amount_minor,currency_code,
payment_method,status,next_action},meta:{contract_version:"v1",request_id}}`.
Status is `pending_payment`; action is `initialize_online_payment` or
`show_bank_instructions`. Bank variant includes `bank_instructions` containing
bank name, holder, account number, branch and currency from the bound version.
No receipt storage reference or privileged credential is returned.

The service-only RPC `csa098_create_checkout_order` rechecks the current account
and session, snapshots a published course under a share lock, checks active
eligible grant sources and atomically inserts an order and immutable idempotency
result. SHA-256 hashes the canonical course/method request. Same key with changed
input conflicts. Replays retain original instructions and price even after course
or configured destination changes. Money remains exact LKR minor units, capped at
JavaScript's exact integer range. Zero-price orders do not grant access here;
entitlement policy remains at the trusted fulfillment boundary.

Lock order: account, session, principal/key advisory lock, course. External Auth
verification is completed before the SQL transaction; provider calls are outside
it. No payment attempt, settlement or enrollment is created by this operation.

Errors: 400 invalid request/key; 401 AUTH_REQUIRED; 403 FORBIDDEN/origin denial;
404 COURSE_NOT_FOUND; 409 ORDER_CONFLICT/ALREADY_ENROLLED; 413 oversized body;
503 SERVICE_UNAVAILABLE/BANK_CHECKOUT_UNAVAILABLE. Internal SQL messages are
not returned. A timeout may follow a committed order; retry with the same key.

Configuration: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, server-only
`SUPABASE_SERVICE_ROLE_KEY`, `ACENDRA_CHECKOUT_ALLOWED_ORIGINS` comma-separated
allowlist, and server-only `ACENDRA_CHECKOUT_BANK_VERSION_ID`. A reviewed trusted
bank version must exist before enabling bank checkout. Immutable destinations
are not seeded and no production configuration is applied.
Bank settlement `receiving_bank_account_scope` is the configured logical
`bank_account_id` UUID rendered as text. The settlement must match the immutable
destination bound to its order; account versions share that stable identity.

Dependency order: CSA-092 → CSA-095/096 → CSA-098. CSA-101 initializes attempts;
CSA-104/116 finalize verified payments and grant entitlements. This contract
does not replace those tasks or imply production payment readiness.
