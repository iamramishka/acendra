# PR132 receipt-status remediation

Owner: CODEX, reassigned by the project owner's explicit fix-and-merge request.
Coordination: https://github.com/iamramishka/acendra/issues/137
PR: https://github.com/iamramishka/acendra/pull/132
Branch: codex/fix/csa-110-pr132; PR branch feat/csa-110-receipt-submission-status.
Worktree: C:/Users/ramis/Downloads/Acendra/review-pr132.
Base: dev ca3158b (includes PR134).
Status: IN_REVIEW pending full checks and merge.

Scope: receipt-status card and tests, existing bank-transfer status screen, and this evidence record. No shared router/provider/financial state changes. Original CLAUDE commits preserved. Open PRs and worktrees inspected before editing; PR134's router and learning scope was kept separate.

The duplicate checkout screen that fabricated a pending receipt and timestamp was removed, along with its duplicate entity. The card now accepts the canonical bank-transfer entity and supports submitted/under-review states. The existing provider-driven, authenticated route renders it and supplies navigation to My Courses and receipt resubmission. Existing awaiting-receipt UI remains. Optional submission timestamps are shown only when supplied and converted to local time. Existing backend status provider remains a stub; this change does not activate receipt upload, payment approval, entitlement grants, or real backend status loading.

Verification: 35 targeted widget/integration tests passed, including four provider-data/navigation regressions. All three reviewed formatting failures corrected. Full formatting, analysis, complete Flutter tests, release build and hosted CI required before merge. Synthetic test data only. No production changes.

Approval authority: project owner, explicit merge authorization in this chat after fixing findings and passing checks.
