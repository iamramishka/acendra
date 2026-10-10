# CSA-001 through CSA-005: Approved requirements baseline

Date: 2026-10-11 (Asia/Colombo)
Status: DONE - documentation and decision tasks formally accepted
Accountable owner: CODEX
Approver: project owner, in this chat
Branch: docs/csa-001-005-finalization
Workspace: C:/Users/ramis/.codex/worktrees/csa-001-005-finalization/acendra
Base: dev at 63b4131
Related pull request: [PR #3](https://github.com/iamramishka/acendra/pull/3)

## Approval evidence

The owner first selected "Sri Lanka, LKR , Payhere payment gateway", then
responded to the prepared MVP/roles/bank-policy approval request with
"i give approve. do that these" on 2026-10-11. This records formal acceptance
of the versioned requirements baseline and the three prepared policy choices.
Runtime implementation, operational readiness, production release and Git merge
are separate from this approval.

## Accepted deliverables

| Task | Priority | Owner | Status | Completion evidence |
| --- | --- | --- | --- | --- |
| CSA-001 | P1 | CODEX; owner accepted | DONE | [SRS 1.1](../../SRS.md) applies accepted resolutions and explicitly gates remaining decisions |
| CSA-002 | P1 | CODEX; owner accepted | DONE | [MVP scope and acceptance matrix](CSA-001-002-SRS-MVP.md); all existing MUST requirements retained |
| CSA-003 | P1 | CODEX; owner accepted | DONE | [Approved role matrix](CSA-003-ROLES.md), enforcement rules and negative-test requirements |
| CSA-004 | P0 | CODEX; owner accepted | DONE | [PayHere/LKR decision](CSA-004-PAYMENT-DECISION.md), official provider evidence and future sandbox gates |
| CSA-005 | P0 | CODEX; owner accepted | DONE | [Approved bank policy](CSA-005-BANK-POLICY.md), transitions, matching, concurrency, resubmission and disputes |

DONE means these requirements/decision deliverables were formally accepted;
it does not mean the product acceptance scenarios have passed. Related SRS IDs,
acceptance criteria and required future tests are in each linked deliverable.

## Approved choices

1. MVP: retain MUST requirements and defer SHOULD features; one course per
   order; curriculum metadata preview; last-lesson/PDF resume; video timestamp
   resume deferred; unpublishing preserves existing entitlements.
2. Roles: assigned-course authoring, super-admin publication/pricing and manual
   grants, one independent finance reviewer, no self-approval/self-role changes,
   MFA for finance/super admin, independent review of beneficiary changes.
3. Bank: 5 MiB JPEG/PNG/PDF, private validated uploads, independent exact LKR
   credit matching, no settlement reuse, new same-order submissions after
   rejection, preserved history and a different reviewer for disputes.

## Remaining implementation and release gates

The owner approved the specified policies, not unspecified operational values.
Required inputs remain: official bank destination, named reviewers and alternate,
review/dispute targets and contacts, receipt inspection technology/resource limits
and retention, exceptional matching policy if needed, PayHere activation/pricing
plan, full customer territories and CSA-006 refund/entitlement rules.
Separate PDF/media, browser/language, load/budget/recovery decisions remain
listed in the [decision crosswalk](CSA-001-002-SRS-MVP.md).
Financial implementation must resolve its relevant dependencies first.

## Coordination and handoff

The user requested parallel sub-agents. Three independent read-only reviewers
covered SRS/MVP, roles and bank policy; CODEX researched the gateway and integrated
documents serially in this isolated worktree. Existing similarly named worktrees
were inspected read-only and left untouched; no ownership over them was assumed.
The initial GitHub issue inspection returned no issues.

This is one coordinated documentation batch. The accepted follow-up authorizes
temporary editing of SRS.md, TASKS.md and docs/requirements/*.md on this branch.
Source, migrations, dependency manifests and other agents' worktrees are outside
scope. Shared-file editing ownership is released at this handoff.

Files changed: SRS.md, TASKS.md and five Markdown files in this directory.
Shared contracts: no API/schema implementation changes. Downstream work must
align API_CONTRACTS.MD and related policy text with this latest owner-approved
baseline under coordinated ownership before implementing affected operations.

Documentation checks passed after approval integration: all 237 requirement
IDs/priorities preserved, local links across seven documents resolved and Git
whitespace checks passed. The diff was inspected. Independent review of the
original packet was completed before owner acceptance.

Application tests: not run for Markdown-only changes. Payment, authorization,
storage and acceptance scenarios remain unexecuted implementation requirements.
GitHub reported no configured checks on PR #3 at the prior handoff; no CI pass
is claimed. Next action: implement approved requirements in separately scoped
tasks, resolving the listed operational dependencies. No production action or
merge is performed by this documentation approval.
