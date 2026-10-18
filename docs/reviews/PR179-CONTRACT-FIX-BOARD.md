# PR #179 contract review corrections

Status: IN_REVIEW. Date: 2026-10-18. Owner: CODEX.

Authorization: the project owner explicitly requested corrections to the parallel
PR review findings. This is bounded documentation correction on existing
PR #179, not a GitHub Issue claim. No corresponding implementation Issue is
claimed or created by this record.

- Branch: `docs/csa-paylist-pr179-review-fixes`.
- Worktree: `C:/Users/ramis/Downloads/Acendra/review-pr179-20261018`.
- Reviewed base/head: `088f0e4e92402e5c55251a5c3c41766b011aee25`.
- Allowed scope: this board and
  `docs/contracts/CSA-PAYMENT-LIST-PROPOSAL.md` only. Temporary ownership covers
  corrections to the proposed status mapping and pagination/count semantics.
- Dependencies: current checkout, bank-review, online-payment and reporting
  migrations are read-only evidence. Active backend PR #181 is outside scope;
  this work does not implement, approve, activate or change that backend.
  PR #181 contains its own copy of the original proposal and subsequent decisions;
  its owner must reconcile these status/pagination corrections before integration
  or activation. This correction does not claim that contract is approved.
- Review/approval authority: project owner; root CODEX reviewer independently
  reviews the resulting correction before updating the original PR.
- Verification criteria: cover routine pending orders without payment child
  rows and the current bank-rejection transition; give live page/count facts one
  per-request timestamp while preserving the fixed cursor membership cutoff;
  align examples, field rules, concurrency cases and frontend adaptation notes;
  preserve PROPOSED status and pending owner decisions; validate the document
  against checked-in schema/workflows and run diff/whitespace checks.
- Release condition: independent review of the correction; proposal remains
  IN_REVIEW until accepted. No production release is authorized here.

## Evidence and handoff

- Corrected proposal mappings: checkout with no attempt/submission is `pending`;
  a bank rejection leaves `pending_payment` plus latest `rejected` submission and
  reports `rejected`; preparing/submitting new evidence reports
  `pending`/`processing`. Terminal order state and the latest supporting row take
  precedence over older rejection history. Schema/workflow cross-check: inspected
  CSA-092/094/096/101-105/108-113/117/158-172 migrations with `Get-Content` and
  `rg -n`, including checkout insertion, receipt preparation/finalization and the
  bank-rejection reset. Criterion met for the document; runtime not verified.
- Corrected pagination proposal: cursor `as_of` fixes the order-creation cutoff
  for both rows and counts; each request refreshes live statuses/counts together
  in one SQL statement snapshot at `count_as_of`. `current_snapshot` refers to
  that latter timestamp. Separate requests need not agree after writes, and
  status-filter membership requires refresh for newly matching rows above the
  cursor. Example, field rules, concurrency cases and frontend adaptation notes
  now use those semantics. Criterion met for document coherence.
- `git merge --no-edit origin/dev`: clean merge of
  `875c8bd1da53e879a59408d3da597262b32a64bf` into the review-fix branch; no manual
  conflict resolution. Integration merge commit: `9370be3764e8f862a4475209391f0ed61f8b7981`.
- PowerShell fenced JSON extraction with `ConvertFrom-Json -ErrorAction Stop`:
  all 3 JSON examples parsed successfully. Local Markdown link resolution with
  `Test-Path -LiteralPath`: all 4 local links exist.
- `git diff --check` and `git diff --check origin/dev`: passed with no output.
- Scope: only this board and the proposed contract receive correction edits.
  Proposal status, owner decision questions and activation gates are retained.
- Gap: documentation only; Flutter/Node/SQL runtime tests, hosted staging,
  production access, implementation acceptance and contract approval are outside
  this correction. No claim of backend verification or release readiness.
- Next action: independent root review, then update original PR #179 if accepted.
  PR #181 owner must reconcile its proposal copy/decisions before integration or
  activation. Shared correction ownership releases after independent review;
  the overall proposal remains IN_REVIEW pending owner acceptance.
