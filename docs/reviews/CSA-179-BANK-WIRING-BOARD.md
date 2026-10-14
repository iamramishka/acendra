# CSA-179/184 bank frontend wiring coordination

Owner CODEX/recovery_acceptance; parent authorized parallel implementation.
Date 2026-10-14. Base origin/dev fe68c6b. Status IN_PROGRESS.
Worktree C:/Users/ramis/.codex/worktrees/phase8-bank-finance-wiring/acendra.
Branch feat/csa-179-bank-request-wiring.
Scope lib/features/bank_transfer/**, lib/features/admin/** and associated tests.
Parent owns shared routing/registry/CI and checkout worker owns checkout forms.
No migrations, dependency changes, backend activation or local tests.
Approval authority project owner/security/finance. Existing upload endpoint is
hard-disabled and must continue reporting503; client does not grant access.
Read/status/queue endpoint is absent and authenticated table access is revoked.
The CSA112 verified_credit proposal remains IN_REVIEW and cannot be silently
approved by client wiring. Approval and rejection remain gated pending contract
reconciliation. Replace fabricated queue/status with honest unavailable state.
Verification: hosted repository transport/error mapping tests and widget states.

Scope extension: user approved trusted bank status/queue reads and reconciliation
of the existing structured verified-credit review contract. Own new
supabase/functions/bank-transfer-read/** and migration20261014000100 only.
Reads require authenticated owner, queue current finance role plus AAL2.
All deployed entrypoints retain hard disablement. No private storage paths exposed.

Security continuation: queue/status providers watch the current auth session and
reject stale async results after identity changes. Reload never renders retained
previous-account rows. Receipt cards have unique submission plus opaque session
keys, so entered evidence and confirmation cannot transfer to another receipt or
account on queue reorder. Decisions capture the requesting session and suppress
success/error state from late completions after account changes. Added hosted
regressions for late queue results, signout, reorder and late decision completion.

Hosted SQL failed at the authorized finance queue assertion (read test line24):
the PL/pgSQL order row variable o collided with the queue relation alias o.
Follow-up migration20261014000200 renames the local row variable to order_row,
retaining SQL ambiguity checking and the existing reviewed access predicates.
The earlier shared migration is preserved. The existing authorized-queue and
owner-status tests exercise both branches and are required to pass on hosted CI.
No failure was suppressed and no local SQL/test execution was performed.
