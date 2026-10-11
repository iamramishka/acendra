
# TASKS.md
# Acedra - Parallel Multi-Agent Development Tracker

Document ID: CSA-TASKS-001
Version: 2.0
Status: Proposed - Pending Approval
Project: Acedra Course Selling Application
Primary Platform: Flutter Web
Backend: Supabase + PostgreSQL
Architecture: Feature-First Clean Architecture

Development Model:
Parallel Multi-Agent Engineering

Agents:
- Claude Code
- OpenAI Codex

Coordination:
- GitHub Issues
- GitHub Pull Requests
- Git Worktrees
- Shared Project Documentation

Methodology:
- Specification-First Development
- Test-Driven Development
- Continuous Integration
- Code Review
- Security by Design

---

# 1. PURPOSE

TASKS.md defines the master implementation
backlog and parallel development strategy
for the Acedra Course Selling Application.

The application includes:

- Student authentication
- Course marketplace
- Online payments
- Bank transfer payments
- Admin receipt approvals
- Course enrollments
- Protected PDF lessons
- Video, image, and text lessons
- Student learning dashboard
- Learning progress
- Admin management system
- Light and dark themes
- Responsive Flutter Web interfaces
- Secure backend infrastructure

Development will involve Claude Code
and OpenAI Codex working concurrently
on approved independent tasks.

The objectives are:

1. Improve development productivity.
2. Avoid duplicate implementation.
3. Prevent conflicting file changes.
4. Maintain consistent architecture.
5. Preserve security boundaries.
6. Ensure reliable Git integration.
7. Maintain complete task traceability.
8. Verify all completed work.

Parallel execution must never compromise
security, correctness, or code quality.

---

# 2. RELATED DOCUMENTS

All agents must follow:

- PLAN.md
- AGENTS.md
- SRS.md
- ARCHITECTURE.md
- DATABASE_DESIGN.md
- DESIGN_SYSTEM.md
- SECURITY.md
- CONTRIBUTING.md
- TESTING.md
- docs/PARALLEL_WORKFLOW.md

Document responsibilities:

PLAN.md:
Development roadmap and phases.

TASKS.md:
Master tasks and parallel allocation.

AGENTS.md:
Mandatory AI engineering rules.

SRS.md:
System requirements.

ARCHITECTURE.md:
Architecture and module boundaries.

DATABASE_DESIGN.md:
Database contracts and RLS.

DESIGN_SYSTEM.md:
UI/UX specifications.

SECURITY.md:
Security policy.

CONTRIBUTING.md:
GitHub contribution workflow.

PARALLEL_WORKFLOW.md:
Detailed multi-agent coordination rules.

Documents still in draft form must not
be treated as formally approved.

---

# 3. MULTI-AGENT OPERATING MODEL

Two AI development agents are available:

CLAUDE:
Claude Code

CODEX:
OpenAI Codex

The project owner or designated
technical lead coordinates integration.

The agents may implement separate
tasks at the same time.

Conceptual workflow:

                  PROJECT OWNER
                        |
                  MASTER BACKLOG
                        |
                  TASK ALLOCATION
                        |
             +----------+----------+
             |                     |
         CLAUDE CODE             CODEX
             |                     |
       Assigned Task A       Assigned Task B
             |                     |
        Worktree A             Worktree B
             |                     |
         Branch A               Branch B
             |                     |
       Tests + Review       Tests + Review
             |                     |
           PR A                  PR B
             |                     |
             +----------+----------+
                        |
                  INTEGRATION
                        |
                 GitHub Actions
                        |
                 Code Review
                        |
                   MAIN BRANCH

Important:

Claude and Codex operate in separate
accounts and execution environments.

Neither agent should assume that it
can directly communicate with the other.

GitHub provides the shared coordination
and source-control environment.

This document defines the process.

It does not automatically launch,
schedule, or synchronize either agent.

---

# 4. AGENT ROLES

## 4.1 CLAUDE

Suggested initial focus:

- Flutter UI implementation
- Responsive layouts
- Design system
- Student screens
- Learning workspace
- PDF reader interface
- Widget tests
- UI/UX documentation

Claude may also implement backend tasks
when explicitly assigned.

## 4.2 CODEX

Suggested initial focus:

- Backend architecture
- Supabase integration
- PostgreSQL schema
- RLS policies
- Payment verification
- Bank receipt workflows
- Enrollment authorization
- Backend tests
- Infrastructure automation

Codex may also implement frontend tasks
when explicitly assigned.

## 4.3 PROJECT LEAD

Identifier:
LEAD

Responsibilities:

- Approve priorities
- Allocate tasks
- Resolve conflicts
- Approve architecture changes
- Coordinate shared files
- Review critical security decisions
- Manage integration
- Approve production releases

## 4.4 OWNERSHIP PRINCIPLE

ONE TASK = ONE ACCOUNTABLE OWNER.

A task may have multiple reviewers.

A task must not have multiple independent
implementation owners simultaneously.

Task ownership may change through
an explicitly recorded reassignment.

---

# 5. AGENT ASSIGNMENT NOTATION

Task registry symbols:

[C] = Suggested Claude task

[X] = Suggested Codex task

[L] = Project Lead / Decision Owner

[T] = Owner to be determined

Important:

These are PROPOSED assignments.

They do not mean an agent has already
claimed or started the task.

Actual ownership must be confirmed
in the corresponding GitHub Issue.

The task owner is authoritative only
after the task has been assigned
through the agreed coordination process.

---

# 6. TASK PRIORITIES

P0 - CRITICAL

Examples:

- Payment verification
- Enrollment authorization
- Admin permissions
- Private receipt protection
- RLS security
- Critical data integrity

P1 - HIGH

Examples:

- Authentication
- Course marketplace
- Checkout UI
- Learning workspace
- Admin dashboard
- PDF reader

P2 - MEDIUM

Examples:

- Enhanced bookmarks
- Advanced analytics
- Extra UI refinements
- Course recommendations

P3 - LOW / FUTURE

Examples:

- Native mobile applications
- Affiliates
- Advanced subscriptions
- Multi-instructor marketplace

Priority is separate from implementation
complexity and execution order.

Dependencies take precedence
over apparent task simplicity.

---

# 7. TASK STATUS MODEL

Allowed task statuses:

BACKLOG
READY
CLAIMED
IN_PROGRESS
BLOCKED
IN_REVIEW
DONE
CANCELLED

## BACKLOG

Task exists but cannot yet begin.

## READY

Requirements and dependencies are ready.

## CLAIMED

An agent has accepted task ownership.

## IN_PROGRESS

The owner is implementing the task.

## BLOCKED

A dependency or unresolved issue
prevents safe progress.

## IN_REVIEW

Implementation is submitted for review.

## DONE

Acceptance criteria are verified,
required checks pass, and changes
are merged or formally accepted.

## CANCELLED

Task was removed through
an approved scope change.

Checkboxes:

[ ] Not verified complete.

[x] Verified DONE.

Never mark a task complete solely
because an AI generated code.

---

# 8. TASK METADATA CONTRACT

Every active task record in GitHub or this backlog must include:

Task ID:
Task Title:
Priority:
Phase:
Proposed Agent:
Confirmed Owner:
Status:
Dependencies:
Allowed Files:
Restricted Shared Files:
Branch:
Worktree or Clone:
Related Requirements:
Acceptance Criteria:
Required Tests:
Related Pull Request:
Completion Evidence:
Work Completed:
Current Blockers:
Next Action:
Next Owner:
Last Updated:

