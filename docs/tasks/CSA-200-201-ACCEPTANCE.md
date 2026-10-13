# CSA-200/201 acceptance continuation

Owner: CODEX/recovery. User authorized parallel acceptance verification 2026-10-13.
Status: IN_REVIEW; available development checks complete, operational acceptance retained. Branch: codex/test/csa-200-201-acceptance.
Worktree: C:/Users/ramis/Downloads/Acendra/csa-200-201-acceptance.
Base: origin/dev 8365d84. Issues: #119 and #117; previous deliverables merged in #124 and #123.
Allowed scope: tool/csa200*, tool/csa201*, supabase/tests/database/csa201*, this document.
Dependencies: disposable PostgreSQL17; real managed recovery and provider evidence remain external gates.
Overlap check: existing completed task worktrees retained; no concurrent mutable recovery assignment reported by parent coordination. No shared files edited.
Approval authority: project owner/security/operations reviewers. The user authorized test completion and subsequently delegated baseline choices to root; production recovery remains separately authorized.
Verification criteria: current disposable recovery drill, existing safeguards, CSA201 actual merged Supabase CI result; explicitly retain remaining external acceptance requirements.
Runtime: new temporary cluster only, loopback port61310; no shared database or hosted credentials.

## Verified merge and CI reconciliation

Live GitHub readback on 2026-10-13 confirms PR123 merged at
`5875e7e35f0311411319289235d70bf42ea17ecf`, with both checks SUCCESS:
[Supabase foundations](https://github.com/iamramishka/acendra/actions/runs/38346951661)
and [Flutter baseline](https://github.com/iamramishka/acendra/actions/runs/38346951672).
The prior CSA201 record's pending full Supabase CI statement is stale. The successful
job replayed migrations and ran the actual disposable Supabase database suite,
including automatically discovered CSA201 SQL, followed by 26 real independent-session
tests, all passing with zero skips. CI also passed live API/MFA checks and database lint.
Successful SQL output is intentionally suppressed by the existing runner; CI success
does not establish real payment/email provider acceptance or a full browser journey.

PR124 merged at `cc252850e8b0fdadcb220b6ca8395bbf89e93514`.
[Supabase foundations](https://github.com/iamramishka/acendra/actions/runs/38347150086)
and [Flutter baseline](https://github.com/iamramishka/acendra/actions/runs/38347150087)
both passed. Its review expressly accepts the bounded recovery tooling, while
preserving managed service/object and operational recovery acceptance blockers.
Issues117/119 remain open; no issue closure or production acceptance is inferred.

## Continuation changes and checks

The recovery harness now executes CSA201 fault/retry SQL on its fresh source database
before retained backup fixtures populate the notification queue, and exposes its
assertion count alongside backup integrity evidence. It also accepts the separately
reserved 61310..61319 loopback range for this parallel task. Existing61000..61009
behavior remains supported; arbitrary ports remain rejected before process creation.

- Five existing recovery safeguards passed with bundled Python.
- Fresh native PostgreSQL17 run on61310 PASSED: 30 migrations; CSA20125 fault/retry
  assertions; 85 financial fixture assertions; all38 table fingerprints matched;
  normalized schema/grants/RLS matched; restored profile isolation passed;
  three synthetic objects restored and one receipt tombstone respected. Dump11.547s,
  restore7.921s on this host; neither timing establishes production RPO/RTO. The
  task-owned temporary cluster stopped and its scratch directory was removed.
- `node --test tool/csa201_notification_recovery.test.mjs`: 2 passed, 0 failed,
  0 skipped. Stable provider idempotency keys survive delivery/acknowledgement loss.
- `git diff --check` passed.

## Remaining acceptance boundaries

Project owner delegated operational baseline choices to the parent task. The parent
decision record selects RPO24h, RTO4h, 30-day backup/diagnostic retention and project
owner as recovery lead. These resolve the missing decision only. The small synthetic
drill cannot prove those operating targets.

Actual Supabase managed Auth/Storage restoration, real private object backup/restore,
production deletion-ledger replay, recoverable encryption/key/retention setup,
representative volume and payment-provider reconciliation still require an authorized
environment. No deployment URL or provider acceptance environment was supplied.
Neither local filesystem objects nor CI's ordinary Storage smoke checks prove a
managed Storage recovery. External email exactly-once delivery remains provider-bound.
