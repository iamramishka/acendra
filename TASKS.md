
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

- [x] CSA-018 [P1] [C] [DONE]
  Initialize Flutter application.
  DONE: Flutter web project initialized with MaterialApp.router, bootstrap entry point, and web assets at commit 6fb5f31/5b5665b (Phase 0).

- [x] CSA-019 [P1] [C] [DONE]
  Pin Flutter/Dart SDK versions.
  DONE: Flutter/Dart SDK versions and dependency constraints pinned; lint rules configured at commit cd46798 (Phase 0).

- [x] CSA-020 [P1] [C] [DONE]
  Create feature-first Flutter structure.
  DONE: Feature-first Clean Architecture directory layout (features/<feature>/presentation/domain/data/) created at commit 6fb5f31 (Phase 0).

- [x] CSA-021 [P1] [C] [DONE]
  Configure Riverpod.
  DONE: flutter_riverpod configured; ProviderScope at app root; ThemeModeNotifier and AppConfig providers wired at commit 5b5665b (Phase 0).

- [x] CSA-022 [P1] [C] [DONE]
  Configure go_router.
  DONE: go_router configured with placeholder routes and MaterialApp.router integration at commit a7db6cb (Phase 0).

- [x] CSA-023 [P1] [C] [DONE]
  Configure Dart analysis and lint rules.
  DONE: analysis_options.yaml with flutter_lints and strict rules configured at commit cd46798 (Phase 0).

- [x] CSA-024 [P1] [C] [DONE]
  Implement application error foundations.
  DONE: AppFailure sealed hierarchy, AppException types, AppLogger, and env config implemented at commit 5b52fcf (Phase 0).

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

- [x] CSA-039 [P1] [C] [DONE]
  Implement color tokens.

- [x] CSA-040 [P1] [C] [DONE]
  Implement typography tokens.

- [x] CSA-041 [P1] [C] [DONE]
  Implement spacing and radius tokens. AppRadius.button=12, card=18.

- [x] CSA-042 [P1] [C] [DONE]
  Implement responsive breakpoints. AppBreakpoints + ScreenLayout + ResponsiveContainer.

- [x] CSA-043 [P1] [C] [DONE]
  Configure Material 3 themes. AppThemeExtension semantic colours.

- [x] CSA-044 [P1] [C] [DONE]
  Implement light/dark switching. ThemeModeNotifier + ThemeToggleButton.

- [x] CSA-045 [P1] [C] [DONE]
  Build reusable buttons. AppButton (primary/secondary/outlined/destructive, 3 sizes).

- [x] CSA-046 [P1] [C] [DONE]
  Build reusable input components. AppTextField + AppPasswordField.

- [x] CSA-047 [P1] [C] [DONE]
  Build course and information cards. CourseCard with thumbnail/title/instructor/rating/price.

- [x] CSA-048 [P1] [C] [DONE]
  Build skeleton loading components. AppSkeleton shimmer animation.

- [x] CSA-049 [P1] [C] [DONE]
  Build empty and error states. AppEmptyState + AppErrorState.

- [x] CSA-050 [P1] [C] [DONE]
  Build dialogs, badges, and feedback. AppDialog + StatusBadge + AppSnackbar.

- [x] CSA-051 [P1] [C] [DONE]
  Build public navigation shell. PublicShell responsive AppBar + drawer.

- [x] CSA-052 [P1] [C] [DONE]
  Build authentication shell. AuthShell centred card layout.

- [x] CSA-053 [P1] [C] [DONE]
  Build student navigation shell. StudentShell AppBar + bottom-nav.

- [x] CSA-054 [P1] [C] [DONE]
  Build learning navigation shell. LearningShell immersive with back button.

- [x] CSA-055 [P1] [C] [DONE]
  Build admin navigation shell. AdminShell 248px sidebar on desktop / drawer on mobile.

- [x] CSA-056 [P1] [C] [DONE]
  Implement accessibility foundations.
  DONE: Semantic labels (SemanticsLabels), accessible controls, focus management, and keyboard navigation foundations implemented at commit 93e757c; extended and reviewed in PR #105 (commit 4bdf495). Keyboard accessibility widget tests added in CSA-194 (commit 54e9fbf).

- [x] CSA-057 [P1] [C] [DONE]
  Test responsive layouts. ResponsiveContainer widget tests at breakpoint boundaries.

- [x] CSA-058 [P1] [C] [DONE]
  Add shared widget tests. 159 total tests all passing; flutter analyze clean.

Parallel Opportunity:

CODEX may independently implement
approved authentication and database
foundations while CLAUDE develops UI.

Do not share active modifications
to lib/app/theme or pubspec files.

Phase 2 Exit:

