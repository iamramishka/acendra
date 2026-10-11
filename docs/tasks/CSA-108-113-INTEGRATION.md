# CSA-108/109/112/113 coordinated integration

Date:2026-10-11 (Asia/Colombo). Owner CODEX root. Issue #81. Status IN_PROGRESS.
Branch codex/feat/csa-108-113-integration, isolated worktree
C:/Users/ramis/.codex/worktrees/csa-108-113-integration/acendra.
Base PR #79 head34e6624; dependent PR remains unmerged. Integration is stacked on
that reviewed/tested foundation, not a claim it is already on dev.

| Task | Owner | Exclusive scope |
| --- | --- | --- |
| CSA108/109 | CODEX checkout_initialization | upload-bank-receipt/**, receipt docs/tests |
| CSA112/113 | CODEX verified_webhook | admin-review-bank-transfer/**, review docs/tests |
| Shared database | CODEX financial_finalization | New017+ migrations/RPCs/SQL tests, private reservation/review evidence/Storage bucket |
| Integration | CODEX root | Registry these4 IDs, package/config, shared integration docs and new race/tests runner |

Workers use independent managed worktrees; one owner serializes schema/payment
state changes. Exact RPC shapes agreed before implementation. Root accepts a
bounded raw authenticated server upload implementation extension to the existing
signed-upload proposal; legacy proposed routes remain untouched and unimplemented.
No student capability, object path, listing or overwrite is exposed. Actual
stored bytes must match inspected size/type/digest before private metadata is
finalized. Missing/failed/unapproved inspection fails closed; upload never grants.

Credit shape agreed: bank_credit_confirmed:true,destination_account_id,
bank_transaction_id,amount_minor,currency:LKR,settled_at,source (bank_portal,
bank_statement,authenticated_bank_feed),order_reference. Public reason and private
reviewer notes remain separate. This is a current authorized finance reviewer's
independent-confirmation assertion, not automated bank proof or student authority.
SQL rechecks current role/MFA/session, prevents self review, serializes settlement
identity/order/submission, and atomically commits decision/payment/grant/audit/outbox.
Rejection preserves evidence and permits a new still-payable-order submission.

Approved CSA003/005/006/008 business/security policies remain authoritative.
Required tests: critical RED/GREEN validation/ownership/state/current permission,
exact independently verified credit, replay/opposing/reuse/races and atomic failure
rollback. Full Supabase migrations/lint/API and CI plus financial review required.
Production gates: approved inspection technology/resources, official bank account,
named authorized/alternate reviewers and retention/dispute operations. New deployed
endpoints hard disabled without environment bypass while these gates remain open.
No production credentials/configuration, live bank/provider calls or deployment.
Approval authority project owner/designated maintainer. IN_REVIEW until accepted.

## Integration evidence and remaining gates

Status IN_REVIEW. Receipt implementation9dacefe, bank reviewbe477e9,
database d7afa87 integrated in this branch. Root follow-up018 denies all bank
receipt deletion until approved retention operations, closing delete/finalize
race without lock inversion. Historical upload replay omits current order_status.
Local Node suite264 passing before follow-up, upload suite36 passing afterward;
database owner reports52 real PostgreSQL assertions; root five concurrent scenarios
pass. Native PostgreSQL uses synthetic Auth/Storage schemas, not real Storage API.
Real pinned Storage upload/metadata lifecycle compatibility, full Supabase replay,
strict lint, hosted CI and financial review remain required. In particular the
strict storage.objects UPDATE guard must be tested against actual Storage upload.
No approved inspection implementation/resource limits or operational banking setup
exists; production handlers remain hard disabled. No merge/deployment performed.
Parallel workers encountered account usage limit before real Storage smoke finished.