Keep the completion checkbox separate from task status. Update the work
summary, evidence, blockers, and next action when the status changes or
the task is handed off. Record only work that was actually performed and
verification that was actually run. Use `None` or `Not started` when a
field has no current value; do not leave the next owner implicit.

Example:

Task ID:
CSA-083

Title:
Responsive Course Grid

Priority:
P1

Phase:
4

Proposed Agent:
CLAUDE

Confirmed Owner:
UNASSIGNED

Status:
BACKLOG

Dependencies:
CSA-039
CSA-047
CSA-077
CSA-079

Allowed Files:
lib/features/marketplace/**

Restricted Shared Files:
lib/app/router/**
lib/app/theme/**
pubspec.yaml
pubspec.lock

Proposed Branch:
feat/csa-083-course-grid

Worktree:
Created after task claim.

Acceptance:
- Responsive course cards
- Light/dark support
- Loading and empty states
- Accessibility
- Widget tests

Related Pull Request:
Not created.

Completion Evidence:
Not run.

Work Completed:
Not started.

Current Blockers:
Dependencies pending confirmation.

Next Action:
Confirm the task owner and dependency readiness.

Next Owner:
Project Lead.

Last Updated:
<YYYY-MM-DD>

Actual ownership, PR links,
and test evidence are recorded
only after those events occur.

---

# 9. TASK CLAIMING PROTOCOL

Before starting:

1. Read AGENTS.md.
2. Read the relevant task.
3. Review linked SRS requirements.
4. Review the architecture.
5. Confirm dependencies.
6. Check current ownership.
7. Check conflicting active tasks.
8. Confirm writable file scope.
9. Obtain assignment approval.
10. Record ownership in GitHub.
11. Create an isolated worktree.
12. Begin implementation.

An agent must not self-assign work
that is reserved for another owner.

GitHub Issue assignment should be
performed by the project lead or
another authorized coordinator.

Do not assume an Issue comment
provides atomic locking.

If simultaneous claims occur,
the coordinator must resolve ownership
before either task proceeds.

---

# 10. WORKTREE AND BRANCH RULES

Each active implementation task
requires an isolated workspace.

Preferred:
Git worktree.

Alternative:
Separate clone.

## Branch Format

<type>/csa-<id>-<description>

Examples:

feat/csa-083-course-grid

feat/csa-143-pdf-reader

security/csa-102-payment-webhook

fix/csa-076-session-handling

## Example - Claude

```bash
git fetch origin

git worktree add \
  ../acedra-claude-csa-083 \
  -b feat/csa-083-course-grid \
  origin/main
```

## Example - Codex

```bash
git fetch origin

git worktree add \
  ../acedra-codex-csa-102 \
  -b security/csa-102-payment-webhook \
  origin/main
```

Rules:

- Never share the same mutable worktree.
- Never modify another agent's branch.
- Never overwrite uncommitted work.
- Never force-push main.
- Never run destructive Git commands
  against another active task.
- Do not delete active worktrees.
- Keep local runtime state isolated.

If agents execute on separate machines,
use separate clones and GitHub branches.

---

# 11. SHARED FILE COORDINATION

The following paths require
special coordination:

AGENTS.md
PLAN.md
TASKS.md
ARCHITECTURE.md
DATABASE_DESIGN.md
DESIGN_SYSTEM.md
SECURITY.md
CONTRIBUTING.md
TESTING.md

CLAUDE.md
docs/PARALLEL_WORKFLOW.md

pubspec.yaml
pubspec.lock

lib/app/**
lib/core/**
lib/shared/**

supabase/migrations/**

.github/workflows/**
.github/CODEOWNERS

Shared API contracts
Shared database models
Shared design tokens

## Shared File Rule

Only one coordinated task should own
conflicting shared changes at a time.

Before editing:

1. Check the shared-file coordination record.
2. Identify current owner.
3. Declare proposed file changes.
4. Obtain temporary ownership.
5. Implement the change.
6. Verify the result.
7. Release ownership after the agreed stage.

Logical ownership records are not
filesystem locks.

They require team compliance.

## Conflict Handling

When overlap is discovered:

- Stop conflicting edits.
- Preserve both agents' work.
- Assign one integration owner.
- Review intended behavior.
- Resolve through a dedicated task.
- Run affected tests again.

Never automatically discard the
other agent's code.

---

# 12. DATABASE MIGRATION RULES

Database migrations require
controlled ownership.

Important:

- One owner per migration.
- Schema contracts must be approved.
- Migration ordering must be verified.
- Never silently edit another migration.
- Never bypass RLS.
- Review database grants.
- Test transaction safety.
- Test privilege boundaries.

Different migrations may be authored
in parallel only when independently
compatible and explicitly coordinated.

Integration must serialize conflicting
schema changes.

Do not use production databases
for normal parallel development.

---

# 13. API CONTRACT RULES

Frontend and backend may be developed
in parallel against approved contracts.

Before implementation, define:

- Function name
- Request structure
- Response structure
- Authentication requirements
- Authorization requirements
- Error codes
- State transition rules
- Idempotency behavior

Example:

Contract:
create-checkout-order

Frontend Owner:
CLAUDE

Backend Owner:
CODEX

Frontend may use synthetic responses.

Backend implements trusted functionality.

Neither agent may change the contract
without coordinating the change.

Never use mocked payment success
as evidence of actual payment verification.

---

# 14. PARALLEL DEVELOPMENT WAVES

Parallel tasks are organized into
dependency-aware development waves.

A wave begins only after its entry
requirements are satisfied.

## WAVE 0 - PROJECT DECISIONS

Owner:
LEAD

Focus:

- Finalize requirements
- Approve architecture
- Approve payment provider
- Define enrollment policy
- Finalize database design
- Finalize PDF security strategy
- Approve initial UI/UX direction

Exit:
Critical design decisions approved.

## WAVE 1 - PROJECT FOUNDATIONS

CLAUDE:

- Flutter scaffolding
- Navigation foundation
- UI architecture
- Design token planning

CODEX:

- Supabase environment
- Backend configuration
- Initial data design
- Database testing infrastructure

Shared:
Repository and dependency contracts.

## WAVE 2 - CORE FOUNDATIONS

CLAUDE:

- Design system components
- Authentication screens
- Public marketplace layouts

CODEX:

- Authentication database policies
- Trusted role handling
- Course database schema
- Backend permission tests

Integration:
Authentication and course data contracts.

## WAVE 3 - COMMERCE

CLAUDE:

- Checkout UI
- Bank transfer upload interface
- Payment status screens

CODEX:

- Orders
- Payment gateway adapter
- Verified callbacks
- Bank receipt authorization
- Enrollment transactions

Integration:
Complete sandbox payment flows.

## WAVE 4 - LEARNING

CLAUDE:

- Learning workspace
- Video player UI
- Protected PDF reader UI
- Progress indicators

CODEX:

- Protected document authorization
- Video playback authorization
- Learning progress schema
- Access revocation enforcement

Integration:
Authorized course learning journey.

## WAVE 5 - ADMINISTRATION

CLAUDE:

- Admin dashboard UI
- Course management screens
- Student management screens
- Receipt review layouts

CODEX:

- Trusted admin operations
- Audit logs
- Financial reporting APIs
- Role permission verification

Integration:
End-to-end administrative workflows.

## WAVE 6 - QUALITY AND RELEASE

CLAUDE:

- Responsive UI verification
- Widget tests
- Accessibility review
- Browser integration tests

CODEX:

- Backend security tests
- Database tests
- Payment concurrency tests
- Infrastructure verification

LEAD:

- Review critical risks
- Coordinate final integration
- Approve production readiness

These waves describe possible concurrency,
not permission to ignore dependencies.

---

# 15. PHASE 0 - REQUIREMENTS AND ARCHITECTURE

All items start unchecked.

- [x] CSA-001 [P1] [L]
  Review and finalize SRS.md.
  DONE, CODEX: SRS 1.1 baseline formally accepted by owner on 2026-10-11; [approval and explicit downstream gates](docs/requirements/README.md).

- [x] CSA-002 [P1] [L]
  Finalize MVP scope and acceptance criteria.
  DONE, CODEX: [MVP scope and acceptance matrix](docs/requirements/CSA-001-002-SRS-MVP.md) accepted by owner on 2026-10-11; product verification remains future work.

- [x] CSA-003 [P1] [L]
  Approve roles and permissions.
  DONE, CODEX: [permission matrix](docs/requirements/CSA-003-ROLES.md) approved by owner on 2026-10-11; implementation unverified.

- [x] CSA-004 [P0] [L]
  Select payment gateway and currency.
  DONE, CODEX: [PayHere/LKR selection and documentation](docs/requirements/CSA-004-PAYMENT-DECISION.md) accepted by owner on 2026-10-11. Merchant readiness unverified.

- [x] CSA-005 [P0] [L]
  Define bank transfer verification policy.
  DONE, CODEX: [bank verification policy](docs/requirements/CSA-005-BANK-POLICY.md) approved by owner on 2026-10-11; listed operational gates remain.

- [x] CSA-006 [P0] [L]
  Define enrollment, expiry, and refund rules.
  DONE, CODEX: [enrollment/refund policy](docs/requirements/CSA-006-ENROLLMENT-REFUNDS.md) accepted by owner on 2026-10-11; operational terms and implementation remain gated.

- [x] CSA-007 [P1] [L]
  Approve ARCHITECTURE.md.
  DONE, CODEX: [architecture baseline](docs/requirements/CSA-007-ARCHITECTURE.md) accepted by owner on 2026-10-11; implementation unverified.

- [x] CSA-008 [P0] [X]
  Design database entities and relationships.
  DONE, CODEX: [entity/relationship baseline](docs/requirements/CSA-008-DATABASE.md) accepted by owner on 2026-10-11; existing draft preserved; migrations/tests remain future work.

- [x] CSA-009 [P0] [X]
  Create initial security threat model.
  DONE, CODEX: SECURITY.md threat model merged in PR #1 (be0aede); completion reconciled at owner's request on 2026-10-11. [Evidence and remaining security work](docs/requirements/CSA-009-016-RECONCILIATION.md).

- [x] CSA-010 [P0] [L]
  Approve protected PDF delivery strategy.
  DONE, CODEX: [authenticated proxy/watermark strategy](docs/requirements/CSA-010-PDF-DELIVERY.md) accepted by owner on 2026-10-11; runtime/reader validation remains required.

- [x] CSA-011 [P1] [L]
  Select protected video delivery provider.
  Status: DONE - owner-accepted documentation deliverable; runtime/release gates retained.
  Confirmed Owner: CODEX preparation; PROJECT LEAD approval on 2026-10-11.
  Related Pull Request: https://github.com/iamramishka/acendra/pull/7
  Completion Evidence: [approval record](docs/requirements/CSA-011-017-APPROVAL.md).
  Verification: documentation checks and merged reviewed revision; no runtime CI pass claimed.

- [x] CSA-012 [P1] [L]
  Approve environments and budget limits.
  Status: DONE - owner-accepted documentation deliverable; runtime/release gates retained.
  Confirmed Owner: CODEX preparation; PROJECT LEAD approval on 2026-10-11.
  Related Pull Request: https://github.com/iamramishka/acendra/pull/8
  Completion Evidence: [approval record](docs/requirements/CSA-011-017-APPROVAL.md).
  Verification: documentation checks and merged reviewed revision; no runtime CI pass claimed.

- [x] CSA-013 [P1] [L]
  Review PLAN.md and AGENTS.md.
  Status: DONE - owner-accepted documentation deliverable; runtime/release gates retained.
  Confirmed Owner: CODEX preparation; PROJECT LEAD approval on 2026-10-11.
  Related Pull Request: https://github.com/iamramishka/acendra/pull/12
  Completion Evidence: [approval record](docs/requirements/CSA-011-017-APPROVAL.md).
  Verification: documentation checks and merged reviewed revision; no runtime CI pass claimed.

- [x] CSA-014 [P1] [C]
  Review and refine DESIGN_SYSTEM.md.
  Status: DONE - owner-accepted documentation deliverable; runtime/release gates retained.
  Confirmed Owner: CODEX preparation; PROJECT LEAD approval on 2026-10-11.
  Related Pull Request: https://github.com/iamramishka/acendra/pull/9
  Completion Evidence: [approval record](docs/requirements/CSA-011-017-APPROVAL.md).
  Verification: documentation checks and merged reviewed revision; no runtime CI pass claimed.

- [x] CSA-015 [P0] [L]
  Approve privacy and security baseline.
  Status: DONE - owner-accepted documentation deliverable; runtime/release gates retained.
  Confirmed Owner: CODEX preparation; PROJECT LEAD approval on 2026-10-11.
  Related Pull Request: https://github.com/iamramishka/acendra/pull/10
  Completion Evidence: [approval record](docs/requirements/CSA-011-017-APPROVAL.md).
  Verification: documentation checks and merged reviewed revision; no runtime CI pass claimed.

- [x] CSA-016 [P1] [X]
  Draft initial architecture decision records.
  Status: DONE - draft deliverable and approval reconciliation complete
  Confirmed Owner: CODEX (user-directed; no GitHub issue found)
  Work Completed:
  - Drafted twelve ADRs in merged PR #2; reconciled eleven Accepted records
    against owner-approved architecture/policies from PR #3/#4.
  - Moved accepted records to docs/decisions/; ADR-010 was subsequently accepted under CSA-011; see the six-task approval record.
  - Numbering reconciled by CSA-007; [canonical index](docs/decisions/README.md).
  Related Pull Request:
  https://github.com/iamramishka/acendra/pull/2
  Completion Evidence:
  - Commit b4ef00e; documentation field and index-link checks passed.
  - git diff --cached --check passed; application tests do not apply.
  Current Blockers:
  - None for the initial drafting/reconciliation task. Video provider selection
    was subsequently accepted under CSA-011; production and implementation gates remain separate.
  Next Action:
  - Complete remaining operational Phase 0 inputs. See the
    [completion reconciliation](docs/requirements/CSA-009-016-RECONCILIATION.md).
  Next Owner: PROJECT LEAD
  Last Updated: 2026-10-11

- [x] CSA-017 [P1] [L]
  Define MVP acceptance test strategy.
  Status: DONE - owner-accepted documentation deliverable; runtime/release gates retained.
  Confirmed Owner: CODEX preparation; PROJECT LEAD approval on 2026-10-11.
  Related Pull Request: https://github.com/iamramishka/acendra/pull/11
  Completion Evidence: [approval record](docs/requirements/CSA-011-017-APPROVAL.md).
  Verification: documentation checks and merged reviewed revision; no runtime CI pass claimed.

Phase 0 Exit:

- [ ] Core requirements approved.
- [ ] Architecture boundaries approved.
- [ ] Payment policy defined.
- [ ] Enrollment rules defined.
- [ ] Database model reviewed.
- [ ] Security assumptions documented.
- [ ] Parallel task boundaries identified.

---

# 16. PHASE 1 - PROJECT SETUP

Dependencies:
Phase 0 approved baseline.

## CLAUDE - FLUTTER FOUNDATIONS

- [ ] CSA-018 [P1] [C]
  Initialize Flutter application.

- [ ] CSA-019 [P1] [C]
  Pin Flutter/Dart SDK versions.

- [ ] CSA-020 [P1] [C]
  Create feature-first Flutter structure.

- [ ] CSA-021 [P1] [C]
  Configure Riverpod.

- [ ] CSA-022 [P1] [C]
  Configure go_router.

- [ ] CSA-023 [P1] [C]
  Configure Dart analysis and lint rules.

- [ ] CSA-024 [P1] [C]
  Implement application error foundations.

## LEAD - REPOSITORY GOVERNANCE

- [ ] CSA-025 [P1] [L]
  Create private GitHub repository.

- [ ] CSA-026 [P1] [L]
  Configure README and .gitignore.

- [ ] CSA-027 [P1] [L]
  Commit approved project documentation.

- [ ] CSA-028 [P1] [L]
  Add CONTRIBUTING.md.

- [ ] CSA-029 [P1] [L]
  Add GitHub issue and PR templates.

- [ ] CSA-030 [P1] [L]
  Configure branch protection where supported.

- [ ] CSA-031 [P0] [L]
  Configure secret protection.

## CODEX - BACKEND FOUNDATIONS

- [ ] CSA-032 [P1] [X]
  Initialize Supabase configuration.

- [ ] CSA-033 [P1] [X]
  Configure local Supabase development.

- [ ] CSA-034 [P0] [X]
  Define safe environment configuration.

- [ ] CSA-035 [P1] [X]
  Configure migration and database tests.

## INTEGRATION / CI

- [x] CSA-036 [P1] [X]
  Configure GitHub Actions CI.

- [x] CSA-037 [P1] [X]
  Configure dependency monitoring.

- [x] CSA-038 [P1] [X]
  Configure baseline automated tests.

Phase 1 Exit:

- [ ] Flutter builds successfully.
- [ ] Supabase local environment works.
- [ ] CI runs.
- [ ] Repository conventions exist.
- [ ] Agents have isolated workspaces.
- [ ] Secrets are protected.

---

# 17. PHASE 2 - DESIGN SYSTEM

Dependencies:
Flutter foundation.

Suggested Owner:
CLAUDE

- [ ] CSA-039 [P1] [C]
  Implement color tokens.

- [ ] CSA-040 [P1] [C]
  Implement typography tokens.

- [ ] CSA-041 [P1] [C]
  Implement spacing and radius tokens.

- [ ] CSA-042 [P1] [C]
  Implement responsive breakpoints.

- [ ] CSA-043 [P1] [C]
  Configure Material 3 themes.

- [ ] CSA-044 [P1] [C]
  Implement light/dark switching.

- [ ] CSA-045 [P1] [C]
  Build reusable buttons.

- [ ] CSA-046 [P1] [C]
  Build reusable input components.

- [ ] CSA-047 [P1] [C]
  Build course and information cards.

- [ ] CSA-048 [P1] [C]
  Build skeleton loading components.

- [ ] CSA-049 [P1] [C]
  Build empty and error states.

- [ ] CSA-050 [P1] [C]
  Build dialogs, badges, and feedback.

- [ ] CSA-051 [P1] [C]
  Build public navigation shell.

- [ ] CSA-052 [P1] [C]
  Build authentication shell.

- [ ] CSA-053 [P1] [C]
  Build student navigation shell.

- [ ] CSA-054 [P1] [C]
  Build learning navigation shell.

- [ ] CSA-055 [P1] [C]
  Build admin navigation shell.

- [ ] CSA-056 [P1] [C]
  Implement accessibility foundations.

- [ ] CSA-057 [P1] [C]
  Test responsive layouts.

- [ ] CSA-058 [P1] [C]
  Add shared widget tests.

Parallel Opportunity:

CODEX may independently implement
approved authentication and database
foundations while CLAUDE develops UI.

Do not share active modifications
to lib/app/theme or pubspec files.

Phase 2 Exit:

- [ ] Theme engine works.
- [ ] Reusable components exist.
- [ ] Navigation shells function.
- [ ] Mobile/tablet/desktop checked.
- [ ] Accessibility reviewed.
- [ ] Relevant tests pass.

---

# 18. PHASE 3 - AUTHENTICATION

Backend Owner:
CODEX

UI Owner:
CLAUDE

## CODEX - BACKEND

- [x] CSA-059 [P0] [X]
  Create profile and role schema.

- [x] CSA-060 [P0] [X]
  Implement profile RLS policies.

- [x] CSA-061 [P0] [X]
  Implement trusted role assignments.

- [x] CSA-062 [P0] [X]
  Configure authentication security.

## CLAUDE - UI

- [ ] CSA-063 [P1] [C]
  Implement registration screen.

- [ ] CSA-064 [P1] [C]
  Implement email verification flow.

- [ ] CSA-065 [P1] [C]
  Implement login screen.

- [ ] CSA-066 [P1] [C]
  Implement forgot password flow.

- [ ] CSA-067 [P1] [C]
  Implement password reset flow.

- [ ] CSA-068 [P1] [C]
  Implement logout interface.

- [ ] CSA-069 [P1] [C]
  Implement session restoration.

- [ ] CSA-070 [P1] [C]
  Implement profile screen.

- [ ] CSA-071 [P1] [C]
  Implement profile editing.

- [ ] CSA-072 [P1] [C]
  Implement route navigation guards.

## CODEX - AUTHORIZATION

- [x] CSA-073 [P0] [X]
  Enforce trusted admin permissions.

- [x] CSA-074 [P0] [X]
  Test cross-user profile isolation.

- [x] CSA-075 [P0] [X]
  Test unauthorized admin operations.

## SHARED INTEGRATION

- [ ] CSA-076 [P1] [C]
  Test complete authentication flows.

Integration Gate:

- [ ] Auth contracts compatible.
- [ ] Login works.
- [ ] Profile policies work.
- [ ] Cross-user access denied.
- [ ] Admin permissions verified.

---

# 19. PHASE 4 - COURSE MARKETPLACE

Backend Owner:
CODEX

UI Owner:
CLAUDE

## CODEX - COURSE DATA

- [ ] CSA-077 [P1] [X]
  Create course and category schema.

- [ ] CSA-078 [P1] [X]
  Create sections and lessons schema.

- [ ] CSA-079 [P0] [X]
  Implement publication access policies.

- [ ] CSA-080 [P1] [X]
  Define media asset metadata.

- [ ] CSA-081 [P1] [X]
  Seed synthetic development course data.

## CLAUDE - MARKETPLACE

- [ ] CSA-082 [P1] [C]
  Implement marketplace homepage.

- [ ] CSA-083 [P1] [C]
  Implement responsive course grid.

- [ ] CSA-084 [P1] [C]
  Implement course search.

- [ ] CSA-085 [P1] [C]
  Implement category filtering.

- [ ] CSA-086 [P1] [C]
  Implement course details.

- [ ] CSA-087 [P1] [C]
  Implement curriculum preview.

- [ ] CSA-088 [P1] [C]
  Implement enrollment-aware UI.

## CODEX - COURSE MANAGEMENT BACKEND

- [ ] CSA-089 [P1] [X]
  Implement minimal authorized
  course creation workflow.

## TESTING

- [ ] CSA-090 [P1] [C]
  Test marketplace interactions.

- [ ] CSA-091 [P0] [X]
  Test unpublished course isolation.

Integration Gate:

- [ ] Course API contract verified.
- [ ] Published courses visible.
- [ ] Unpublished courses protected.
- [ ] Marketplace responsive.
- [ ] API and UI tests pass.

---

# 20. PHASE 5 - PAYMENTS AND ENROLLMENTS

Criticality:
P0 Security-Sensitive

Backend Owner:
CODEX

UI Owner:
CLAUDE

## CODEX - FINANCIAL DATABASE

- [ ] CSA-092 [P0] [X]
  Create orders and payment attempts.

- [ ] CSA-093 [P0] [X]
  Create payment event records.

- [ ] CSA-094 [P0] [X]
  Create bank transfer submission schema.

- [ ] CSA-095 [P0] [X]
  Create enrollment records.

- [ ] CSA-096 [P0] [X]
  Implement financial uniqueness
  and transaction constraints.

## CLAUDE - CHECKOUT UI

- [ ] CSA-097 [P1] [C]
  Implement checkout interface.

- [ ] CSA-099 [P1] [C]
  Implement payment method selector.

- [ ] CSA-106 [P1] [C]
  Implement payment status screens.

## CODEX - ONLINE PAYMENT BACKEND

- [ ] CSA-098 [P0] [X]
  Implement trusted order creation.

- [ ] CSA-100 [P0] [X]
  Implement payment adapter.

- [ ] CSA-101 [P0] [X]
  Implement checkout initialization.

- [ ] CSA-102 [P0] [X]
  Implement verified provider webhook.

- [ ] CSA-103 [P0] [X]
  Validate transaction amount and currency.

- [ ] CSA-104 [P0] [X]
  Implement atomic payment finalization.

- [ ] CSA-105 [P0] [X]
  Implement idempotent event processing.

## CLAUDE - BANK TRANSFER UI

- [ ] CSA-107 [P1] [C]
  Implement bank transfer instructions.

- [ ] CSA-110 [P1] [C]
  Implement receipt submission status UI.

- [ ] CSA-111 [P0] [C]
  Implement minimum finance review UI.

- [ ] CSA-115 [P1] [C]
  Implement receipt resubmission UI.

## CODEX - BANK TRANSFER BACKEND

- [ ] CSA-108 [P0] [X]
  Implement private receipt upload.

- [ ] CSA-109 [P0] [X]
  Validate receipt type and ownership.

- [ ] CSA-112 [P0] [X]
  Implement authorized bank approval.

- [ ] CSA-113 [P0] [X]
  Implement bank rejection processing.

- [ ] CSA-114 [P0] [X]
  Implement concurrency-safe approvals.

## CODEX - ENROLLMENTS

- [ ] CSA-116 [P0] [X]
  Implement entitlement grant logic.

- [ ] CSA-117 [P0] [X]
  Implement entitlement verification.

- [ ] CSA-118 [P0] [X]
  Implement access revocation.

- [ ] CSA-119 [P1] [X]
  Implement payment status notifications.

## CODEX - CRITICAL SECURITY TESTS

- [ ] CSA-120 [P0] [X]
  Test forged provider callbacks.

- [ ] CSA-121 [P0] [X]
  Test amount/currency mismatches.

- [ ] CSA-122 [P0] [X]
  Test duplicate provider events.

- [ ] CSA-123 [P0] [X]
  Test concurrent approval scenarios.

- [ ] CSA-124 [P0] [X]
  Test rejected/pending access denial.

- [ ] CSA-125 [P0] [X]
  Test unauthorized finance operations.

- [ ] CSA-126 [P0] [X]
  Test financial transaction recovery.

Integration Gate:

- [ ] Frontend/backend contracts compatible.
- [ ] Sandbox payment flow passes.
- [ ] Payment verification secure.
- [ ] Bank approval secure.
- [ ] Entitlement transactions atomic.
- [ ] Invalid payments remain locked.
- [ ] Critical security tests pass.

Do not merge incomplete payment workflows
into production-enabled functionality.

---

# 21. PHASE 6 - LEARNING AND PDF

Backend Owner:
CODEX

Learning UI Owner:
CLAUDE

## CODEX - LEARNING DATA

- [ ] CSA-127 [P1] [X]
  Create learning progress data model.

## CLAUDE - LEARNING UI

- [ ] CSA-128 [P1] [C]
  Implement My Courses.

- [ ] CSA-129 [P1] [C]
  Implement learning workspace.

- [ ] CSA-130 [P1] [C]
  Implement curriculum navigation.

- [ ] CSA-131 [P1] [C]
  Implement text lesson viewer.

- [ ] CSA-132 [P1] [C]
  Implement image lesson viewer.

- [ ] CSA-134 [P1] [C]
  Implement continue-learning UI.

## CODEX - LEARNING DATA INTEGRATION

- [ ] CSA-133 [P1] [X]
  Implement learning progress persistence.

## VIDEO

- [ ] CSA-135 [P1] [C]
  Implement video player interface.

- [ ] CSA-136 [P0] [X]
  Implement playback authorization.

- [ ] CSA-137 [P1] [C]
  Implement video error/loading states.

- [ ] CSA-138 [P1] [C]
  Implement playback progress integration.

## CODEX - PROTECTED PDF BACKEND

- [ ] CSA-139 [P0] [X]
  Configure private PDF storage.

- [ ] CSA-140 [P0] [X]
  Implement PDF entitlement checks.

- [ ] CSA-141 [P0] [X]
  Implement controlled PDF delivery.

## CLAUDE - PDF READER

- [ ] CSA-142 [P1] [C]
  Integrate evaluated PDF library.

- [ ] CSA-143 [P1] [C]
  Implement responsive reader interface.

- [ ] CSA-144 [P1] [C]
  Implement page navigation.

- [ ] CSA-145 [P1] [C]
  Implement zoom controls.

- [ ] CSA-146 [P1] [C]
  Implement fit-to-width and expanded view.

- [ ] CSA-147 [P1] [C]
  Implement reading position persistence UI.

## WATERMARK STRATEGY

- [ ] CSA-148 [P0] [X]
  Implement approved watermark delivery
  or generation strategy.

  UI presentation may be delegated
  to CLAUDE as a separate coordinated task.

## CLAUDE - READER QUALITY

- [ ] CSA-149 [P1] [C]
  Implement PDF loading/error states.

- [ ] CSA-150 [P1] [C]
  Verify readability and accessibility.

- [ ] CSA-151 [P2] [C]
  Add bookmarks/search where supported.

## SECURITY AND INTEGRATION TESTS

- [ ] CSA-152 [P0] [X]
  Test unauthorized PDF requests.

- [ ] CSA-153 [P0] [X]
  Test revoked entitlement behavior.

- [ ] CSA-154 [P0] [X]
  Test unauthorized video playback.

- [ ] CSA-155 [P1] [X]
  Test learning progress persistence.

- [ ] CSA-156 [P1] [C]
  Test PDF rendering across devices.

Integration Gate:

- [ ] Learning progress saved.
- [ ] Course content authorized.
- [ ] PDF reader works.
- [ ] Video playback works.
- [ ] Unauthorized content denied.
- [ ] PDF watermark approach evaluated.
- [ ] Reader accessible and responsive.
- [ ] Browser capture limitations documented.

---

# 22. PHASE 7 - ADMIN SYSTEM

Frontend Owner:
CLAUDE

Backend Owner:
CODEX

## CLAUDE - ADMIN UI

- [ ] CSA-157 [P1] [C]
  Implement admin dashboard.

- [ ] CSA-159 [P1] [C]
  Implement payment queue summary UI.

- [ ] CSA-160 [P1] [C]
  Implement course management list.

- [ ] CSA-161 [P1] [C]
  Implement course editor.

- [ ] CSA-162 [P1] [C]
  Implement curriculum builder.

- [ ] CSA-163 [P1] [C]
  Implement lesson editor.

- [ ] CSA-166 [P1] [C]
  Implement student management list.

- [ ] CSA-167 [P1] [C]
  Implement student enrollment details UI.

- [ ] CSA-169 [P1] [C]
  Complete finance review dashboard.

- [ ] CSA-170 [P1] [C]
  Implement payment search/filter UI.

- [ ] CSA-171 [P1] [C]
  Implement receipt review history UI.

## CODEX - ADMIN BACKEND

- [ ] CSA-158 [P1] [X]
  Implement real dashboard statistics.

- [ ] CSA-164 [P1] [X]
  Implement authorized media uploads.

- [ ] CSA-165 [P1] [X]
  Implement trusted course publish actions.

- [ ] CSA-168 [P0] [X]
  Implement audited enrollment management.

- [ ] CSA-172 [P1] [X]
  Implement transaction reporting backend.

- [ ] CSA-173 [P0] [X]
  Verify all admin operation permissions.

- [ ] CSA-174 [P0] [X]
  Implement/review audit logging.

- [ ] CSA-175 [P0] [X]
  Implement trusted role management.

- [ ] CSA-176 [P0] [X]
  Test unauthorized admin API access.

Integration Gate:

- [ ] Admin UI functions.
- [ ] Backend permissions verified.
- [ ] Payment approval audited.
- [ ] Course builder works.
- [ ] Financial data is accurate.
- [ ] Student private data protected.

---

# 23. PHASE 8 - QUALITY ASSURANCE

## END-TO-END TESTS

- [ ] CSA-177 [P1] [C]
  Test registration journey.

- [ ] CSA-178 [P0] [X]
  Test online purchase journey.

- [ ] CSA-179 [P0] [X]
  Test bank approval journey.

- [ ] CSA-180 [P0] [X]
  Test purchase-to-learning entitlement.

- [ ] CSA-181 [P1] [C]
  Test admin course publishing journey.

## CODEX - SECURITY TESTING

- [ ] CSA-182 [P0] [X]
  Audit RLS and grants.

- [ ] CSA-183 [P0] [X]
  Test cross-student data isolation.

- [ ] CSA-184 [P0] [X]
  Test finance role restrictions.

- [ ] CSA-185 [P0] [X]
  Test private file policies.

- [ ] CSA-186 [P0] [X]
  Test upload security.

- [ ] CSA-187 [P0] [X]
  Review XSS and security headers.

- [ ] CSA-188 [P0] [X]
  Review secrets and logging.

- [ ] CSA-189 [P0] [X]
  Review dependency vulnerabilities.

## CLAUDE - UI/UX TESTING

- [ ] CSA-190 [P1] [C]
  Test small mobile widths.

- [ ] CSA-191 [P1] [C]
  Test tablet layouts.

- [ ] CSA-192 [P1] [C]
  Test desktop layouts.

- [ ] CSA-193 [P1] [C]
  Test light/dark themes.

- [ ] CSA-194 [P1] [C]
  Test keyboard accessibility.

- [ ] CSA-195 [P1] [C]
  Validate high-priority user workflows.

## PERFORMANCE

- [ ] CSA-196 [P1] [C]
  Measure Flutter startup performance.

- [ ] CSA-197 [P1] [X]
  Measure database query performance.

- [ ] CSA-198 [P1] [C]
  Test large PDF rendering.

- [ ] CSA-199 [P1] [C]
  Test protected video playback.

## RELIABILITY AND RELEASE

- [ ] CSA-200 [P0] [X]
  Test backup and recovery.

- [ ] CSA-201 [P0] [X]
  Test financial failure recovery.

- [ ] CSA-202 [P0] [L]
  Coordinate critical security fixes.

- [ ] CSA-203 [P0] [L]
  Coordinate release-blocking bug fixes.

- [ ] CSA-204 [P1] [L]
  Complete regression acceptance review.

Quality Gate:

- [ ] Critical tests pass.
- [ ] Security requirements verified.
- [ ] Responsive interfaces verified.
- [ ] Financial integrity verified.
- [ ] Integration tests pass.
- [ ] No unresolved release blockers.

---

# 24. PHASE 9 - PRODUCTION RELEASE

Production activities require
authorized project approval.

## INFRASTRUCTURE

- [ ] CSA-205 [P1] [X]
  Configure production hosting.

- [ ] CSA-206 [P0] [X]
  Configure HTTPS and domain.

- [ ] CSA-207 [P0] [X]
  Configure production secrets.

- [ ] CSA-208 [P0] [X]
  Apply reviewed production migrations.

- [ ] CSA-209 [P0] [X]
  Configure production storage policies.

## PAYMENT PRODUCTION

- [ ] CSA-210 [P0] [X]
  Configure live payment provider.

- [ ] CSA-211 [P0] [X]
  Verify production payment notifications.

- [ ] CSA-212 [P0] [X]
  Verify finance approval permissions.

## OPERATIONS

- [ ] CSA-213 [P0] [X]
  Configure monitoring and alerts.

- [ ] CSA-214 [P0] [X]
  Configure backups.

- [ ] CSA-215 [P0] [L]
  Finalize incident response contacts.

- [ ] CSA-216 [P0] [X]
  Finalize recovery runbooks.

- [ ] CSA-217 [P1] [L]
  Approve privacy and commercial policies.

## RELEASE APPROVAL

- [ ] CSA-218 [P0] [L]
  Complete security release checklist.

- [ ] CSA-219 [P0] [L]
  Approve production launch.

- [ ] CSA-220 [P1] [L]
  Create authorized release tag.

- [ ] CSA-221 [P0] [L]
  Coordinate post-deployment smoke tests.

- [ ] CSA-222 [P1] [L]
  Review initial operational readiness.

Production Gate:

- [ ] Required approvals obtained.
- [ ] Payment security verified.
- [ ] Content access verified.
- [ ] Monitoring operational.
- [ ] Backup/recovery validated.
- [ ] Release smoke tests completed.

No agent may independently
deploy to production without authorization.

---

# 25. POST-MVP BACKLOG

These tasks remain outside MVP unless
the approved scope changes.

- [ ] CSA-223 [P2] [C]
  Advanced bookmarks and notes.

- [ ] CSA-224 [P2] [C]
  Quizzes and assessments.

- [ ] CSA-225 [P2] [C]
  Course certificates.

- [ ] CSA-226 [P2] [X]
  Advanced student analytics.

- [ ] CSA-227 [P2] [X]
  Discount coupon backend and integration.

- [ ] CSA-228 [P2] [X]
  Course bundles.

- [ ] CSA-229 [P3] [X]
  Subscription billing.

- [ ] CSA-230 [P3] [X]
  Referral and affiliate system.

- [ ] CSA-231 [P2] [C]
  Multilingual interface.

- [ ] CSA-232 [P3] [C]
  Native Android application.

- [ ] CSA-233 [P3] [C]
  Native iOS application.

- [ ] CSA-234 [P3] [C]
  Evaluate native capture restrictions.

- [ ] CSA-235 [P3] [X]
  Multi-instructor administration.

Future tasks require approved
requirements and architectural review.

---

# 26. NEW MULTI-AGENT COORDINATION TASKS

These tasks extend the previous backlog.

They establish safe parallel development.

## REPOSITORY COORDINATION

- [ ] CSA-236 [P1] [L]
  Configure GitHub task ownership fields.

  Acceptance:
  GitHub Issues show assigned agent,
  owner, priority, status, and dependencies.

- [ ] CSA-237 [P1] [L]
  Create docs/PARALLEL_WORKFLOW.md.

  Acceptance:
  Claiming, locking, handoffs, integration,
  and conflict resolution are documented.

- [ ] CSA-238 [P1] [L]
  Create CLAUDE.md.

  Acceptance:
  Claude instructions reference AGENTS.md
  without duplicating conflicting policies.

- [ ] CSA-239 [P1] [L]
  Define agent branch/worktree conventions.

- [ ] CSA-240 [P1] [L]
  Configure .github/CODEOWNERS.

  Important:
  CODEOWNERS should identify actual
  human/team reviewers where supported,
  not fictional AI account identities.

- [ ] CSA-241 [P1] [L]
  Extend pull request template
  with agent and task metadata.

## ISOLATION AND LOCKS

- [x] CSA-242 [P1] [X]
  Configure isolated CI test environments.
  DONE, CODEX: isolated hosted-runner workflow and disposable local backend checks are verified. See [CSA-242/244/248 handoff](docs/tasks/CSA-242-244-248.md) and issue #49.

- [ ] CSA-243 [P0] [L]
  Establish shared-file ownership protocol.

- [x] CSA-244 [P1] [X]
  Establish shared API contract registry.
  DONE, CODEX: canonical registry and change/ownership procedures are documented; proposed API/business decisions remain unapproved. See [CSA-242/244/248 handoff](docs/tasks/CSA-242-244-248.md) and issue #49.

- [ ] CSA-245 [P1] [L]
  Document agent worktree setup.

- [ ] CSA-246 [P1] [L]
  Document safe worktree cleanup.

## INTEGRATION AND VERIFICATION

- [ ] CSA-247 [P1] [L]
  Define integration task workflow.

- [x] CSA-248 [P1] [X]
  Configure isolated backend test data.
  DONE, CODEX: separate worktree/test profiles and rollback-scoped synthetic fixtures are verified. See [CSA-242/244/248 handoff](docs/tasks/CSA-242-244-248.md) and issue #49.

- [ ] CSA-249 [P1] [L]
  Establish task status reconciliation.

- [ ] CSA-250 [P1] [L]
  Run controlled two-agent dry-run.

  Suggested dry-run:

  Claude:
  Independent UI component.

  Codex:
  Independent backend test utility.

  Acceptance:
  Separate branches and workspaces,
  both CI checks pass, PRs reviewed,
  integration verified, no file conflicts.

- [ ] CSA-251 [P1] [L]
  Define merge queue and revalidation process.

  Acceptance:
  Integration order is dependency-aware,
  and post-merge regression checks are defined.

- [ ] CSA-252 [P0] [L]
  Define security-sensitive AI review policy.

  Acceptance:
  Payments, RLS, enrollment, and production
  changes require appropriate authorized review.

## Multi-Agent Setup Gate

- [ ] Task allocation process established.
- [ ] GitHub Issues configured.
- [ ] Worktree isolation demonstrated.
- [ ] Shared-file rules documented.
- [ ] Contract changes coordinated.
- [ ] Two-agent dry-run verified.
- [ ] Integration process approved.

The multi-agent setup gate should be
completed before scaling concurrent work.

---

# 27. ACTIVE TASK ALLOCATION BOARD

This section summarizes active work.

It must reflect actual GitHub assignments.

Do not populate with fabricated
agent claims or PR references.

Current Baseline:

No implementation task is confirmed
as claimed by this document alone.

## Active Claude Task

Task ID: NONE
Status: UNASSIGNED
Branch: NONE
Worktree: NONE
PR: NONE

## Active Codex Task

Task ID: NONE
Status: UNASSIGNED
Branch: NONE
Worktree: NONE
PR: NONE

## Integration Task

Task ID: NONE
Owner: UNASSIGNED
Status: NOT STARTED

GitHub Issues are the live source
for claims and intermediate statuses.

Update this summary during
approved project reconciliation.

---

# 28. TASK DEPENDENCY RULES

A dependent task cannot be declared
READY until its required prerequisites
are sufficiently verified.

Important chains:

## Authentication

Profile schema
  -> Authentication configuration
  -> User flows
  -> Authorization integration
  -> Security tests

## Commerce

Course schema
  -> Order schema
  -> Payment initialization
  -> Verified callback
  -> Atomic finalization
  -> Entitlement grant
  -> Learning access

## Bank Transfer

Order
  -> Receipt authorization
  -> Private upload
  -> Bank verification
  -> Approved review transaction
  -> Enrollment grant

## Protected PDFs

Private storage
  -> Entitlement verification
  -> Delivery authorization
  -> PDF reader integration
  -> Watermarking
  -> Security tests

## Admin Operations

Trusted roles
  -> Backend permissions
  -> Admin workflows
  -> Audit logs
  -> Authorization tests

Frontend screens may begin earlier
against approved synthetic contracts.

However, a mocked UI is not an
accepted end-to-end business feature.

---

# 29. TASK EXECUTION LIMITS

Use controlled concurrency.

Recommended initial limit:

- One active implementation task for Claude.
- One active implementation task for Codex.
- One integration task when necessary.

This is an operational starting policy,
not a technical limit of either tool.

Additional concurrent tasks may be
approved after the coordination workflow
is demonstrated to be reliable.

Avoid starting many branches
with unfinished dependencies.

Prefer completing and integrating
small tasks before expanding concurrency.

---

# 30. GITHUB TASK SYNCHRONIZATION

Source of truth:

GitHub Issues:
Live ownership, status, and PR links.

TASKS.md:
Stable master backlog and milestones.

PLAN.md:
Phase-level roadmap.

## Synchronization Rules

- Task ownership is recorded on GitHub.
- Intermediate status is updated on GitHub.
- TASKS.md is updated at milestones.
- No two agents should edit TASKS.md
  concurrently without coordination.
- Changes to task scope require approval.
- Cancelled tasks retain their identifiers.
- Do not reuse previously assigned IDs.

If GitHub and TASKS.md disagree:

1. Stop any conflicting new assignment.
2. Review recent approved decisions.
3. Reconcile task ownership and status.
4. Update the stale record.
5. Resume affected work.

Never silently overwrite
another agent's task progress.

---

# 31. CROSS-AGENT HANDOFF TEMPLATE

Every handoff should include:

## Task

Task ID:
Title:
Agent:
Status:

## Source Control

Branch:
Commit:
Pull Request:
Base Revision:

## Work Completed

Describe verified implementation.

## Files Changed

List affected files.

## Shared Contracts

List changed API/schema contracts.

## Testing

Commands run:
Results:
Checks not performed:

## Risks

Known bugs:
Security implications:
Unresolved issues:

## Required Next Action

Next owner:
Dependency:
Recommended action:

Do not rely only on chat history
for development handoffs.

Use shared GitHub records.

---

# 32. CROSS-AGENT REVIEW RULES

Claude may review Codex changes.

Codex may review Claude changes.

Review should cover:

- Functional correctness
- Requirements alignment
- Architecture
- Security
- Test quality
- API contract compatibility
- Data integrity
- UI/UX impact
- Maintainability

However:

AI review does not automatically
replace required human approval.

Critical payment, role, RLS, secret,
and production changes require an
authorized reviewer or approved
compensating governance process.

The implementing agent cannot claim
its own self-review was independent.

---

# 33. CONFLICT RESOLUTION POLICY

When changes conflict:

1. Identify affected tasks.
2. Pause conflicting integration.
3. Preserve both branches.
4. Identify intended behavior.
5. Assign a conflict-resolution owner.
6. Review dependencies.
7. Resolve changes deliberately.
8. Rerun tests.
9. Update affected documentation.
10. Submit the resolution for review.

Never use an automatic conflict
resolution that discards functionality
without inspection.

Never force-push main.

Never modify financial invariants
only to remove a merge conflict.

---

# 34. INTEGRATION ACCEPTANCE GATE

Before merging parallel work:

- [ ] Dependencies are satisfied.
- [ ] File ownership rules respected.
- [ ] No unresolved conflicts.
- [ ] Shared contracts remain compatible.
- [ ] Database migration order verified.
- [ ] RLS behavior tested where relevant.
- [ ] Payment invariants preserved.
- [ ] Flutter analysis passes.
- [ ] Relevant tests pass.
- [ ] UI behavior verified where relevant.
- [ ] Documentation updated.
- [ ] Required reviews completed.

After merging:

- Revalidate affected integration paths.
- Update dependent branches.
- Update GitHub task status.
- Release temporary ownership locks.
- Remove worktrees only when safe.

---

# 35. TESTING REQUIREMENTS

All agents must verify meaningful behavior.

## Flutter

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

## Supabase

```bash
supabase test db
```

Use configured backend function tests,
security tests, and integration tests
where relevant.

## Critical Tests

- Unauthorized enrollment denial
- Forged payment callback rejection
- Duplicate callback handling
- Bank receipt approval permissions
- Concurrent approval protection
- Cross-student data isolation
- Protected PDF authorization
- Revoked course access enforcement
- Admin privilege restrictions

## Isolation

Parallel agents must not share:

- Mutable test databases
- Conflicting local ports
- Writable test fixture directories
- Production payment accounts
- Customer financial data
- Uncoordinated migration state

Separate worktrees do not automatically
isolate all external services.

Environment isolation must be configured.

---

# 36. SECURITY RULES

Every agent must follow SECURITY.md.

Non-negotiable rules:

- Never bypass RLS.
- Never expose privileged API keys.
- Never trust frontend payment success.
- Never auto-approve bank receipts.
- Never create unauthorized enrollments.
- Never publicly expose paid PDFs.
- Never store student receipts in Git.
- Never fabricate tests.
- Never deploy without authorization.
- Never claim browser screenshots
  can be completely prevented.

Payment state changes must be trusted,
transactional, and auditable.

Sensitive changes must receive
appropriate review.

---

# 37. DEFINITION OF READY

A task is READY only when:

- [ ] Task ID exists.
- [ ] Requirements are defined.
- [ ] Priority is assigned.
- [ ] Dependencies are resolved.
- [ ] API contracts are available if required.
- [ ] File scope is defined.
- [ ] Shared-file conflicts are addressed.
- [ ] Security implications are identified.
- [ ] Acceptance criteria are testable.
- [ ] No unresolved decision blocks work.

READY does not mean work has started.

CLAIMED requires recorded ownership.

---

# 38. DEFINITION OF DONE

A task is DONE only when:

- [ ] Acceptance criteria satisfied.
- [ ] Scope respected.
- [ ] Architecture followed.
- [ ] Relevant tests pass.
- [ ] Static analysis passes.
- [ ] Security checked.
- [ ] Error handling verified.
- [ ] UI responsive where applicable.
- [ ] Accessibility evaluated.
- [ ] No secrets exposed.
- [ ] Shared file changes coordinated.
- [ ] Documentation updated.
- [ ] CI checks pass.
- [ ] Required review complete.
- [ ] Changes merged or formally accepted.
- [ ] Completion evidence recorded.

AI-generated code is not
automatically completed work.

An unmerged PR is normally IN_REVIEW,
not DONE.

---

# 39. PROGRESS REPORTING

Reports must use actual verified data.

Include:

- Current phase
- Tasks DONE
- Tasks IN_PROGRESS
- Tasks BLOCKED
- Active Claude task
- Active Codex task
- Active branches
- Open PRs
- Required integrations
- Security blockers
- Next ready tasks

Do not invent percentages or progress.

If progress is calculated:

Completed MVP Tasks /
Approved Total MVP Tasks

Track post-MVP work separately.

---

# 40. RELEASE BLOCKERS

Production release is blocked when:

- Payment verification is unsafe.
- Course access can be granted improperly.
- RLS policies expose private data.
- Bank approvals bypass verification.
- Sensitive content is publicly accessible.
- Production credentials are exposed.
- Critical tests fail.
- Required backups are unavailable.
- Critical vulnerabilities remain unresolved.
- Production approval is missing.

No AI agent may waive these
requirements independently.

---

# 41. NEXT EXECUTION ORDER

The recommended immediate actions are:

1. Approve updated AGENTS.md v2.0.

2. Approve updated TASKS.md v2.0.

3. Create docs/PARALLEL_WORKFLOW.md.

4. Create CLAUDE.md.

5. Update CONTRIBUTING.md for
   parallel development.

6. Configure GitHub Issues,
   task fields, and PR templates.

7. Establish worktree conventions.

8. Run the controlled parallel dry-run.

9. Finalize Phase 0 requirements
   and unresolved architecture decisions.

10. Start independent Flutter and
    backend development tasks.

Do not start security-critical
implementation using unresolved
financial or entitlement rules.

---

# 42. FINAL DIRECTIVE

Acedra uses coordinated parallel development.

CLAUDE and CODEX may work simultaneously
when tasks are independent.

Every task requires:

- Clear ownership
- Explicit scope
- Defined dependencies
- Isolated workspace
- Approved contracts
- Security-aware implementation
- Relevant tests
- Reviewable commits
- GitHub pull request
- Verified integration

Parallel development must be controlled.

Do not duplicate tasks.

Do not overwrite another agent's work.

Do not silently modify shared contracts.

Do not skip payment or security checks.

Do not fabricate completed work.

Only verified tasks may be marked DONE.

ONE TASK - ONE ACCOUNTABLE OWNER.
TWO AGENTS - ISOLATED WORKSPACES.
GITHUB - SHARED COORDINATION.
SECURITY - NON-NEGOTIABLE.
TESTS - REQUIRED.
REVIEW - BEFORE MERGE.
INTEGRATION - VERIFIED.

END OF TASKS.md
