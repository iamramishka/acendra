# CSA-184–188 review and operational deferral

Date: 2026-10-14 (Asia/Colombo). Owner: CODEX root.
Review status: ACCEPTED AND MERGED INTO DEV.
Operational acceptance: DEFERRED until real-environment setup.
Registry status: IN_REVIEW applies to outstanding operational acceptance only.
User requested review/merge, then explicitly instructed use of dummy details,
skipping checks requiring real environments and merging into dev for later setup.
This accepts the bounded review records; it does not waive production controls.

## Current owner decision

On 2026-10-14 the owner confirmed that no further local testing is required
for the current review/documentation stage and requested this document update.
The CSA-184–188 review and dev integration are accepted and complete for this
stage. Existing test evidence is retained as historical verification; no new
local runtime tests are required or claimed by this update. Real-environment
finance, private-file, upload inspection, hosted headers and managed logging
acceptance remain deferred for later setup. IN_REVIEW does not mean a pending
dev merge. It records those outstanding operational checks.

Coordination: CODEX owns this new owner-decision section and status wording
only on `docs/csa-184-owner-review-acceptance`, based on `4ab617b`, in
`C:/Users/ramis/Downloads/Acendra/csa184-owner-acceptance`.
Related issue: #129. PR #150 contains a redundant historical merge record;
its branch and proposed record are preserved untouched. This follow-up adds
the current owner decision without discarding that proposal or changing runtime
controls. Scope: this document only. Authority: current project-owner request.
Verification: document/diff review and whitespace check; merge through CI.
Temporary ownership ends on merge.

## Coordination and scope

Base: origin/dev d415157. Branch: docs/csa-184-operational-deferral.
Worktree: C:/Users/ramis/.codex/worktrees/csa-184-188-deferral/acendra.
Related coordination: issue #129, with existing independent operational acceptance
requirements retained. No open PR was found at preparation. Existing worktrees
were retained; no other agent's working files were edited.
Exclusive scope: this record and the five CSA-184–188 notes in TASKS.md.
Temporary shared ownership covers those notes only through merge. No runtime,
migration, workflow or credential changes. Authority: project owner for this merge
and later concrete release acceptance. Verify source/evidence references, exact
CI metadata, unchanged unchecked task status, and git diff --check.

## Reviewed merged evidence

