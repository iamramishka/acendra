# Phase 5 parallel implementation handoff

Date: 2026-10-11. Integration owner: CODEX root. Draft PR #71 targets dev.

| Tasks | Implementation owner | Source PR | Acceptance |
| --- | --- | --- | --- |
| CSA-092 | CODEX root | #61 | DONE, merged dev56cedbd |
| CSA-093/096 | CODEX financial_ledger | #70 | IN_REVIEW |
| CSA-094/095 | CODEX bank_enrollments | #69 | IN_REVIEW |
| CSA-098 | CODEX root | #71 | IN_REVIEW |
| CSA-100 | CODEX payment_adapter | #68 | IN_REVIEW |

Each worker used a separate worktree with exclusive file ownership recorded in
issues #62–67 and task documents. Root imported committed worker changes into
the CSA-098 integration branch and reviewed the combined state. Original source
PRs remain drafts as traceable handoffs; #71 contains the complete ordered set.
No production configuration, deployment or paid fulfillment was performed.

## Integrated evidence

Code commit 2293e2c passed both workflows:

- [Flutter format/analyze/test/build](https://github.com/iamramishka/acendra/actions/runs/38141209649)
- [Supabase migration replay/existing database tests/lint/live isolation/MFA](https://github.com/iamramishka/acendra/actions/runs/38141209708)

Earlier startup failures were SQLSTATE42601 in migration014. Independent static
review identified an unparenthesized CASE inside a PL/pgSQL IF; correction passed
the complete existing migration workflow. Root temporarily owned the narrow
tool/local_supabase.mjs diagnostic change under issue64. Only bounded SQLSTATE
and migration names are exposed; private raw logs and keys remain suppressed.

Static cross-review also found mutable provider configuration/attempt terms.
CSA100 now freezes validated snapshots before asynchronous retrieval. Other
review changes preserve grant settlement identity and first fulfillment time,
reject contradictory/converted provider amounts, and match bank settlement to
the destination bound to its order. AI review is not human approval.

## Remaining acceptance and next action

Review fixes at commit `870c03f` passed both complete workflows:

- [Flutter format/analyze/test/build](https://github.com/iamramishka/acendra/actions/runs/38143420079)
- [Supabase migrations, financial assertions/races, lint, live isolation and MFA](https://github.com/iamramishka/acendra/actions/runs/38143420037)

The owner's request to fix PR #71 findings authorized focused tests. Issue #72
records isolated test ownership and integration scope. Added 68 checkout-handler
tests, 14 payment-adapter tests, 55 financial database assertions and 41 trusted
order assertions. All passed locally. A regression test exposed malformed JWT
claims returning 503; the handler now rejects these claims with 401.

Five races passed on independent PostgreSQL 16 sessions: identical idempotent
retries, conflicting retries, independent principals, duplicate settlement
references and duplicate active bank submissions. CI explicitly runs these
against its disposable Supabase database. Local PostgreSQL used a synthetic
Auth schema; full Supabase Auth behavior remains a CI check. The complete Node
suite passed with only the deliberately gated database-race suite skipped;
the separate enabled race run passed all five scenarios.

## Owner-approved deferred provider acceptance

On 2026-10-11 the owner explicitly approved deferring sandbox checkout
verification and merging the foundations into dev with online payments disabled.
The deployed create-checkout-order handler now rejects online requests with
503 ONLINE_CHECKOUT_UNAVAILABLE before any Auth or database request. Its default
is disabled and there is no environment enable switch. Regression tests verify
zero external requests while disabled; contract tests opt in only in tests.

Actual sandbox OAuth passed using a retrieval-only key. A simulated payment-link
payment succeeded, but it does not prove this adapter's callback/retrieval binding.
The controlled web checkout was rejected using the App integration credential;
PayHere also rejected a temporary tunnel subdomain as a web integration. The
tunnel and isolated local server were stopped. No provider verification pass is
claimed and no credentials were committed. This recorded owner decision permits
dev integration of the disabled foundations; it does not approve deployment or
online payment enablement. Re-enable only in a reviewed follow-up after real
sandbox checkout, callback and authenticated reference/amount binding pass.

CSA100 still requires real sandbox retrieval binding
and merchant readiness evidence per approved CSA004; official response amount
ambiguity fails closed until verified. Bank checkout needs a reviewed destination
version and server configuration. No credentials or real bank accounts are seeded.

The merchant secret supplied by the owner is insufficient for Retrieval API
OAuth. Separate sandbox App ID/App Secret and an existing successful sandbox
payment are required. The read-only `npm run payment:sandbox:verify` probe
documents these inputs in the adapter contract. Synthetic fixtures do not
resolve this acceptance gate. Provider acceptance remains deferred under the
owner decision above; task implementation acceptance is not payment readiness.

Downstream CSA101/102/104/105/112/114/116/117 implement checkout initialization,
webhook processing, atomic audited fulfillment, bank review and live entitlement
checks. This batch supplies their foundations and never treats a callback,
receipt or order row alone as paid access. Worktrees are retained for review.
