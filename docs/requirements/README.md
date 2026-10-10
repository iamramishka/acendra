# CSA-001 through CSA-005 requirements review

Date: 2026-10-11 (Asia/Colombo)
Status: IN_REVIEW - review packet prepared; final policy/baseline approval pending
Accountable owner: CODEX
Branch: docs/csa-001-005-finalization
Workspace: C:/Users/ramis/.codex/worktrees/csa-001-005-finalization/acendra
Base: dev at 63b4131

## Coordination

The project owner requested all five tasks together with sub-agents. Three
read-only reviewers cover SRS/MVP, roles, and bank policy; CODEX handles gateway
research and serial integration. Reviewers do not modify a shared workspace.
This is one coordinated documentation review batch, not five independent
implementation branches. Runtime implementation is outside this assignment.

GitHub issue inspection returned no issues. TASKS.md lists these tasks as lead
decisions with no confirmed implementation owner. Existing worktrees bearing
similar task names were inspected read-only and left untouched; they are not
treated as abandoned or reassigned. No ownership claim is made over them.

Temporary shared-file ownership for this branch: TASKS.md and SRS.md, solely for
the requested review and its traceability. Scope: those files and
docs/requirements/*.md. All source, tests, migrations, dependency manifests,
other policy documents, and other agents' worktrees are restricted.
Release condition: documentation handoff; later policy integration requires review.

## Task records

| Task | Priority | Owner | Dependencies for final approval | Deliverable | Acceptance / required verification |
| --- | --- | --- | --- | --- | --- |
| CSA-001 | P1 | CODEX; owner signs off | CSA-002 through CSA-005 and remaining SRS open decisions | SRS review and revision | Existing requirement IDs preserved; contradictions resolved or explicitly gated; requirement references checked |
| CSA-002 | P1 | CODEX; owner signs off | CSA-001 baseline; CSA-003 through CSA-006; media and release decisions | MVP acceptance matrix | Every MUST retained; optional scope explicit; measurable scenarios and evidence gates |
| CSA-003 | P1 | CODEX; owner signs off | Existing roles and security baseline; owner separation decision | Permission matrix | Every role covered; deny cases and backend enforcement defined |
| CSA-004 | P0 | CODEX; owner selection recorded | Merchant eligibility, volume and CSA-006 affect implementation readiness | PayHere/LKR decision record | Owner selection and primary sources recorded; sandbox acceptance defined |
| CSA-005 | P0 | CODEX; owner signs off | CSA-003, CSA-004, CSA-006 and retention decision | Bank verification policy | Independent credit evidence; transactional approval; concurrency and privacy cases defined |

All five task records share the branch, workspace, scope and ownership above.
Related requirements and completion evidence appear in each deliverable.
Related pull request: [draft PR #3](https://github.com/iamramishka/acendra/pull/3),
targeting dev. Application tests are not claimed by
this documentation review; listed test scenarios are requirements for future work.

Dependencies do not prevent parallel review and preparation. They do prevent
calling the policies approved or beginning dependent financial implementation.

## Deliverables and decision status

| Task | Review result | Evidence |
| --- | --- | --- |
| CSA-001 | SRS 1.1 review candidate; security clarifications and confirmed payment selection applied | [SRS/MVP review](CSA-001-002-SRS-MVP.md), [SRS](../../SRS.md) |
| CSA-002 | Complete MVP scope/acceptance proposal; all existing MUST requirements retained | [Acceptance matrix](CSA-001-002-SRS-MVP.md) |
| CSA-003 | Concrete role matrix, separation rules and negative tests proposed | [Roles](CSA-003-ROLES.md) |
| CSA-004 | Owner confirmed Sri Lanka, LKR and PayHere; merchant readiness unverified | [Payment decision](CSA-004-PAYMENT-DECISION.md) |
| CSA-005 | Concrete bank verification, concurrency, rejection and dispute policy proposed | [Bank policy](CSA-005-BANK-POLICY.md) |

All task statuses are IN_REVIEW, not DONE. The payment selection is confirmed;
the other policy choices have not been approved merely by requesting this work.

## Approval requested

The owner can approve these prepared choices together or name specific changes:

1. MVP baseline: retain all MUST requirements; defer SHOULD features; one course
   per order; curriculum metadata preview; last-lesson/PDF resume; video timestamp
   resume deferred; unpublishing preserves existing entitlements.
2. Roles: assigned-course authoring, super-admin publication/pricing and manual
   grants, one independent finance reviewer, no self-approval/self-role changes,
   MFA for finance/super admin, independent review of beneficiary changes.
3. Bank policy: 5 MiB JPEG/PNG/PDF, private validated uploads, independent exact
   LKR bank-credit matching, no settlement reuse, new same-order submissions after
   rejection, preserved history and a different reviewer for disputes.

Remaining operational facts are explicit downstream gates: official bank account,
named reviewers and alternate, review/dispute response targets, receipt inspection
implementation and retention, PayHere activation/pricing plan, full customer
territories, and CSA-006 refund/entitlement rules. No secrets are needed in chat.
Other SRS decisions are listed in the SRS/MVP crosswalk.

## Handoff

Completed work: three independent read-only reviews, provider documentation
research, consolidated policies and acceptance scenarios, SRS candidate updates.
Files changed: SRS.md, TASKS.md and this directory's five Markdown files.
Shared contracts: no API/schema changes; approved proposals will require later
alignment with API_CONTRACTS.MD and related policies under coordinated ownership.
Verification: independent read-only packet review completed; all 237 requirement
IDs/priorities preserved; local links across seven documents passed; Git
whitespace checks passed. These checks verify documentation, not application behavior.
GitHub reported no CI checks on the draft PR at handoff; no CI pass is claimed.
Application tests: not run because this batch changes only Markdown; all payment,
authorization, storage and acceptance scenarios remain unexecuted requirements.
Known risks: unresolved business/operational gates; provider readiness unverified.
Next action: owner reviews the three prepared choices and supplies operational
facts before dependent implementation. No merge or production action authorized
by this packet. Shared-file editing ownership is released at documentation handoff.
