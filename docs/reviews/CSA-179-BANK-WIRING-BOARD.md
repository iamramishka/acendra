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
