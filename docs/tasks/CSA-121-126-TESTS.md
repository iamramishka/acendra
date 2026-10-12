# CSA-121–126 financial regression ownership and evidence

Owner CODEX. Issue87; isolated branch codex/test/csa-121-126-financial-security
and managed csa-121-126-financial-tests worktree. Base merged dev a19fd04891ec196c6b08a90bb65e28a12839020d (includes PR84).
Allowed scope new financial SQL regression file, this handoff, TASKS.md these six
IDs only. One test owner; production RPCs/migrations/package/runner unchanged.
Active issue85/PR86 entitlement and notification scope remains independent.

| Task | Evidence surface |
| --- | --- |
| CSA121 | New underpayment/zero/canonical-currency SQL; existing bank and online amount/currency mismatch and adapter exact-money tests |
| CSA122 | New recovered bank review replay/one-grant-one-outbox checks; existing online duplicate event/body-conflict tests and actual concurrent callback races |
| CSA123 | Existing real independent-session bank same-key/opposing decision/credit-reuse races run by db:test, observing actual blocked PostgreSQL backends |
| CSA124 | New pending/rejected no-grant/no-projection, authenticated private lesson/media path denial; existing restrictive private Storage transport tests |
| CSA125 | New expired/banned/nonfinance rejection/direct-browser-RPC checks; existing self-review/MFA/revoked-role and live Auth/MFA denial |
| CSA126 | New fault injection at bank review record/final approval audit/outbox; rollback settlement/attempt/order/submission/grant/projection/key, then successful same-key recovery/replay; existing online rollback/recovery |

Acceptance is fresh local tests plus full Supabase migration replay, regression
SQL, actual independent-session races, strict lint and live private Storage/Auth
checks on the final PR commit. No production calls or acceptance fabrication.
CSA124 proves current merged backend boundaries only; full protected lesson delivery
integration with proposed PR86 verifier remains a downstream release check.
Tasks remain IN_REVIEW until authorized review/merge. Approver project owner.
Local npm run tool:test:266 passed,3 database concurrency suites intentionally skipped in local mode. Full real database suite/concurrency runs in CI. Draft PR88; status IN_REVIEW.
New SQL regression file:26 assertions pass on fresh native PostgreSQL16 after ordered001–018 migrations using synthetic Auth/Storage schema shims. Initial CI exposed a fixture-only renamed RPC reference; corrected to unchanged csa108_prepare_receipt. Real Supabase CI remains required.

## Authorized PR88 review follow-up — 2026-10-12

Owner CODEX root, assigned by project owner to review, resolve findings and merge
PR88 into dev. Reuse clean isolated csa-121-126-financial-tests worktree and existing
branch; issue87 remains coordination source. Writable scope unchanged: regression
SQL, this record and TASKS.md CSA121–126. No production writes or migration changes.
Merged current dev1729117 before verification; no conflicts. Related PR86 dependency
is merged. Existing PR75/new status branch is separate; only these six status IDs
are temporarily owned here. Review found fault identity and per-fault rollback
coverage too weak: SQLSTATE alone can accept a different P0001 failure; final-only
checks do not independently assert audit/review/outbox cleanup after each fault.
Fix in scope: exact injected error message and full rollback assertion after each
fault, retaining existing successful same-key recovery/duplicate assertions.
Fresh baseline Node run:304 pass,0 fail,4 explicitly gated DB suites. Full hosted
Supabase and Flutter exact-head checks required before authorized merge. Production
activation and live provider/bank/email acceptance remain outside this review.

## Review verdict and acceptance evidence — 2026-10-12

Specification and engineering review: PASS after resolving the rollback-test
coverage finding. No remaining actionable finding in PR88's scoped test diff.
No production code, migrations, runner or dependencies changed. New helper checks
exact injected error message and financial/order/submission/grant/projection,
review evidence, both review-start/final audit, outbox and idempotency rollback
independently at all three fault boundaries. Same-key retry and one-effect replay
remain verified. Existing amount/currency, callback duplicate, current finance
permission, private Storage and real lock-contention suites cover CSA121–125.

Fresh verification at code commit82afb30d772b02d55ebaa958880b57b675dc272e:
- npm run tool:test:304 passed,0 failed,4 DB suites explicitly gated locally.
- Task-owned fresh PostgreSQL17 loopback55488, synthetic Auth/Storage bootstrap;
  ordered migrations001–020 replayed. New SQL29 assertions passed.
- Mutation replaced only injected fault message with unrelated P0001; test failed
  at the intended error-identity assertion. No source test was weakened afterward.
- Enabled four independent-session suites:22 tests passed,0 failed,0 skipped.
- Existing online, bank and entitlement SQL suites plus new recovery suite passed.
  Initial broad bank test failed because synthetic Storage shim omitted authenticated
  SELECT privilege; corrected only the disposable fixture grant, then reran green.
  Synthetic bootstrap is not equivalent to actual Supabase; hosted checks below
  independently verify the pinned full stack. Local instance stopped.
- [Exact-code Supabase](https://github.com/iamramishka/acendra/actions/runs/38199230937):
  SUCCESS, including SQL migration replay/tests/races, strict lint, actual private
  Storage transport/API/Auth/MFA checks and cleanup.22 real-session tests passed.
- [Exact-code Flutter](https://github.com/iamramishka/acendra/actions/runs/38199230942):
  SUCCESS, formatting, analysis, tests and release web build.
- git diff --check passed. Review includes the full current-dev integrated diff.

Project owner explicitly requested review, resolution and merge of PR88. With
findings resolved and required evidence green, CSA121–126 are accepted for their
bounded test scopes. Registry records DONE; final documentation check/approved
merge follows. Development integration does not enable production operations.
Protected delivery integration, PayHere sandbox, banking operations and live email
acceptance remain separate release dependencies. No independent human review
is claimed for this AI review; the owner's explicit merge authorization controls.
