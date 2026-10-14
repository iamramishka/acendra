# CSA-212 — Finance permission acceptance procedure

Status: IN_REVIEW preparation; production acceptance pending. Owner: CODEX.
Date: 2026-10-15 (Asia/Colombo). Coordination: `docs/tasks/CSA-211-216-PREPARATION.md` in the integration checkout. Exclusive scope: this document.
Baseline: dev `7916c6eb69c2fa108df4d9a8511b9cf0503fa607`. Open PR #153 changes bank flows; recheck its final merge and the deployed revision before applying this procedure. This snapshot is not evidence of deployed behavior.

The owner authorized preparation with dummy targets. Use `https://db.test` and `https://example.test/review` only as illustrative targets matching the existing HTTP fixtures; they are not configured services. Fixture strings `public` and `private` are dummy test values, never deployment credentials. No live target is selected by this document.

## Current release boundary

[`admin-review-bank-transfer/index.ts`](../../supabase/functions/admin-review-bank-transfer/index.ts) does not enable `bankReviewEnabled`. The [handler](../../supabase/functions/admin-review-bank-transfer/handler.mjs) returns HTTP 503 `BANK_REVIEW_UNAVAILABLE` before I/O by default; no environment flag enables it. The finance screen remains a synthetic preview. A disabled endpoint proves fail-closed behavior, but cannot satisfy positive operational finance acceptance. Enabling review, queue/receipt access and live UI integration require reviewed implementation and release evidence.

The [bank workflow migration](../../supabase/migrations/20261011001700_csa108_113_bank_workflow.sql) checks live account/session, AAL2 and current finance_admin/super_admin authority under locks, denies own review before replay, and exposes the trusted review RPC only to service_role. Browser metadata supplies no privileges. Independent bank credit evidence must match the order; receipt upload alone does not verify credit.

## Acceptance matrix

Execute state-changing probes only against isolated synthetic fixtures in a staging environment matching the deployment. Record both HTTP results and trusted state observations; SQL errors below describe the RPC boundary, not every gateway response.

| Boundary | Probe and expected result | Existing regression coverage |
|---|---|---|
| Positive authority | Independent current finance_admin and super_admin, verified AAL2: approve exact settled credit or reject with safe reason. One decision only; rejection grants no access. Operational endpoint must be enabled through reviewed release. | Bank workflow SQL; handler HTTP suite |
| Role isolation | Student, content manager, revoked finance role and forged role metadata: denied, no financial mutation. Role revocation also denies replay. | Bank workflow SQL; admin denial SQL/HTTP |
| MFA and identity | AAL1, missing/mismatched actor/session, anonymous, banned/deleted account, expired/deleted/downgraded session, forged JWT: denied. SQL authorization failures are 42501. | Financial recovery SQL; admin denial SQL/HTTP; handler HTTP |
| Independent review | Buyer or receipt submitter cannot approve or reject their own submission even with finance/super authority; retry cannot bypass independence. | Bank workflow SQL; inspect final deployed RPC and add missing variant coverage before acceptance |
| Cross-user access | Student A cannot read Student B's submission/receipt or alter its decision through browser tables, APIs or storage. Authorized reviewer may review another buyer only through trusted permission checks. | Bank workflow storage SQL; admin denial SQL; hosted cross-user read probes remain required |
| Browser RPC and DML | anon/authenticated cannot EXECUTE csa112_review_bank_transfer, insert paid enrollment, mutate settlement/submission, or assign trusted roles. Forged actor parameters cannot bypass service-only grants. | Bank workflow SQL; financial recovery SQL; admin denial SQL |
| Receipt privacy | bank-receipts private; unauthenticated/cross-user listing/download and arbitrary path upload denied. Finalized bytes cannot be replaced/deleted through client privileges. Finance receipt viewing requires its reviewed delivery boundary; do not enable a public bucket. | Bank workflow SQL; live storage delivery/listing checks pending |
| Concurrency and replay | Same-key retries yield one review/settlement/grant/outbox event; opposing decisions cannot both commit; one bank credit cannot fund two orders. Committed role revocation blocks subsequent review. | Bank concurrency suite |
| Audit and rollback | Immutable reviewer attribution and safe/public versus private notes; audit/outbox failure rolls back all financial state and permits same-key recovery. Denied calls leave no state change. | Financial recovery SQL; audit integrity SQL; admin denial SQL |
| Gateway and output | Allowlisted production origin, expected preflight headers, Auth validation, sanitized failures, no-store responses and no private notes/credit/secrets in browser output. | Handler HTTP suite; real Auth/CORS/PostgREST verification pending |

