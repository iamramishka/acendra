# CSA-207/210: Production secret and payment preparation

Date: 2026-10-14 (Asia/Colombo). Preparation status: IN_REVIEW.
CSA-207 and CSA-210 operational configuration remains pending.
Owner: CODEX secrets/payment agent. Assignment and exclusive scope:
[preparation board](../tasks/CSA-205-210-PREPARATION.md).

This is a dummy configuration worksheet. No secrets were injected, endpoints
enabled, provider requests sent or production targets configured. All values
below are intentionally unusable; never execute a deployment with them.

## Public browser configuration

`lib/core/config/env_config.dart` reads compile-time Dart environment settings.
Flutter does not load the repository `.env`. Keep only public settings in the
later approved build configuration; a public key still requires correct RLS.

| Actual binding | Dummy value | Treatment |
| --- | --- | --- |
| `APP_ENV` | `production` | Public environment selector |
| `SUPABASE_URL` | `https://supabase.example.invalid` | Public target; replace with verified production project URL |
| `SUPABASE_PUBLISHABLE_KEY` | `DUMMY_PUBLIC_KEY_DO_NOT_BUILD` | Public publishable key; dummy deliberately fails key validation |
| `SUPABASE_ANON_KEY` | `DUMMY_PUBLIC_KEY_DO_NOT_BUILD` | Legacy public fallback when publishable binding is absent |

The frontend validates hosted HTTPS URLs and rejects privileged key shapes;
this does not prove that a key belongs to the intended project. Verify project
identity separately. Never put service-role, PayHere, Mux private signing or
SMTP credentials in Dart defines, browser files, source control or build logs.

## Backend configuration inventory

The following names are actual `env(...)` reads in `supabase/functions`.
Use the production project's managed backend configuration after target and
access approval. Supabase-provided runtime values must be verified in that
project; this document does not prescribe overwriting reserved platform values.

| Actual binding | Dummy value | Purpose and boundary |
| --- | --- | --- |
| `SUPABASE_URL` | `https://supabase.example.invalid` | Backend project URL; must match browser project |
| `SUPABASE_ANON_KEY` | `DUMMY_PUBLIC_KEY_DO_NOT_BUILD` | Public key used by backend Auth requests; independent of frontend publishable binding |
| `SUPABASE_SERVICE_ROLE_KEY` | `REPLACE_IN_APPROVED_SECRET_STORE` | Privileged backend-only credential |
| `MUX_SIGNING_KEY_ID` | `DUMMY_MUX_SIGNING_KEY_ID` | Backend video signing key identifier |
| `MUX_SIGNING_PRIVATE_KEY_PEM` | `REPLACE_IN_APPROVED_SECRET_STORE` | Backend-only private signing material |
| `ACENDRA_ADMIN_ALLOWED_ORIGINS` | `https://courses.example.invalid` | Admin CORS allowlist |
| `ACENDRA_CHECKOUT_ALLOWED_ORIGINS` | `https://courses.example.invalid` | Checkout and bank-receipt CORS allowlist |
| `ACENDRA_VIDEO_ALLOWED_ORIGINS` | `https://courses.example.invalid` | Video authorization CORS allowlist |
| `PDF_ALLOWED_ORIGINS` | `https://courses.example.invalid` | PDF delivery CORS allowlist |
| `ACENDRA_CHECKOUT_BANK_VERSION_ID` | `DUMMY_BANK_VERSION_ID` | Must resolve to reviewed production bank instructions; dummy is not a valid record |

Sources include `create-checkout-order/handler.mjs`,
`admin-assign-user-role/handler.mjs`, `authorize-video/handler.mjs`,
`pdf-content/handler.mjs` and `_shared/pdf/authorization.mjs`.
Origin allowlists are comma-separated exact approved origins, without wildcards.
SMTP/Auth provider settings require a separate approved account configuration;
no SMTP environment binding is invented here.

## PayHere code gate

PayHere and LKR are approved selections under
[CSA-004](../requirements/CSA-004-PAYMENT-DECISION.md). Live merchant activation,
approved domain, plan and retrieval access have not been verified.

`supabase/functions/initialize-checkout/index.ts` injects only `env` into its
handler. `initialize-checkout/handler.mjs` defaults `onlineCheckoutEnabled` to
`false` and returns HTTP 503 `ONLINE_CHECKOUT_UNAVAILABLE` for online checkout.
It receives `paymentConfig` through dependency injection, not environment reads.