[PR #146](https://github.com/iamramishka/acendra/pull/146) is already merged at
`d415157a85f0111edb667289483a794adab526c4`.
Its final tested head `0cdbd6691009e05da6fd3734710cb5f40b5e87fe` has successful
[Flutter CI](https://github.com/iamramishka/acendra/actions/runs/38529359834)
and [Supabase CI](https://github.com/iamramishka/acendra/actions/runs/38529359723).
The merged dev commit also has successful
[Flutter CI](https://github.com/iamramishka/acendra/actions/runs/38540544597).
These results attest to their tested revisions, not a configured production build.

Fresh review in the isolated csa-184-188-review worktree at the merged revision
reran the 14 existing Node test files for finance/role/entitlement boundaries,
receipt/admin media upload, PDF/video authorization, header evaluation, local
environment safeguards and private media smoke safeguards: **249 passed,
0 failed, 0 skipped**. No blocking finding was identified in this bounded scope.
These component/safeguard reruns do not replace effective deployed API/browser
or managed-service acceptance. Existing CI provides disposable SQL/Storage and
Chrome malicious-text evidence; no new deployed checks were run.

Review confirmed current finance RPCs require a current finance/super-admin
assignment and AAL2 session. Private media smoke checks preserve synthetic bytes
after denied access and reject server failures as denial evidence. Receipt/admin
ingestion entry points still omit approved inspection dependencies and remain
unavailable. Current AppLogger output is debug-only with no active call sites;
arbitrary debug values and third-party/managed logs still require privacy review.

## Deferred checks and dummy worksheet

| Task | Retained operational acceptance |
| --- | --- |
| CSA-184 | Real finance/non-finance and AAL1/AAL2 workflows, independent bank credit verification and trusted operational actions |
| CSA-185 | Authorized private-file delivery, cross-user/entitlement-revocation denial and no private-reference disclosure through actual UI/API journeys |
| CSA-186 | Approved actual inspection/scanning and resource limits; safe/malicious/mismatched/oversize ingestion, quarantine and failure evidence |
| CSA-187 | Effective deployed HTTPS headers, CSP compatibility and authenticated stored-payload journeys |
| CSA-188 | Scan of the approved configured release artifact; managed log redaction, denied unauthorized readers and enforced retention |

Staging URL: `https://staging.courses.example.invalid`.
Supabase project: `DUMMY_STAGING_PROJECT_REF`.
Logging provider: `UNSELECTED`; stream: `DUMMY_MANAGED_LOG_STREAM`.
Upload inspection service/policy: `UNSELECTED`; identifier: `DUMMY_INSPECTION_POLICY`.
Credentials: replace through an approved secret store, never in this record.
These are unusable documentation placeholders, not deployed controls, selected
services, approved inspection policies or secret bindings. No requests, build,
deployment, upload enablement or log probes may use them.

Later operator: replace placeholders with approved real staging/account access,
complete coordinated operational implementation and inspection selection, scan
the actual configured release, verify deployed headers and managed log controls,
then submit sanitized scenario results for owner acceptance. Keep deployed
financial/upload gates closed until prerequisites are satisfied. All five tasks
remain unchecked IN_REVIEW; merge of this record does not establish DONE.

Preparation verification: source/reference review and git diff --check passed.
No security requirement was removed.

## Verified merge and documentation synchronization

[PR #148](https://github.com/iamramishka/acendra/pull/148) merged into `dev`
on 2026-10-14 at 15:06:36 Asia/Colombo, commit
`bd5a5c91dd4708a76d3443eabffa10c36bf965ad`.
[Flutter baseline CI](https://github.com/iamramishka/acendra/actions/runs/38542456018)
completed SUCCESS before merge: formatting, analysis, Flutter tests, release web
build and tooling regression checks passed. This is documentation integration
evidence, not real-environment operational acceptance.

The owner subsequently requested document updates. CODEX root owns this merge
record and the corresponding CSA-184–188 TASKS.md summary only. No open PR or
overlapping documentation assignment was found at synchronization. Branch:
`docs/csa-184-merge-record-update`; isolated worktree:
`C:/Users/ramis/.codex/worktrees/csa-184-188-doc-sync/acendra`.
Base: `bd5a5c9`. Verification: GitHub merge/check readback, scoped diff review and
`git diff --check`. No runtime change or new operational test is required for
this synchronization. Documentation status: merged and accepted; operational
task status: IN_REVIEW, unchanged. Temporary note ownership ends at review/merge.

## Final dev merge readback

Owner request, 2026-10-14: update the documents and deliver merged `dev`.
CODEX owns this bounded follow-up and the corresponding TASKS.md summary;
no open PR overlap was found. Related issue: #129. Branch:
`docs/csa-184-final-merge-record`; isolated worktree:
`C:/Users/ramis/Downloads/Acendra/csa184-final-docs`. Base: `6beaa8c`.
Authority: project owner. Verification: exact GitHub merge/CI readback,
document reference review and `git diff --check`; ownership ends on merge.

[PR #149](https://github.com/iamramishka/acendra/pull/149) merged into `dev`
on 2026-10-14 at 17:16:36 Asia/Colombo, commit
`6beaa8c8a7b5190163210b9044abf94d4d1ec42a`.
[Exact-head Flutter baseline CI](https://github.com/iamramishka/acendra/actions/runs/38544728331)
passed at `78d56157e330b643d30e48edea9b1ccd25d20d1a`.
Independent focused rerun at that head: 249 Node tests passed, exit 0,
covering finance/role/entitlement, receipt/admin media, PDF/video, headers,
local environment and private media smoke safeguards. No blocking finding
was identified in this bounded review. Local `dev` was fast-forwarded to
the verified merge commit. All five tasks remain IN_REVIEW with real-environment
acceptance deferred; no production activation or DONE claim is made.

## PR #150 integration review

Owner requested review and merge of PR #150 on 2026-10-14. CODEX owns this
bounded documentation reconciliation in `docs/csa-184-pr150-integration`,
worktree `C:/Users/ramis/Downloads/Acendra/pr150-integration`, based on PR head
`26cc67e` and current dev `f09d0fa`. Only PR #150 was open at review.
The PR #149 merge evidence is retained in the existing final readback above;
conflicting duplicate wording is consolidated without changing the current
owner decision or deferred operational acceptance. Verification: GitHub
merge/CI metadata, scoped diff review, whitespace check and updated-head CI.
Temporary ownership ends on merge.

CSA-201's separately reviewed changes are already merged through PR #123 and
PR #146; its operational recovery acceptance also remains IN_REVIEW.