Coverage references: [bank workflow SQL](../../supabase/tests/database/csa108_113_bank_workflow.test.sql), [financial recovery SQL](../../supabase/tests/database/csa121_126_financial_recovery.test.sql), [admin denial SQL](../../supabase/tests/database/csa176_admin_denials.test.sql), [audit integrity SQL](../../supabase/tests/database/csa174_audit_integrity.test.sql), [bank concurrency](../../tool/csa108_113_concurrency.test.mjs), [handler HTTP](../../supabase/functions/admin-review-bank-transfer/handler.test.mjs), [admin denial HTTP](../../tool/csa176_admin_denials.test.mjs).

## Verification procedure

1. Record target environment, deployed frontend/function revision, migration ledger, reviewer and authorization for the release. Compare the deployed RPC/function grants, RLS, storage policies and handler with the final reviewed source, including PR #153 changes. Keep secret values and personal financial data out of evidence.
2. Run migrations and the referenced SQL tests in a disposable database. Run concurrency tests only with their documented opt-in configuration against a disposable database; inspect the runner before selecting a target. Never point these fixture/fault-injection suites at production.
3. Run the HTTP command below. These tests use mocked Auth/RPC responses and synthetic enablement; they do not validate JWT signing or hosted roles.
4. In staging, create separate synthetic buyer, ordinary student, content manager, independent finance reviewer and super administrator identities. Use the existing bank credit contract and synthetic fixtures; obtain verified AAL2 sessions through real Auth. Complete every matrix probe, including post-revocation replay and live storage isolation. Compare trusted before/after financial, enrollment, audit and outbox state.
5. For positive decisions, verify exact settlement/order linkage, safe response fields and current reviewer attribution. Exercise opposite decision/replay and role-revocation races with isolated fixtures. Confirm a rejected or denied request grants no paid entitlement.
6. On production, perform read-only deployment/configuration comparisons and evidence review. A real financial decision or role mutation requires a separately authorized operational transaction. Record any omitted probe as unverified; retain CSA-212 unchecked until the full acceptance matrix, required security review and release conditions are satisfied.

```sh
node --test supabase/functions/admin-review-bank-transfer/handler.test.mjs tool/csa176_admin_denials.test.mjs
```

## Execution evidence for this preparation

On the baseline above, the isolated checkout ran the two HTTP suites: **175 passed, 0 failed, 0 skipped**, exit 0. No production call, role mutation or configuration change was made. SQL, concurrency, live Supabase Auth/PostgREST/storage, hosted configuration and production acceptance were not executed. SQL tooling was unavailable on PATH during discovery; existing historical test records are references, not a fresh execution claim. Documentation links and `git diff --check` are verified before commit.

## Acceptance evidence template

| Field | Required recorded value |
|---|---|
| Environment and deployment | Target identity; frontend/function commit; migration ledger; verification time/timezone |
| Governance | Task owner; authorized security reviewer; release authorization/evidence reference |
| Matrix result | One row per probe: synthetic fixture alias, expected/actual HTTP or SQL result, pass/fail/unverified |
| State evidence | Sanitized before/after comparison; review/settlement/grant/audit/outbox counts; no personal financial payloads |
| Auth and access | Real AAL/session/role checks; revocation results; browser and storage isolation; CORS evidence |
| Execution | Exact command, tool versions, exit code, passed/failed/skipped totals, retained sanitized logs |
| Remaining gaps | Disabled endpoint, missing boundary, omitted probes, deployment differences and accountable next owner |
| Final acceptance | Review decision and date; completion evidence; CSA-212 remains pending until accepted |

All template fields currently pending except the baseline and HTTP preparation results above. This document supplies a reviewable procedure and records local evidence; it does not certify production finance permissions.
