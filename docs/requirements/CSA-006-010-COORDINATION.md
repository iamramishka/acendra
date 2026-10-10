# CSA-006 / CSA-007 / CSA-008 / CSA-010 coordination

Date: 2026-10-11 (Asia/Colombo)
Status: IN_REVIEW - four coordinated decision candidates prepared
Accountable owner: CODEX; policy approver: project owner
Branch: docs/csa-006-010-policy-review
Workspace: C:/Users/ramis/.codex/worktrees/csa-006-010-policies/acendra
Base: origin/dev at b9bc60b

## Assignment and isolation

The user requested all four tasks in parallel. Three read-only sub-agents review
enrollment/refund, architecture and database design. CODEX reviews PDF delivery
and integrates all shared-document changes serially in this isolated worktree.
This is a coordinated documentation batch; no runtime or migration implementation.

The existing csa-008-db-design worktree has uncommitted DATABASE_DESIGN.md changes.
They are inspected read-only and preserved. This task does not claim or alter
that worktree. The new database candidate is prepared against the published base
with findings and provenance recorded. No open PR was found at assignment.

Writable scope: SRS.md, TASKS.md, ARCHITECTURE.md, DATABASE_DESIGN.md and
docs/requirements/CSA-006*.md, CSA-007*.md, CSA-008*.md, CSA-010*.md.
Temporary shared ownership belongs to CODEX in this branch for this batch only;
release at handoff. Source code, dependencies, migrations, applied schemas,
existing ADR drafts and other worktrees are restricted.

| Task | Priority | Owner | Dependencies / gate | Acceptance evidence / required checks |
| --- | --- | --- | --- | --- |
| CSA-006 | P0 | CODEX; owner decides | Approved CSA-003..005; refund terms and reversal policy | Concrete duration/refund/revocation rules; state/concurrency scenarios and preserved requirement IDs |
| CSA-007 | P1 | CODEX; owner approves | SRS baseline; CSA-006/008/010 contracts | Consistent trust/layer boundaries; open decisions and ADR numbering mapped; documentation checks |
| CSA-008 | P0 | CODEX review candidate; existing draft owner retained | CSA-006 financial/access policy; CSA-003 roles | Entity/relationship invariants, exact money, RLS/grants, constraints and migration test plan; no executed SQL claims |
| CSA-010 | P0 | CODEX; owner approves | CSA-006 access/revocation; private storage and PDF requirements | Concrete delivery/watermark design, revocation limitations, reader/accessibility/performance gates and primary-source research |

Related PR: [draft PR #4](https://github.com/iamramishka/acendra/pull/4).
Related requirements and proposed tests are in the task
deliverables. Approval for new policy choices is not inferred from the request
to prepare these tasks. Lifetime access and refund requests within seven days
were explicitly selected by the owner during this batch; other choices will be
presented concretely for acceptance. Pending operational values remain gates.

## Review result and acceptance choices

- [CSA-006](CSA-006-ENROLLMENT-REFUNDS.md): confirmed lifetime/seven-day choices;
  proposed precise 168-hour fulfillment-time cutoff, independently reviewed full
  refund execution, source-specific revocation and trusted dispute restrictions.
- [CSA-007](CSA-007-ARCHITECTURE.md): architecture candidate corrects previously
  approved permission/provider/MFA inconsistencies and reconciles ADR numbering.
- [CSA-008](CSA-008-DATABASE.md): canonical entity addendum supplies versioned
  destinations, settlement/reversal/refund ledgers, grant lifecycle/restrictions
  and private derivative relationships. Existing other-worktree draft untouched.
- [CSA-010](CSA-010-PDF-DELIVERY.md): propose authenticated proxy delivery of
  personalized server-watermarked PDFs, with current authorization per request,
  no raw storage URL, bounded transformation and reader/accessibility gates.

Owner acceptance is requested for the remaining CSA-006 policy details, the
architecture/database candidates and the PDF strategy together. That acceptance
does not supply unspecified refund eligibility terms, operational contacts,
retention, runtime/hosting, workload limits or production validation evidence.

## Verification and handoff

All four are documentation candidates, not DONE. Relevant business decisions
remain explicitly pending rather than invented. Required documentation checks:
all 237 requirement IDs/priorities preserved, local links across nine documents
passed, and Git whitespace checks passed. Cross-task review identified and
corrected PDF denial wording to preserve independent valid grants. Runtime tests
are not applicable to Markdown-only
edits; listed financial/security/reader tests are future acceptance requirements.
No migration, payment, database reset, package install or production action run.
Next action: owner accepts or requests changes to the concrete candidates, then
separately scoped implementation aligns API/security/schema contracts and proves
the required negative/concurrency/reader behavior. Shared edit ownership releases
at this handoff.