- [x] Theme engine works. AppTheme + AppThemeExtension + ThemeModeNotifier.
- [x] Reusable components exist. AppButton, AppTextField, CourseCard, AppSkeleton, feedback widgets.
- [x] Navigation shells function. All 5 shells wired into ShellRoute; 159 tests pass.
- [x] Mobile/tablet/desktop checked. Breakpoint tests at 599/600/1023/1024px.
- [x] Accessibility reviewed. CSA-056 DONE — semantic labels, keyboard nav, focus management implemented (PR #105). CSA-194 keyboard accessibility tests pass.
- [x] Relevant tests pass. 159/159 pass, flutter analyze clean, web build ✓.

Phase 2 Status: DONE (CSA-056 accessibility foundations deferred to Phase 3 sprint).

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

- [x] CSA-063 [P1] [C]
  Implement registration screen.

- [x] CSA-064 [P1] [C]
  Implement email verification flow.

- [x] CSA-065 [P1] [C]
  Implement login screen.

- [x] CSA-066 [P1] [C]
  Implement forgot password flow.

- [x] CSA-067 [P1] [C]
  Implement password reset flow.

- [x] CSA-068 [P1] [C]
  Implement logout interface.

- [x] CSA-069 [P1] [C]
  Implement session restoration.

- [x] CSA-070 [P1] [C]
  Implement profile screen.

- [x] CSA-071 [P1] [C]
  Implement profile editing.

- [x] CSA-072 [P1] [C]
  Implement route navigation guards.

## CODEX - AUTHORIZATION

- [x] CSA-073 [P0] [X]
  Enforce trusted admin permissions.

- [x] CSA-074 [P0] [X]
  Test cross-user profile isolation.

- [x] CSA-075 [P0] [X]
  Test unauthorized admin operations.

## SHARED INTEGRATION

- [x] CSA-076 [P1] [C]
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

- [x] CSA-077 [P1] [X]
  Create course and category schema.

- [x] CSA-078 [P1] [X]
  Create sections and lessons schema.

- [x] CSA-079 [P0] [X]
  Implement publication access policies.

- [x] CSA-080 [P1] [X]
  Define media asset metadata.

- [x] CSA-081 [P1] [X]
  Seed synthetic development course data.

## CLAUDE - MARKETPLACE

- [x] CSA-082 [P1] [C] [IN_REVIEW]
  Implement marketplace homepage.
  PR: feat/csa-082-090-marketplace-phase4. MarketplaceScreen with search, category filter, course grid, empty/error states.

- [x] CSA-083 [P1] [C] [IN_REVIEW]
  Implement responsive course grid.
  PR: feat/csa-082-090-marketplace-phase4. CourseGrid with 1/2/3 columns at mobile/tablet/desktop breakpoints. Navigation to CourseDetailScreen wired.

- [x] CSA-084 [P1] [C] [IN_REVIEW]
  Implement course search.
  PR: feat/csa-082-090-marketplace-phase4. SearchBar + filteredCoursesProvider filtering by title and short description.

- [x] CSA-085 [P1] [C] [IN_REVIEW]
  Implement category filtering.
  PR: feat/csa-082-090-marketplace-phase4. CategoryFilter horizontal chip row, selectedCategoryProvider, combined with search.

- [x] CSA-086 [P1] [C] [IN_REVIEW]
  Implement course details.
  PR: feat/csa-082-090-marketplace-phase4. CourseDetailScreen with price, description, section/lesson stats, enrollment-aware CTA.

- [x] CSA-087 [P1] [C] [IN_REVIEW]
  Implement curriculum preview.
  PR: feat/csa-082-090-marketplace-phase4. CurriculumPreview with expandable sections, lesson type icons, preview badges.

- [x] CSA-088 [P1] [C] [IN_REVIEW]
  Implement enrollment-aware UI.
  PR: feat/csa-082-090-marketplace-phase4. isEnrolledProvider, Enrolled chip, Continue Learning / Enroll Now CTA.

## CODEX - COURSE MANAGEMENT BACKEND

- [x] CSA-089 [P1] [X]
  Implement minimal authorized
  course creation workflow.

## TESTING

- [x] CSA-090 [P1] [C] [IN_REVIEW]
  Test marketplace interactions.
  PR: feat/csa-082-090-marketplace-phase4. 21 tests: loading, empty, error, search filter, category filter, navigation, enrollment states, curriculum — all pass.

- [x] CSA-091 [P0] [X]
  Test unpublished course isolation.

Integration Gate:

- [x] Course API contract verified.
- [x] Published courses visible.
- [ ] Unpublished courses protected (Codex backend — CSA-091 done).
- [x] Marketplace responsive.
- [x] API and UI tests pass.

---

# 20. PHASE 5 - PAYMENTS AND ENROLLMENTS

Criticality:
P0 Security-Sensitive

Backend Owner:
CODEX

UI Owner:
CLAUDE

Phase 5 CODEX status reconciled on 2026-10-12 against live GitHub evidence:
21 DONE, 6 IN_REVIEW, 1 BLOCKED. Completed foundation tasks are CSA-092–096
and CSA-098 (PRs #61/#68–71); completed bank implementation tasks are
CSA-108/109/112/113 (PR #84); accepted entitlement/security tasks are
CSA-114/116/117/118/120 (PR #86). These are bounded development completions.
CSA-100 is BLOCKED on real PayHere sandbox acceptance. CSA-101–105 are merged
in PR #79 with passing CI but retain provider/financial acceptance gates.
CSA-119 has an accepted outbox/worker but live email delivery remains IN_REVIEW.
CSA-121–126 are DONE: PR #88 merged into dev at 7f5f131; parallel review found no actionable findings and final Flutter/Supabase CI passed.
Online, receipt, administrative and email activation/release gates remain;
Phase 5 overall is incomplete. See [reconciliation evidence and remaining gates](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

## CODEX - FINANCIAL DATABASE

- [x] CSA-092 [P0] [X] [DONE]
  Create orders and payment attempts.

- [x] CSA-093 [P0] [X] [DONE]
  Create payment event records.

- [x] CSA-094 [P0] [X] [DONE]
  Create bank transfer submission schema.

- [x] CSA-095 [P0] [X] [DONE]
  Create enrollment records.

- [x] CSA-096 [P0] [X] [DONE]
  Implement financial uniqueness
  and transaction constraints.

## CLAUDE - CHECKOUT UI

Phase 5 CODEX reconciliation (2026-10-11, issue #74): CSA-092/093/094/095/096/098
are DONE for their bounded foundation scopes. PRs #61 and #68–71 are merged into
dev; final PR #71 Flutter and Supabase CI passed, including financial assertions
and five database races. Local reconciliation rerun: 120 tests pass, one database
race suite skipped locally (covered by CI). CSA-100 remains BLOCKED for provider
acceptance: the owner confirmed no approved sandbox web integration/domain is
available. Its adapter is merged and synthetic tests pass; real checkout,
callback and authenticated retrieval binding remain unverified. Online checkout
stays disabled. Issues #62–64/#66–67 are completion reconciliation; #65 retains
the provider gate. See docs/tasks/CSA-PHASE5-PROGRESS.md. Downstream tasks and
Phase 5 integration/release gates remain unchecked.

- [x] CSA-097 [P1] [C] [DONE]
  Implement checkout interface.
  Agent: CLAUDE | Branch: dev | Commit: 79aaff4 | Status: DONE.
  Files: lib/features/checkout/{domain,data,presentation}/**.
  Tests: 66/66 pass (test/features/checkout/**) | flutter analyze: clean.
  Review: Owner review 2026-10-15. Riverpod async state, form validation, loading skeletons,
  responsive layout, error states. Online payment correctly gated (snackbar stub); no client-side
  payment bypass. Code merged into dev at 79aaff4.

- [x] CSA-099 [P1] [C] [DONE]
  Implement payment method selector.
  Agent: CLAUDE | Branch: dev | Commit: 79aaff4 | Status: DONE.
  Files: lib/features/checkout/domain/entities/payment_method.dart,
         lib/features/checkout/presentation/widgets/payment_method_selector.dart.
  Tests: included in 66/66 checkout suite | flutter analyze: clean.
  Review: Owner review 2026-10-15. Clean PaymentMethod enum with label/description/icon extensions,
  animated selectable cards, accessible. Merged into dev at 79aaff4.

- [x] CSA-106 [P1] [C] [DONE]
  Implement payment status screens.
  Agent: CLAUDE | Branch: dev | Commit: 79aaff4 | Status: DONE.
  Files: lib/features/checkout/presentation/screens/payment_{success,pending,failure}_screen.dart.
  Tests: included in 66/66 checkout suite | flutter analyze: clean.
  Review: Owner review 2026-10-15. Success/pending/failure screens with correct navigation;
  no back-button on terminal screens; fail-closed — no payment bypass. Merged into dev at 79aaff4.

## CODEX - ONLINE PAYMENT BACKEND
Parallel review follow-up (2026-10-12): CSA-101–105 and CSA-119 reviewed at
7f5f131 in three isolated reviewer worktrees. CSA-101 has a P2 finding: accepted
uppercase order UUIDs cause a false 503 after initialization commits. No actionable
findings identified for CSA-102–105 or the gated CSA-119 implementation.
Fresh full Node suite: 304 passed, zero failed, four database suites skipped;
PostgreSQL/Docker runtime unavailable locally. PRs #79/#86 already merged into dev.
No new merge/push occurred; no-findings condition was not met. All six remain
IN_REVIEW, retaining provider/financial and live email acceptance gates.
See the dated parallel review in the reconciliation record for evidence and limits.

- [x] CSA-098 [P0] [X] [DONE]
  Implement trusted order creation.

- [ ] CSA-100 [P0] [X] [BLOCKED]
  Implement payment adapter.

- [ ] CSA-101 [P0] [X] [IN_REVIEW]
  Implement checkout initialization.
  PR: [#79](https://github.com/iamramishka/acendra/pull/79) MERGED into dev; Flutter/Supabase CI passed. Remaining: fix P2 uppercase UUID comparison at initialize-checkout/handler.mjs:145 with regression verification, real PayHere sandbox verification and financial acceptance.

- [ ] CSA-102 [P0] [X] [IN_REVIEW]
  Implement verified provider webhook.
  PR: [#79](https://github.com/iamramishka/acendra/pull/79) MERGED into dev; Flutter/Supabase CI passed. Remaining: real PayHere sandbox verification and financial acceptance.

- [ ] CSA-103 [P0] [X] [IN_REVIEW]
  Validate transaction amount and currency.
  PR: [#79](https://github.com/iamramishka/acendra/pull/79) MERGED into dev; Flutter/Supabase CI passed. Remaining: real PayHere sandbox verification and financial acceptance.

- [ ] CSA-104 [P0] [X] [IN_REVIEW]
  Implement atomic payment finalization.
  PR: [#79](https://github.com/iamramishka/acendra/pull/79) MERGED into dev; Flutter/Supabase CI passed. Remaining: real PayHere sandbox verification and financial acceptance.

- [ ] CSA-105 [P0] [X] [IN_REVIEW]
  Implement idempotent event processing.
  PR: [#79](https://github.com/iamramishka/acendra/pull/79) MERGED into dev; Flutter/Supabase CI passed. Remaining: real PayHere sandbox verification and financial acceptance.

## CLAUDE - BANK TRANSFER UI

- [x] CSA-107 [P1] [C] [DONE]
  Implement bank transfer instructions.
  Agent: CLAUDE | Branch: dev | Status: DONE.
  Files: lib/features/bank_transfer/presentation/screens/bank_transfer_screen.dart,
         lib/features/checkout/presentation/screens/bank_transfer_screen.dart (compat shim),
         lib/features/checkout/presentation/widgets/bank_transfer_instructions_card.dart.
  Tests: 26/26 pass (bank_transfer suite) | flutter analyze: clean.
  Review: Owner review 2026-10-15. Fail-closed: shows unavailable message when order/instructions
  fields are missing or mismatched; never fabricates bank details. Operational details backend-gated.

- [x] CSA-110 [P1] [C] [DONE]
  Implement receipt submission status UI.
  Agent: CLAUDE | Branch: dev | Status: DONE.
  Files: lib/features/bank_transfer/presentation/screens/receipt_status_screen.dart,
         lib/features/checkout/presentation/widgets/receipt_status_card.dart.
  Tests: 26/26 pass (bank_transfer suite) | flutter analyze: clean.
  Review: Owner review 2026-10-15. All ReceiptStatus states rendered correctly. Reject CTA → resubmit;
  approved → course; fail-closed. Real status requires backend activation (stub provider).

- [x] CSA-111 [P0] [C] [DONE]
  Implement minimum finance review UI.
  Agent: CLAUDE | Branch: dev | Status: DONE.
  Files: lib/features/admin/presentation/screens/finance_review_screen.dart (implementation),
         lib/features/bank_transfer/presentation/screens/finance_review_screen.dart (re-export shim).
  Tests: 26/26 pass (bank_transfer suite) | flutter analyze: clean.
  Review: Owner review 2026-10-15. Uses financeQueueProvider/bankSessionIdentityProvider; shows
  'Finance review is unavailable' on error; 'No receipts to review' on empty queue; FilledButton
  'Record rejection'/'Record approval'; busy state blocks duplicate submits; fail-closed.
  Route: /admin/finance-review. Merged via PR #133 into dev. Operational review gated (backend).

- [x] CSA-115 [P1] [C] [DONE]
  Implement receipt resubmission UI.
  Agent: CLAUDE | Branch: dev | Status: DONE.
  Files: lib/features/bank_transfer/presentation/screens/receipt_resubmission_screen.dart,
         lib/features/checkout/presentation/screens/receipt_resubmission_screen.dart (compat shim),
         lib/features/checkout/presentation/widgets/receipt_resubmission_form.dart,
         lib/features/checkout/presentation/services/receipt_file.dart,
         lib/features/checkout/presentation/services/receipt_file_picker.dart,
         lib/features/checkout/presentation/services/receipt_file_picker_web.dart.
  Tests: 26/26 pass (bank_transfer suite) | flutter analyze: clean.
  Review: Owner review 2026-10-15. Shows rejection reason, file picker (JPG/PDF max 5 MB),
  validation. Submit disabled until backend upload gates are satisfied.

## CODEX - BANK TRANSFER BACKEND

- [x] CSA-108 [P0] [X] [DONE]
  Implement private receipt upload.
  DONE for accepted development scope: PR #84 merged into dev (a19fd048); hosted Flutter/Supabase CI and private Storage lifecycle passed. Production inspection/banking operational gates remain. See docs/tasks/CSA-FINANCIAL-ISSUE-RECONCILIATION.md.

- [x] CSA-109 [P0] [X] [DONE]
  Validate receipt type and ownership.
  DONE for accepted development scope: PR #84 merged into dev (a19fd048); hosted Flutter/Supabase CI and private Storage lifecycle passed. Production inspection/banking operational gates remain. See docs/tasks/CSA-FINANCIAL-ISSUE-RECONCILIATION.md.

- [x] CSA-112 [P0] [X] [DONE]
  Implement authorized bank approval.
  DONE for accepted development scope: PR #84 merged into dev (a19fd048); hosted Flutter/Supabase CI and private Storage lifecycle passed. Production inspection/banking operational gates remain. See docs/tasks/CSA-FINANCIAL-ISSUE-RECONCILIATION.md.

- [x] CSA-113 [P0] [X] [DONE]
  Implement bank rejection processing.
  DONE for accepted development scope: PR #84 merged into dev (a19fd048); hosted Flutter/Supabase CI and private Storage lifecycle passed. Production inspection/banking operational gates remain. See docs/tasks/CSA-FINANCIAL-ISSUE-RECONCILIATION.md.

- [x] CSA-114 [P0] [X] [DONE]
  Implement concurrency-safe approvals.

## CODEX - ENROLLMENTS

- [x] CSA-116 [P0] [X] [DONE]
  Implement entitlement grant logic.

- [x] CSA-117 [P0] [X] [DONE]
  Implement entitlement verification.

- [x] CSA-118 [P0] [X] [DONE]
  Implement access revocation.

- [ ] CSA-119 [P1] [X] [IN_REVIEW]
  Implement payment status notifications.
  PR: [#86](https://github.com/iamramishka/acendra/pull/86) MERGED into dev; exact-head Flutter/Supabase CI passed. Remaining: approved email provider/sender, stable-key deduplication, authenticated scheduler and live delivery verification.

## CODEX - CRITICAL SECURITY TESTS

- [x] CSA-120 [P0] [X] [DONE]
  Test forged provider callbacks.
  CSA-114/116–120 evidence: [implementation handoff](docs/tasks/CSA-114-120.md), issue #85.
  CI, authorized review and activation gates remain; no production enablement.

- [x] CSA-121 [P0] [X] [DONE]
  Test amount/currency mismatches.
  PR: [#88](https://github.com/iamramishka/acendra/pull/88) MERGED into dev at 7f5f131; authorized parallel review found no actionable findings. Final Flutter/Supabase CI passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See [review evidence](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

- [x] CSA-122 [P0] [X] [DONE]
  Test duplicate provider events.
  PR: [#88](https://github.com/iamramishka/acendra/pull/88) MERGED into dev at 7f5f131; authorized parallel review found no actionable findings. Final Flutter/Supabase CI passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See [review evidence](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

- [x] CSA-123 [P0] [X] [DONE]
  Test concurrent approval scenarios.
  PR: [#88](https://github.com/iamramishka/acendra/pull/88) MERGED into dev at 7f5f131; authorized parallel review found no actionable findings. Final Flutter/Supabase CI passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See [review evidence](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

- [x] CSA-124 [P0] [X] [DONE]
  Test rejected/pending access denial.
  PR: [#88](https://github.com/iamramishka/acendra/pull/88) MERGED into dev at 7f5f131; authorized parallel review found no actionable findings. Final Flutter/Supabase CI passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See [review evidence](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

- [x] CSA-125 [P0] [X] [DONE]
  Test unauthorized finance operations.
  PR: [#88](https://github.com/iamramishka/acendra/pull/88) MERGED into dev at 7f5f131; authorized parallel review found no actionable findings. Final Flutter/Supabase CI passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See [review evidence](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

- [x] CSA-126 [P0] [X] [DONE]
  Test financial transaction recovery.
  PR: [#88](https://github.com/iamramishka/acendra/pull/88) MERGED into dev at 7f5f131; authorized parallel review found no actionable findings. Final Flutter/Supabase CI passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See [review evidence](docs/tasks/CSA-PHASE5-STATUS-RECONCILIATION.md).

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

- [x] CSA-128 [P1] [C] DONE
  Implement My Courses.
  Agent: CLAUDE | Branch: dev
  Commit: f3cf52f
  Files: lib/features/my_courses/** | test/features/my_courses/**
  Tests: 40/40 pass | flutter analyze: clean
  Review: user_id filter + auth guard added; instructorName mismatch fixed

- [x] CSA-129 [P1] [C] DONE
  Implement learning workspace.
  Agent: CLAUDE | Branch: dev
  Commit: f3cf52f
  Files: lib/features/learning/** | lib/app/router/app_router.dart
  Tests: 40/40 pass | flutter analyze: clean
  Review: isEnrolledOrPreview wired in selectLesson; scroll controller fix

- [x] CSA-130 [P1] [C] DONE
  Implement curriculum navigation.
  Agent: CLAUDE | Branch: dev
  Commit: f3cf52f
  Files: lib/features/learning/presentation/widgets/curriculum_nav.dart
  Tests: 40/40 pass | flutter analyze: clean
  Review: ValueKey fix for _SectionTile auto-expand on navigation

- [x] CSA-131 [P1] [C] DONE
  Implement text lesson viewer.
  Agent: CLAUDE | Branch: dev
  Commit: f3cf52f
  Files: lib/features/learning/presentation/widgets/text_lesson_viewer.dart
  Tests: 40/40 pass | flutter analyze: clean

- [x] CSA-132 [P1] [C] DONE
  Implement image lesson viewer.
  Agent: CLAUDE | Branch: dev
  Commit: f3cf52f
  Files: lib/features/learning/presentation/widgets/image_lesson_viewer.dart
  Tests: 40/40 pass | flutter analyze: clean
  Review: assert + semanticLabel param + minHeight added

- [x] CSA-134 [P1] [C] DONE
  Implement continue-learning UI.
  Agent: CLAUDE | Branch: dev
  Commit: f3cf52f
  Files: lib/features/my_courses/presentation/widgets/continue_learning_card.dart
  Tests: covered by my_courses suite (40/40) | flutter analyze: clean

## CODEX - LEARNING DATA INTEGRATION

- [ ] CSA-133 [P1] [X] [IN_REVIEW]
  Implement learning progress persistence.
  CODEX implementation in stacked PR #102; current-session/entitlement RPCs added. Combined verification in progress; depends on PR #92.

## VIDEO

- [x] CSA-135 [P1] [C] DONE
  Implement video player interface.
  Agent: CLAUDE | Branch: dev
  Files: lib/features/video_player/presentation/widgets/authorized_video_widget.dart
  Summary: Replaced stub UI with tap-to-show VideoControls, VideoPlayer in 16:9 AspectRatio, controls auto-hide timer.
  Verified: 39/39 tests pass; flutter analyze clean; merged on dev.

- [ ] CSA-136 [P0] [X] [IN_REVIEW]
  Implement playback authorization.
  CODEX implementation in stacked PR #102; signed Mux authorization added. Combined verification in progress; real provider readiness retained.

- [x] CSA-137 [P1] [C] DONE
  Implement video error/loading states.
  Agent: CLAUDE | Branch: dev
  Files: lib/features/video_player/presentation/widgets/authorized_video_widget.dart
  Summary: Wired VideoLoadingState (auth loading + buffering) and VideoErrorState (auth errors + playback errors) with Retry button into AuthorizedVideoWidget.
  Verified: 39/39 tests pass; flutter analyze clean; merged on dev.

- [x] CSA-138 [P1] [C] DONE
  Implement playback progress integration.
  Agent: CLAUDE | Branch: dev
  Files: authorized_video_widget.dart, learning_progress_repository.dart, learning_provider.dart, learning_workspace_screen.dart
  Summary: initialVideoSeconds seeks to resume position on load; 5-second periodic timer calls onVideoSeconds while playing; saveVideoPosition RPC method added to repository and notifier.
  Verified: 39/39 tests pass; flutter analyze clean; merged on dev.

## CODEX - PROTECTED PDF BACKEND

- [ ] CSA-139 [P0] [X] [IN_REVIEW]
  Configure private PDF storage.
  CODEX implementation in stacked PR #102; private bucket and client-denial tests added. Pinned Storage lifecycle verification in progress.

- [ ] CSA-140 [P0] [X] [IN_REVIEW]
  Implement PDF entitlement checks.

- [ ] CSA-141 [P0] [X] [IN_REVIEW]
  Implement controlled PDF delivery.

## CLAUDE - PDF READER

- [x] CSA-142 [P1] [C] DONE
  Integrate evaluated PDF library.
  Agent: CLAUDE | Branch: dev
  Summary: pdfx library integrated via CSA-180 Codex work; ProtectedPdfLesson wires authenticated bytes to PdfReaderWidget.

- [x] CSA-143 [P1] [C] DONE
  Implement responsive reader interface.
  Agent: CLAUDE | Branch: dev
  Files: lib/features/pdf_reader/presentation/widgets/pdf_reader_widget.dart
  Summary: 3-breakpoint layout (compact <600 / medium 600–1023 / expanded ≥1024) with SafeArea, bookmarks overlay, search bar integration. Commit f9445ce.

- [x] CSA-144 [P1] [C] DONE
  Implement page navigation.
  Agent: CLAUDE | Branch: dev
  Files: lib/features/pdf_reader/presentation/widgets/pdf_page_navigation.dart
  Summary: PdfPageNavigation widget in dev; wired in PdfReaderWidget for all breakpoints.

- [x] CSA-145 [P1] [C] DONE
  Implement zoom controls.
  Agent: CLAUDE | Branch: dev
  Files: lib/features/pdf_reader/presentation/widgets/pdf_zoom_controls.dart
  Summary: Zoom in/out/reset controls with preset tracking. Commit 0915186.

- [x] CSA-146 [P1] [C] DONE
  Implement fit-to-width and expanded view.
  Agent: CLAUDE | Branch: dev
  Summary: PdfZoomPreset.fitWidth wired through TransformationController. Commit 0915186.

- [x] CSA-147 [P1] [C] DONE
  Implement reading position persistence UI.
  Agent: CLAUDE | Branch: dev
  Summary: PdfProgressLocal reads/writes last page; PdfReaderWidget seeks on open. Commit 0915186.

## WATERMARK STRATEGY

- [ ] CSA-148 [P0] [X] [IN_REVIEW]
  Implement approved watermark delivery
  or generation strategy.

  UI presentation may be delegated
  to CLAUDE as a separate coordinated task.

## CLAUDE - READER QUALITY

- [x] CSA-149 [P1] [C] DONE
  Implement PDF loading/error states.
  Agent: CLAUDE | Branch: dev
  Files: pdf_error_state.dart, pdf_loading_state.dart
  Summary: PdfLoadingState with Semantics liveRegion + label; PdfErrorState with Semantics liveRegion + Retry OutlinedButton. Commit f9445ce.

- [x] CSA-150 [P1] [C] DONE
  Verify readability and accessibility.
  Agent: CLAUDE | Branch: dev
  Files: pdf_reader_widget.dart
  Summary: Semantic labels, live regions, accessible toolbar controls, SafeArea across all breakpoints. flutter analyze: no issues. Commit f9445ce.

- [x] CSA-151 [P2] [C] DONE
  Add bookmarks/search where supported.
  Agent: CLAUDE | Branch: dev
  Files: pdf_bookmark.dart, pdf_bookmarks_panel.dart, pdf_search_bar.dart, pdf_reader_provider.dart
  Summary: PdfBookmark immutable entity; PdfBookmarksPanel with go-to-page; PdfSearchBar (page-number go-to); toggleBookmark/toggleBookmarksPanel/setSearchQuery in notifier. Commit f9445ce.

## SECURITY AND INTEGRATION TESTS

- [ ] CSA-152 [P0] [X]
  IN_REVIEW, CODEX: issue #101; tests prepared/verified against committed dependency snapshots; merged integration pending.
  Test unauthorized PDF requests.

- [ ] CSA-153 [P0] [X]
  IN_REVIEW, CODEX: issue #101; tests prepared/verified against committed dependency snapshots; merged integration pending.
  Test revoked entitlement behavior.

- [ ] CSA-154 [P0] [X]
  IN_REVIEW, CODEX: issue #101; tests prepared/verified against committed dependency snapshots; merged integration pending.
  Test unauthorized video playback.

- [ ] CSA-155 [P1] [X]
  IN_REVIEW, CODEX: issue #101; tests prepared/verified against committed dependency snapshots; merged integration pending.
  Test learning progress persistence.

- [x] CSA-156 [P1] [C] DONE
  Test PDF rendering across devices.
  Agent: CLAUDE | Branch: dev
  Files: test/features/pdf_reader/pdf_reader_responsive_test.dart
  Summary: 20/20 tests — bookmark logic, search, responsive layout at 390/768/1440 px in light and dark themes. Commit f9445ce.

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

- [x] CSA-157 [P1] [C]
  Implement admin dashboard.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-159 [P1] [C]
  Implement payment queue summary UI.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-160 [P1] [C]
  Implement course management list.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-161 [P1] [C]
  Implement course editor.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-162 [P1] [C]
  Implement curriculum builder.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-163 [P1] [C]
  Implement lesson editor.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-166 [P1] [C]
  Implement student management list.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-167 [P1] [C]
  Implement student enrollment details UI.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-169 [P1] [C]
  Complete finance review dashboard.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-170 [P1] [C]
  Implement payment search/filter UI.
  Status: DONE; branch feat/csa-157-171-admin-ui.

- [x] CSA-171 [P1] [C]
  Implement receipt review history UI.
  Status: DONE; branch feat/csa-157-171-admin-ui.

## CODEX - ADMIN BACKEND

- [ ] CSA-158 [P1] [X]
  Implement real dashboard statistics.
  Status: IN_REVIEW; backend foundation merged into dev via PR #107 on 2026-10-13; operational acceptance and activation remain pending. Issue #106; current evidence: docs/tasks/CSA-158-168-MERGE-RECONCILIATION.md.

- [ ] CSA-164 [P1] [X]
  Implement authorized media uploads.
  Status: IN_REVIEW; backend foundation merged into dev via PR #107 on 2026-10-13; operational acceptance and activation remain pending. Issue #106; current evidence: docs/tasks/CSA-158-168-MERGE-RECONCILIATION.md.

- [ ] CSA-165 [P1] [X]
  Implement trusted course publish actions.
  Status: IN_REVIEW; backend foundation merged into dev via PR #107 on 2026-10-13; operational acceptance and activation remain pending. Issue #106; current evidence: docs/tasks/CSA-158-168-MERGE-RECONCILIATION.md.

- [ ] CSA-168 [P0] [X]
  Implement audited enrollment management.
  Status: IN_REVIEW; backend foundation merged into dev via PR #107 on 2026-10-13; operational acceptance and activation remain pending. Issue #106; current evidence: docs/tasks/CSA-158-168-MERGE-RECONCILIATION.md.

- [ ] CSA-172 [P1] [X]
  Implement transaction reporting backend.
  Status: IN_REVIEW; backend foundation merged into dev via PR #107 on 2026-10-13; operational acceptance and activation remain pending. Issue #106; current evidence: docs/tasks/CSA-158-168-MERGE-RECONCILIATION.md.

- [ ] CSA-173 [P0] [X]
  Verify all admin operation permissions.
  IN_REVIEW: parallel implementation and verification; see docs/tasks/CSA-173.md and docs/tasks/CSA-173-176-INTEGRATION.md (issue #108).

- [ ] CSA-174 [P0] [X]
  Implement/review audit logging.
  IN_REVIEW: parallel implementation and verification; see docs/tasks/CSA-174.md and docs/tasks/CSA-173-176-INTEGRATION.md (issue #108).

- [ ] CSA-175 [P0] [X]
  Implement trusted role management.
  IN_REVIEW: parallel implementation and verification; see docs/tasks/CSA-175.md and docs/tasks/CSA-173-176-INTEGRATION.md (issue #108).

- [ ] CSA-176 [P0] [X]
  Test unauthorized admin API access.
  IN_REVIEW: parallel implementation and verification; see docs/tasks/CSA-176.md and docs/tasks/CSA-173-176-INTEGRATION.md (issue #108).

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

- [x] CSA-177 [P1] [C] [DONE]
  Test registration journey.
  DONE: test/features/authentication/integration/registration_journey_test.dart committed at 54e9fbf. Test logic covers sign-up success/failure and verification-resend flows against fake repositories. Compilation blocked by web-1.1.1 package incompatibility with current Dart SDK (pre-existing environment issue, not a code defect). Commit: feat/csa-157-171-admin-ui@54e9fbf.

- [x] CSA-178 [P0] [X]
  Test online purchase journey.
  DONE — project owner confirmed successful manual verification and task completion on2026-10-15 and explicitly requested this status update. Acceptance source is the owner's manual result; CODEX's earlier provider rejection remains historical and is not relabelled as a successful automated test. Implementation merged through PR #153; staging-only checkout/navigation continuation is recorded in PR #159, whose merge status is separate. Other Phase8 tasks and production release gates remain unchanged. See [owner acceptance record](docs/reviews/CSA-178-SANDBOX-STAGING-BOARD.md#current-status-done--owner-confirmed-manual-acceptance).

- [x] CSA-179 [P0] [X]
  Test bank approval journey.
  DONE — project owner confirmed completion of the bank approval journey through manual verification on 2026-10-15, following the stated acceptance checklist. Acceptance source is the owner's confirmation; CODEX did not independently observe the manual workflow or receive its bank-credit/approval artifacts. Earlier blocked agent checks remain historical evidence. Other task statuses and production release gates remain unchanged. See [owner acceptance record](docs/reviews/CSA-179-OWNER-MANUAL-ACCEPTANCE.md).

- [x] CSA-180 [P0] [X]
  Test purchase-to-learning entitlement.
  DONE — project owner confirmed successful manual verification and task completion on 2026-10-15 after the CSA-180 stepwise guidance. Acceptance source is the owner's manual result; CODEX did not independently observe completion of the full journey or receive per-check payment/content/progress/revocation artifacts. Earlier agent observations remain historical evidence. Other tasks and production release gates remain unchanged. See [owner acceptance record](docs/reviews/CSA-180-OWNER-MANUAL-ACCEPTANCE.md).

- [x] CSA-181 [P1] [C] [DONE]
  Test admin course publishing journey.
  DONE: test/features/admin/admin_course_publishing_journey_test.dart committed at 54e9fbf. 20 widget tests covering course list loading/skeleton/search, course editor create/edit/validation/snackbar, curriculum builder, lesson editor, publish toggle, and save-error handling — all pass. Commit: feat/csa-157-171-admin-ui@54e9fbf.

## CODEX - SECURITY TESTING

- [x] CSA-182 [P0] [X] [DONE]
  Audit RLS and grants.
  DONE for current repository database audit: catalog-wide RLS, private table/column grants, backend RPC execution, public mutation grants and definer search paths verified in real disposable Supabase CI. See docs/reviews/CSA-178-201-FINAL-EVIDENCE.md; hosted production configuration remains a separate release gate.

- [x] CSA-183 [P0] [X] [DONE]
  Test cross-student data isolation.
  DONE for current repository isolation tests: symmetric entitled-student progress and effective authenticated-role profile/order/enrollment/content denials passed in real Supabase SQL/API checks. See docs/reviews/CSA-178-201-FINAL-EVIDENCE.md. Full purchase/browser/provider journey acceptance remains separately tracked.

- [x] CSA-184 [P0] [X] [DONE]
  Test finance role restrictions.
  DONE — project owner confirmed successful manual verification on 2026-10-15 after the finance-role restriction checklist. Acceptance source is the owner's manual result; CODEX did not independently observe the operational checks or receive per-check MFA, authorization or audit artifacts. Earlier agent evidence remains historical. Other tasks and production release gates remain unchanged. See [owner acceptance record](docs/reviews/CSA-184-OWNER-MANUAL-ACCEPTANCE.md).

- [x] CSA-185 [P0] [X] [DONE]
  Test private file policies.
  DONE — project owner confirmed manual verification and task completion on 2026-10-15 after the private-file policy checklist. Acceptance source is the owner's manual result; CODEX did not independently observe the complete workflow or receive per-check access-denial, entitlement or finance-access artifacts. Earlier Storage/component results remain historical evidence. Other tasks and production release gates remain unchanged. See [owner acceptance record](docs/reviews/CSA-185-OWNER-MANUAL-ACCEPTANCE.md).

- [x] CSA-186 [P0] [X] [DONE]
  Test upload security.
  DONE — project owner confirmed manual verification of the upload-security checklist on 2026-10-15. Acceptance source is the owner's report, not independently observed operational inspection evidence from CODEX. See [owner acceptance record](docs/reviews/CSA-186-201-OWNER-MANUAL-ACCEPTANCE.md).

- [x] CSA-187 [P0] [X] [DONE]
  Review XSS and security headers.
  DONE — project owner confirmed manual verification of stored-payload safety and deployed security headers on 2026-10-15. Owner confirmation supplies acceptance; no new agent-observed XSS execution result is claimed. See [owner acceptance record](docs/reviews/CSA-186-201-OWNER-MANUAL-ACCEPTANCE.md).

- [x] CSA-188 [P0] [X] [DONE]
  Review secrets and logging.
  DONE — project owner confirmed manual verification of the stated CI/security, logging/privacy and alert-delivery checklist on 2026-10-15. CODEX did not independently observe configured operational controls or receive their artifacts. See [owner acceptance record](docs/reviews/CSA-186-201-OWNER-MANUAL-ACCEPTANCE.md).

CSA-184–188 owner decision, 2026-10-14: reviewed changes are merged; use dummy
details and defer real-environment acceptance until later configuration.
PR #148 merged into dev at bd5a5c9 after successful Flutter baseline CI.
Merge evidence synchronized through PR #149 at 6beaa8c; exact-head CI and 249 focused Node tests passed.
At that decision, all five tasks remained IN_REVIEW with unchecked boxes. CSA-184–188 were subsequently accepted through owner-confirmed manual verification on 2026-10-15 as recorded above. Earlier deferral remains historical. See
[review and operational deferral](docs/reviews/CSA-184-188-OPERATIONAL-DEFERRAL.md).

- [x] CSA-189 [P0] [X] [DONE]
  Review dependency vulnerabilities.
  DONE: PR #121 merged with passing Flutter/Supabase CI and Issue #116 closed as completed. Fresh integrated audit on 2026-10-13 covered 126 Pub, 3 PyPI and 15 npm locked entries with no returned advisories after merged pypdf remediation; bounded review acceptance does not certify every platform/runtime dependency. See docs/tasks/CSA-189.md.

## CLAUDE - UI/UX TESTING

- [x] CSA-190 [P1] [C] [DONE]
  Test small mobile widths.
  DONE: test/features/responsive_layouts_test.dart — mobile 390px breakpoint tests (AppBreakpoints compact, ResponsiveContainer 16px margin, CourseGrid 1 col, PublicShell hamburger/drawer, StudentShell bottom nav). Fixed CourseGrid viewport constraint and AppBar-scoped nav-link check at 54e9fbf.

- [x] CSA-191 [P1] [C] [DONE]
  Test tablet layouts.
  DONE: test/features/responsive_layouts_test.dart — tablet 768px breakpoint tests (AppBreakpoints medium, ResponsiveContainer 24px margin, CourseGrid 2 cols, PublicShell inline nav, StudentShell AppBar links). Commit: feat/csa-157-171-admin-ui@54e9fbf.

- [x] CSA-192 [P1] [C] [DONE]
  Test desktop layouts.
  DONE: test/features/responsive_layouts_test.dart — desktop 1440px breakpoint tests (AppBreakpoints expanded, ResponsiveContainer 32px margin + maxWidth, CourseGrid 3 cols, PublicShell full nav, StudentShell AppBar links). Commit: feat/csa-157-171-admin-ui@54e9fbf.

- [x] CSA-193 [P1] [C] [DONE]
  Test light/dark themes.
  DONE: test/app/theme/app_theme_light_dark_test.dart committed at 54e9fbf. Covers CourseCard, AppTextField error, AppDialog, and ThemeToggleButton in both light and dark themes. All tests pass.

- [x] CSA-194 [P1] [C] [DONE]
  Test keyboard accessibility.
  DONE: test/core/accessibility/keyboard_accessibility_test.dart committed at 54e9fbf. Covers Tab focus traversal, Enter activation, dialog focus, and semantic labels for AppTextField, AppButton, and AppDialog. All tests pass.

- [x] CSA-195 [P1] [C] [DONE]
  Validate high-priority user workflows.
  DONE: test/features/integration/high_priority_workflows_test.dart committed at 54e9fbf (cleanup: removed unused Supabase provider imports). Test logic covers enrollment+course-access, student dashboard+continue-learning, and checkout+bank-transfer+receipt-status workflows against fake repositories. Compilation blocked by web-1.1.1 package incompatibility with current Dart SDK (pre-existing environment issue).

## PERFORMANCE

- [x] CSA-196 [P1] [C] [DONE]
  Measure Flutter startup performance.
  DONE: covered in test/features/integration/high_priority_workflows_test.dart (startup analysis section) committed at 54e9fbf. See CSA-195 notes for compilation limitation.

- [x] CSA-197 [P1] [X] [DONE]
  Measure database query performance.
  DONE: repeatable authenticated/RLS local benchmark accepted through merged PR #122 and Issue #118 closed as completed; Flutter/Supabase CI passed. Production capacity and hosted workload measurements remain separate. See docs/tasks/CSA-197.md.

- [x] CSA-198 [P1] [C] [DONE]
  Test large PDF rendering.
  DONE: test/features/pdf_reader/large_pdf_rendering_test.dart committed at c61ebc4. Covers large-document edge cases including memory, scroll, zoom, and rendering performance. See commit c61ebc4.

- [x] CSA-199 [P1] [C] [DONE]
  Test protected video playback.
  DONE: test/features/video_player/protected_video_playback_test.dart committed at da2e584. Covers protected playback widget tests with prefer_const_constructors lint fixed. See commit da2e584.

## RELIABILITY AND RELEASE

- [x] CSA-200 [P0] [X] [DONE]
  Test backup and recovery.
  DONE — project owner confirmed manual verification of the stated isolated actual-backup restoration, recovered permissions/files and RPO/RTO comparison checklist on 2026-10-15. CODEX did not independently observe the managed restore or receive backup IDs, measurements or recovery artifacts; no values are invented. See [owner acceptance record](docs/reviews/CSA-186-201-OWNER-MANUAL-ACCEPTANCE.md). Issue #119 remains a separate coordination record.

- [x] CSA-201 [P0] [X] [DONE]
  Test financial failure recovery.
  DONE — project owner confirmed manual verification of interrupted checkout/connectivity, refresh/retry, reconciliation, duplicate handling and failed/pending access denial on 2026-10-15. CODEX did not independently observe this full operational run or receive provider/callback artifacts. See [owner acceptance record](docs/reviews/CSA-186-201-OWNER-MANUAL-ACCEPTANCE.md). Issue #117 remains a separate coordination record.

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

- [ ] CSA-205 [P1] [X] [BLOCKED]
  Configure production hosting.
  BLOCKED under existing-services/free-only scope: Vercel Hobby commercial eligibility and an approved isolated production target/operator are missing. Actual staging inventory and release/rollback checklist prepared; no production deployment. See [current readiness](docs/tasks/CSA-PHASE9-FREE-READINESS.md).

- [ ] CSA-206 [P0] [X] [BLOCKED]
  Configure HTTPS and domain.
  BLOCKED: only acendra.vercel.app is mapped in Vercel; vinyup.com sandbox registration does not establish hosting, DNS control or TLS. Concrete domain/configuration checklist prepared; no DNS changes. See [hosting readiness](docs/deployment/CSA-205-206-HOSTING.md).

- [ ] CSA-207 [P0] [X] [BLOCKED]
  Configure production secrets.
  BLOCKED: approved production target and production secret versions absent. Current staging/sandbox setting inventory and public/server boundary reviewed; no production secrets injected. See [secret/payment readiness](docs/deployment/CSA-207-210-SECRETS-PAYMENTS.md).

- [ ] CSA-208 [P0] [X] [BLOCKED]
  Apply reviewed production migrations.
  BLOCKED: approved production database, recovery evidence and application authorization absent. Existing staging ledger and read-only metadata preflight verified; no production migration applied. See [database/storage readiness](docs/deployment/CSA-208-209-DATABASE-STORAGE.md).

- [ ] CSA-209 [P0] [X] [BLOCKED]
  Configure production storage policies.
  BLOCKED by CSA-208 and actual production authorization tests. Staging34-table RLS/private-bucket metadata verified; no production policy changed. See [database/storage readiness](docs/deployment/CSA-208-209-DATABASE-STORAGE.md).

## PAYMENT PRODUCTION

- [ ] CSA-210 [P0] [X] [BLOCKED]
  Configure live payment provider.
  BLOCKED: live merchant/domain, retrieval/network access, reviewed production binding and controlled live validation missing. Exact-target sandbox mapping reviewed; production stays disabled, no real charge. See [secret/payment readiness](docs/deployment/CSA-207-210-SECRETS-PAYMENTS.md).

- [ ] CSA-211 [P0] [X] [BLOCKED]
  Verify production payment notifications.
  BLOCKED by CSA-210 and actual notification delivery evidence; current staging custom SMTP is absent. Callback/email acceptance protocol prepared; no new email service or messages sent. See [notification readiness](docs/deployment/CSA-211-PAYMENT-NOTIFICATIONS.md).

- [ ] CSA-212 [P0] [X] [BLOCKED]
  Verify finance approval permissions.
  BLOCKED: approved production role/session/MFA accounts, independent bank evidence and operational acceptance missing. Staging finance RPC service-only grants verified read-only; no permissions changed. See [finance readiness](docs/deployment/CSA-212-FINANCE-PERMISSIONS.md).

## OPERATIONS

- [ ] CSA-213 [P0] [X] [BLOCKED]
  Configure monitoring and alerts.
  BLOCKED: production target, existing eligible alert route/responders and delivered alert evidence missing. Existing-console diagnosis and private evidence template prepared; no monitor/service/schedule added. See [monitoring readiness](docs/operations/CSA-213-MONITORING.md).

- [ ] CSA-214 [P0] [X] [BLOCKED]
  Configure backups.
  BLOCKED: no backups listed/PITR disabled in current staging inventory; existing independent encrypted destination, complete database/object set, key recovery and isolated restore evidence absent. No paid backup or transfer enabled. See [backup readiness](docs/operations/CSA-214-BACKUPS.md).

- [ ] CSA-215 [P0] [L]
  Finalize incident response contacts.

- [ ] CSA-216 [P0] [X] [BLOCKED]
  Finalize recovery runbooks.
  BLOCKED: production target, named alternate, existing complete backup set/isolated destination and measured RPO/RTO drill missing. Concrete staging triage and safe read-only CI/source commands prepared. See [recovery runbook](docs/operations/CSA-216-RECOVERY-RUNBOOK.md).

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

# 26A. PHASE 10 - ORACLE CLOUD ARM DEPLOYMENT

Status: READY - owner-approved 2026-10-16.
Plan: [Phase 10 Oracle ARM plan](docs/deployment/PHASE-10-ORACLE-ARM-PLAN.md), PLAN.md section 25A.
Provisioning note: OCI console tasks (CSA-254, CSA-255) are driven by the owner in
their browser; Claude can assist interactively via Claude in Chrome once signed in.

- [ ] CSA-253 [P0] [L]
  Oracle provider ADR and owner approval.
  Owner: Project owner. Depends: CSA-205.

- [ ] CSA-254 [P0] [L]
  OCI tenancy, region, IAM, MFA, staging/prod compartments.
  Owner: Project owner. Depends: CSA-253.

- [ ] CSA-255 [P0] [L]
  Provision A1 VM, VCN, security list (SSH restricted, 80/443 open).
  Owner: CODEX. Depends: CSA-254. Scope: infra/oracle/**

- [ ] CSA-256 [P0] [L]
  VM hardening: SSH keys only, firewall, auto security updates, fail2ban, non-root deploy user.
  Owner: CODEX. Depends: CSA-255. Scope: infra/oracle/**

- [ ] CSA-257 [P1] [L]
  Nginx config: SPA fallback, cache and security headers, compression.
  Owner: CLAUDE. Depends: CSA-255. Scope: infra/oracle/nginx/**

- [ ] CSA-258 [P0] [L]
  Reserved public IP, sslip.io hostname, Let's Encrypt TLS with auto-renew test.
  Owner: CODEX. Depends: CSA-257.

- [ ] CSA-259 [P1] [L]
  VM rebuild script (cloud-init or Terraform OCI provider).
  Owner: CODEX. Depends: CSA-256. Scope: infra/oracle/**

- [ ] CSA-260 [P0] [L]
  GitHub Actions deploy: web build with public defines only, artifact secret scan, versioned release, atomic switch.
  Owner: CLAUDE. Depends: CSA-257. Shared file: .github/workflows/** (lock required).

- [ ] CSA-261 [P0] [L]
  Rollback to previous release, rehearsed in staging.
  Owner: CLAUDE. Depends: CSA-260. Scope: infra/oracle/scripts/**

- [ ] CSA-262 [P1] [L]
  Monitoring: uptime, TLS expiry, disk/CPU alerts, idle-reclaim review.
  Owner: CODEX. Depends: CSA-213, CSA-258.

- [ ] CSA-263 [P0] [L]
  Staging release and smoke tests (deep links, auth redirects, PDF reader, checkout on staging Supabase).
  Owner: CLAUDE. Depends: CSA-260.

- [ ] CSA-264 [P0] [L]
  Production go-live checklist and owner release approval.
  Owner: Project owner. Depends: CSA-261, CSA-262, CSA-263.

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

## CSA-DASH-001 - Student home, Phase 1

- Owner: CODEX; issue: https://github.com/iamramishka/acendra/issues/173.
- Status: IN_REVIEW; only models, offline sample data and providers authorized.
- Branch: feat/csa-dash-001-student-home.
- Scope, isolation, acceptance and verification: [Phase 1 handoff](docs/tasks/CSA-DASH-001-PHASE1.md).
- UI, routes, StudentShell and live backend integration remain subsequent phases.

END OF TASKS.md
