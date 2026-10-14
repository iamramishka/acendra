# Checkout flow continuation

2026-10-14. CODEX backend_acceptance delegate, issue129 owner continuation.
User explicitly selected implementation with operational gates retained; no local
tests. Base fe68c6b. Branch feat/csa-178-179-checkout-flows; isolated worktree
C:/Users/ramis/.codex/worktrees/phase8-checkout-flows/acendra.
Scope: lib/features/checkout/**, checkout tests and this task-specific report.
Root owns shared routing/integration. No bank_transfer/backend/dependency edits.
Outcome: invoke documented online initialization and raw receipt contracts,
preserve replay keys, display gated errors safely, never infer paid access from
redirects or route extras. Dependencies: existing gated handlers; actual provider,
inspection and independent bank evidence remain owner operational gates.
Hosted formatting/analyzer/tests/build required; no local test execution.
Status IN_REVIEW. Project owner retains merge/operational acceptance authority.

Implemented: checkout Pay Now invokes initialize-checkout with contact contract
and retry-stable key, validates pending order/attempt/amount and provider origin,
and submits a safe DOM POST handoff on web. Checkout initial bank receipt and the
existing canonical resubmission form invoke raw Uint8List upload-bank-receipt with
private handler headers. Gated/SDK errors are sanitized; retries retain the key;
only a matching submitted acknowledgement displays pending verification.
Return/success route extras no longer claim paid/enrolled or offer immediate
Start Learning. Pending route extras cannot supply transfer-account instructions
or an invented verification deadline. No order/enrollment/Storage writes added.

Auth/inspection/provider release dependencies remain gated. No backend entry
point enabled and no sandbox/bank/inspector evidence invented. Unit and widget
regressions prepared for hosted CI: dangerous handoff URLs, order/attempt/amount
mismatches, raw upload contract, SDK 503 sanitization, receipt replay after network
uncertainty, and route-extra truthfulness. No local tests/analyzer/build ran.
Dart formatting ran successfully (missing flutter_lints package resolution warning
in fresh worktree); git diff --check passed. Root must run exact-head hosted
Flutter formatting/analyzer/tests/build and applicable backend checks before merge.
