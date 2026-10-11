# CSA-100 PayHere adapter contract

Status: IN_REVIEW. Owner: CODEX. Date: 2026-10-11.

Trusted backend import: `supabase/functions/_shared/payments/payhere.mjs`.
No HTTP endpoint, database mutation, enrollment grant, or payment finalization
is supplied by this adapter. CSA-101/102/104 remain separate consumers.

## Configuration and terms

`createPayHereAdapter(config)` requires `ready: true`, `environment` equal to
`sandbox` or `production`, `merchantId`, `merchantSecret`, `appId`, `appSecret`,
and HTTPS `returnUrl`, `cancelUrl`, `notifyUrl`. Secrets are backend configuration
only. There are no default credentials, URLs, readiness, or environment fallback.
Readiness must reflect verified domain, merchant account, OAuth API permissions
and matching environment credentials. Production IP allowlisting is a release
gate. No such readiness is established by this implementation.

Every operation takes a stored, trusted attempt with `attemptId`, `orderId`,
`method: online`, `provider: payhere`, `merchantId`, `environment`,
`currency: LKR`, and positive `amountMinor` as a canonical decimal integer string.
The caller maps database order/attempt records to this shape; never populate
price, merchant, environment, or ownership from an HTTP client. `orderId` is the
exact unique identifier previously submitted to PayHere. Checkout also needs
the stored title in `title`.

## Operations

- `createCheckout(attempt, customer)` returns hosted `action` plus form `fields`.
  Customer fields: `first_name`, `last_name`, `email`, `phone`, `address`, `city`,
  `country`. Caller supplies authorized customer details. Money uses BigInt and
  two decimal places. Server-generated protocol MD5 is not a general-purpose
  password/security hash. Output contains a checkout hash, never merchant secret.
- `verifyNotification(form, attempt)` takes URLSearchParams from a bounded,
  form-encoded callback. Reject duplicate required fields, malformed inputs,
  incorrect merchant/order/amount/currency/status/checksum. Output is branded
  by this adapter instance and labeled `checksum_only`. Unsigned payment ID
  remains untrusted for settlement. Ignore customer/card metadata completely.
- `retrieveSettlement(notification, attempt)` accepts only a success notification
  produced by the same adapter. OAuth client credentials and fixed provider
  endpoints authenticate order search. Require exactly one matching payment ID
  with identical order, currency, exact amount and `RECEIVED` status. Both
  top-level amount and amount_detail.gross must match the order exactly; detail
  currency, exchange_from and exchange_to must be LKR with exchange_rate one.
  Missing, inconsistent or converted amount details fail closed. It returns
  minimal `authenticated_retrieval` evidence and retrieval timestamp. Other
  successful payments returned for the order remain reconciliation work; this
  method does not grant access or deduplicate database transactions.

Errors expose only stable `PaymentAdapterError.code`; callers must map these to
safe errors and avoid logging raw notification bodies, provider responses,
customer details, tokens, secrets or checkout configuration. Network requests
have a 10 second timeout, reject redirects and bound response bytes. Financial
JSON numeric lexemes are preserved as strings before JSON parsing, preventing
floating-point rounding of money and provider references. Non-decimal or
sub-cent provider amounts fail closed.

## Provider sources and readiness gate

Official pages read 2026-10-11:

- [Checkout API](https://support.payhere.lk/api-&-mobile-sdk/checkout-api)
- [Retrieval API](https://support.payhere.lk/api-&-mobile-sdk/retrieval-api)

These document hosted form checkout, callback checksum, OAuth token and
order-ID search. The callback checksum excludes payment_id. Retrieval may return
multiple payments for one order. The published retrieval example has differing
top-level `amount` and `amount_detail.gross`; this adapter requires both to match
and rejects that contradictory example. The provider's amount meanings must be
confirmed against sandbox before acceptance.

Required outstanding evidence: valid sandbox checkout/callback/retrieval,
merchant credential association, exact amount/reference binding, invalid and
changed unsigned callback rejection, duplicate/reversal responses, timeout and
rate-limit handling. Live merchant onboarding, domain/IP allowlisting and
credentials remain external configuration. No sandbox or production calls were
made. No new dependencies were introduced; node:crypto is supported by Deno.

## Read-only sandbox acceptance probe

Owner-approved dev integration exception (2026-10-11): real checkout acceptance
is deferred, with the deployed online order endpoint disabled by default and no
environment enable flag. Real sandbox OAuth succeeded; controlled checkout and
callback/retrieval binding remain unverified. This is not provider acceptance.
Online enablement requires a separately reviewed change after verification.

Run `npm run payment:sandbox:verify` in the integration checkout after securely
configuring these environment variables (never commit or log their values):

- `PAYHERE_SANDBOX_MERCHANT_ID` and `PAYHERE_SANDBOX_MERCHANT_SECRET`
- `PAYHERE_SANDBOX_APP_ID` and `PAYHERE_SANDBOX_APP_SECRET` with Retrieval API access
- `PAYHERE_SANDBOX_ORDER_ID` and `PAYHERE_SANDBOX_PAYMENT_ID` for an existing successful sandbox payment
- `PAYHERE_SANDBOX_AMOUNT_MINOR` for its authoritative expected LKR amount in cents
- `PAYHERE_SANDBOX_NOTIFICATION_FILE` pointing to its original URL-encoded successful callback, stored privately outside tracked files

The probe verifies the callback and performs sandbox OAuth/order retrieval,
including rejection of a changed unsigned payment ID. It never creates payments
or grants access. Success writes minimal private evidence under ignored
`build/payhere-sandbox/evidence.json`, including the adapter hash. A failed run
does not constitute acceptance; inspect its exit status and the evidence date
and hash before review. Merchant secrets cannot substitute for OAuth App secrets.