`supabase/functions/payment-provider-webhook/index.ts` also injects only `env`.
Its handler defaults `onlinePaymentsEnabled` to `false` and returns HTTP 503
`ONLINE_PAYMENTS_UNAVAILABLE`; `providerConfig` is injected separately.
No environment variable can enable these deployed entry points. Secret injection
alone cannot complete CSA-210. Keep these gates intact during dummy preparation.

`_shared/payments/payhere.mjs` consumes the following object properties. These
are **adapter properties, not implemented production environment bindings**:

| Property | Dummy worksheet value |
| --- | --- |
| `environment` | `production` |
| `ready` | `false` (adapter rejects configuration) |
| `merchantId` | `DUMMY_PAYHERE_MERCHANT_ID` |
| `merchantSecret` | `REPLACE_IN_APPROVED_SECRET_STORE` |
| `appId` | `DUMMY_PAYHERE_APP_ID` |
| `appSecret` | `REPLACE_IN_APPROVED_SECRET_STORE` |
| `returnUrl` | `https://courses.example.invalid/DUMMY_RETURN_ROUTE` |
| `cancelUrl` | `https://courses.example.invalid/DUMMY_CANCEL_ROUTE` |
| `notifyUrl` | `https://supabase.example.invalid/functions/v1/payment-provider-webhook` |

Return/cancel route names above are unimplemented placeholders. Resolve actual
approved routes and webhook URL against the selected production project.
Merchant secrets and OAuth app secrets serve different purposes and cannot
substitute for each other. Future environment-to-object mapping and endpoint
enablement requires a separately reviewed runtime change with an accountable
financial owner after provider acceptance.

## Configuration and rotation procedure for later live work

1. Verify `DUMMY_PRODUCTION_PROJECT_REF` replacement, selected project URL,
   environment isolation, approved domain, operator and managed secret store.
   Record configuration names and version identifiers, never credential values.
2. Grant narrowly scoped release access with MFA. Keep staging and production
   credentials separate; exclude production secrets from untrusted PR jobs.
3. Inject approved backend secrets through protected account tooling. Validate
   required names, formats and project identity without printing values.
   Reject remaining dummy markers before any build or deploy.
4. Test approved origin preflights, foreign-origin rejection, authentication,
   entitlement checks and signing using authorized validation accounts. CORS
   does not replace backend authorization. Scan built browser assets for
   privileged credentials before release.
5. For rotation, identify every consumer and in-flight payment/signing effect;
   prepare replacement credentials in the provider and managed store, validate
   approved canaries, switch consumers and revoke old material after a reviewed
   overlap where the provider supports it. Do not assume provider dual-key
   support. Record operator, timestamps, versions and redacted verification.
6. If compromise caused rotation, revoke compromised credentials promptly and
   follow the incident process. Preserve financial evidence and reconcile
   in-flight callbacks; do not roll back to compromised credentials.

## Payment acceptance before activation

[CSA-100 adapter contract](../contracts/CSA-100-PAYMENT-ADAPTER.md) retains real
sandbox acceptance requirements. The
[Phase 5 reconciliation](../tasks/CSA-PHASE5-STATUS-RECONCILIATION.md) records
CSA-100 BLOCKED: historical OAuth success does not establish checkout,
callback/retrieval binding or fulfillment acceptance.

- Complete controlled real sandbox checkout, original signed callback and
  authenticated retrieval evidence. The read-only sandbox probe alone does
  not exercise checkout or entitlement fulfillment.
- Validate exact server-priced LKR amount, order, merchant, environment,
  transaction reference and success status. Reject checksum forgery and
  mismatches. A return redirect must never grant access.
- Verify duplicate, delayed and concurrent callbacks, retry behavior, bank
  approval races, pending/failure/cancel states and refund/reversal behavior
  against approved policies. Confirm database atomicity and one entitlement.
- Obtain review of the concrete production binding/enablement change and
  retained release gates. Verify active merchant/plan, domain, callback reachability,
  Retrieval API access and isolated production credentials through authorized
  account access.
- Conduct owner-approved controlled live validation and notification acceptance
  under CSA-211; capture redacted provider/database evidence and reconciliation.
  Do not create real charges as part of this dummy worksheet.

Preparation verification: source-reference inspection and `git diff --check`.
No provider, database, browser, production configuration or rotation acceptance
is claimed. Operational tasks move to DONE only after their actual acceptance
and integration evidence is recorded.
