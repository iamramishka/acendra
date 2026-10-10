
# PARALLEL_WORKFLOW.md
# Acedra - Claude and Codex Parallel Development Workflow

Document ID: CSA-PARALLEL-001
Version: 1.0
Status: Proposed - Pending Approval
Project: Acedra Course Selling Application
Primary Platform: Flutter Web
Backend: Supabase + PostgreSQL
Development Model: Coordinated Multi-Agent Engineering

AI Agents:
- Claude Code
- OpenAI Codex

Coordination Platform:
- GitHub Issues
- GitHub Pull Requests
- GitHub Actions

Isolation:
- Git Worktrees
- Independent Git Branches
- Separate Test Environments

Development Method:
- Specification-First
- Test-Driven Development
- Continuous Integration
- Security by Design

---

# 1. PURPOSE

This document defines how Claude Code
and OpenAI Codex work together safely
on the Acedra application.

The project uses parallel development
to improve productivity while preserving:

- Code correctness
- Financial integrity
- Student privacy
- Security
- Architecture consistency
- Reliable testing
- Clean Git history
- Maintainable source code
- Predictable integration

Claude and Codex may work simultaneously.

However, parallel development must be:

- Planned
- Authorized
- Independent where possible
- Coordinated where necessary
- Tested
- Reviewed
- Integrated safely

Parallel development does not mean
both agents can modify anything at any time.

---

# 2. FUNDAMENTAL RULES

These rules are mandatory.

RULE-001:
One task has one accountable owner.

RULE-002:
Every active implementation task uses
a unique Git branch.

RULE-003:
Every active implementation task uses
an isolated worktree or clone.

RULE-004:
Agents must respect assigned file scopes.

RULE-005:
Shared-file changes require coordination.

RULE-006:
API contracts must be approved before
parallel dependent implementation.

RULE-007:
Conflicting database changes must be
serialized or explicitly coordinated.

RULE-008:
Security-sensitive changes require
appropriate review.

RULE-009:
No agent may overwrite another
agent's unmerged work.

RULE-010:
No task is complete without verification.

RULE-011:
Production changes require authorization.

RULE-012:
GitHub is the shared coordination platform.

RULE-013:
AI agents must never fabricate results.

RULE-014:
Security and correctness take priority
over parallel execution speed.

---

# 3. RELATED PROJECT DOCUMENTS

All agents must follow:

AGENTS.md
TASKS.md
PLAN.md
CONTRIBUTING.md
SRS.md
ARCHITECTURE.md
DESIGN_SYSTEM.md
SECURITY.md

Read when available and relevant:

DATABASE_DESIGN.md
TESTING.md
CLAUDE.md
docs/API_CONTRACTS.md
docs/decisions/

This document describes the operational
parallel development workflow.

It must not contradict AGENTS.md.

If instructions conflict:

1. Identify the conflict.
2. Follow higher-priority instructions.
3. Preserve security requirements.
4. Report the inconsistency.
5. Obtain an approved resolution.

Do not treat proposed technical decisions
as already approved.

---

# 4. SYSTEM OVERVIEW

The project contains three
coordination roles.

1. PROJECT LEAD
2. CLAUDE CODE
3. OPENAI CODEX

Workflow:

                    PROJECT LEAD
                          |
                    GitHub Backlog
                          |
                   Task Allocation
                          |
               +----------+----------+
               |                     |
          CLAUDE CODE              CODEX
               |                     |
          Git Worktree A       Git Worktree B
               |                     |
           Branch A              Branch B
               |                     |
          Task A Code          Task B Code
               |                     |
          Local Tests          Local Tests
               |                     |
          Pull Request A       Pull Request B
               |                     |
               +----------+----------+
                          |
                    CI Validation
                          |
                     Code Review
                          |
                    Integration
                          |
                      main
                          |
                End-to-End Verification

Each task must be traceable
from requirement to implementation
and verification evidence.

---

# 5. AGENT RESPONSIBILITIES

## 5.1 PROJECT LEAD

Identifier:
LEAD

Responsibilities:

- Approve task priorities
- Confirm task assignment
- Resolve ownership conflicts
- Coordinate shared files
- Approve critical architecture decisions
- Coordinate integration
- Review high-risk changes
- Approve production deployments
- Maintain the master development roadmap

The project lead may be the
project owner or authorized maintainer.

## 5.2 CLAUDE CODE

Identifier:
CLAUDE

Suggested initial focus:

- Flutter UI
- Design system
- Student experience
- Responsive layouts
- Course marketplace
- Checkout interfaces
- Learning workspace
- PDF reader interface
- Admin dashboard UI
- Widget tests

These are suggested work areas.

Claude may implement other tasks
when explicitly assigned.

## 5.3 OPENAI CODEX

Identifier:
CODEX

Suggested initial focus:

- Supabase setup
- PostgreSQL
- RLS policies
- Database migrations
- Backend API development
- Payment verification
- Bank receipt processing
- Enrollment authorization
- Protected content authorization
- Backend tests
- CI/CD

These are suggested work areas.

Codex may implement other tasks
when explicitly assigned.

## 5.4 NO PERMANENT MODULE OWNERSHIP

The project uses task-based ownership.

Do not assume:

Claude = All frontend files.

Codex = All backend files.

Actual permissions depend on
the assigned task and file scope.

---

# 6. COMMUNICATION MODEL

Claude and Codex may operate through:

- Separate accounts
- Separate chat sessions
- Separate computers
- Different cloud environments
- Different local Git clones

Therefore:

Do not assume agents share:

- Memory
- Conversations
- Temporary files
- Local environment variables
- Running processes
- Uncommitted code
- Task status

Critical information must be placed
in shared project artifacts.

## Official Communication Channels

1. GitHub Issues
2. GitHub Pull Requests
3. Approved repository documentation
4. Architecture Decision Records
5. Task handoff notes

The project lead is responsible
for resolving unclear ownership.

No automatic cross-agent communication
is assumed by this document.

---

# 7. SOURCE OF TRUTH

Use the following ownership hierarchy.

## GitHub Issues

Authoritative for:

- Active task ownership
- Current task status
- Dependencies
- Branch references
- Blockers
- Handoffs

## GitHub Pull Requests

Authoritative for:

- Submitted code
- Review comments
- CI results
- Merge status

## TASKS.md

Authoritative for:

- Master task IDs
- Planned backlog
- Milestone task coverage
- Stable implementation requirements

## PLAN.md

Authoritative for:

- Development phases
- Strategic dependencies
- Release gates

## AGENTS.md

Authoritative for:

- Shared AI engineering rules

When status records disagree:

1. Identify the latest approved decision.
2. Stop conflicting assignments.
3. Review GitHub evidence.
4. Correct stale records.
5. Resume only after ownership is clear.

Do not silently overwrite task records.

---

# 8. TASK IDENTIFICATION

Every tracked development task
must have a unique task ID.

Format:

CSA-XXX

Examples:

CSA-083
CSA-102
CSA-143

Existing IDs from TASKS.md
must be preserved.

New tasks must use unused identifiers.

Do not reuse cancelled task IDs.

## Issue Title Format

[CSA-083] Implement Responsive Course Grid

[CSA-102] Implement Payment Provider Webhook

[CSA-143] Implement PDF Reader Interface

## Task Attributes

Every active task requires:

Task ID:
Title:
Priority:
Proposed Agent:
Confirmed Owner:
Status:
Dependencies:
Allowed File Scope:
Restricted Shared Files:
Branch:
Workspace:
Related Requirements:
Acceptance Criteria:
Required Tests:
Related Pull Request:
Completion Evidence:

---

# 9. TASK STATUS WORKFLOW

Statuses:

BACKLOG
READY
CLAIMED
IN_PROGRESS
BLOCKED
IN_REVIEW
DONE
CANCELLED

Normal workflow:

BACKLOG
   |
   v
READY
   |
   v
CLAIMED
   |
   v
IN_PROGRESS
   |
   v
IN_REVIEW
   |
   v
DONE

Blocked workflow:

IN_PROGRESS
   |
   v
BLOCKED
   |
   v
READY / IN_PROGRESS

Task cancellation requires
approved scope management.

## DONE Requirements

A task is DONE when:

- Implementation is complete.
- Acceptance criteria are satisfied.
- Relevant tests actually pass.
- Required review is complete.
- CI requirements are satisfied.
- Code is merged or formally accepted.
- Completion evidence is recorded.

An open pull request is generally
IN_REVIEW, not DONE.

---

# 10. TASK READINESS CHECK

Before a task can be assigned:

- [ ] Task ID exists.
- [ ] Requirements are clear.
- [ ] Priority is recorded.
- [ ] Dependencies are satisfied.
- [ ] Architecture is defined.
- [ ] Security impact is identified.
- [ ] API contract exists if required.
- [ ] Writable file scope is clear.
- [ ] Shared-file conflicts are resolved.
- [ ] Acceptance criteria are testable.
- [ ] Required test approach is known.

If any critical requirement is unresolved,
mark the task BLOCKED.

Do not begin implementation using
guessed financial or permission rules.

---

# 11. TASK ALLOCATION PROCEDURE

The project lead allocates tasks.

## Step 1 - Select Task

Choose a READY task from
the approved task backlog.

## Step 2 - Check Dependencies

Verify all mandatory prerequisites.

## Step 3 - Check Agent Availability

Determine which agent is available
for new implementation work.

## Step 4 - Check File Scope

Identify every file or directory
the task may modify.

## Step 5 - Check Conflicts

Compare the proposed task with
currently active tasks.

## Step 6 - Confirm Ownership

Assign exactly one implementation owner.

## Step 7 - Record Assignment

Update the GitHub Issue.

## Step 8 - Create Workspace

Use an isolated branch and worktree
or separate Git clone.

## Step 9 - Start Work

The assigned agent may begin.

Do not treat a suggested allocation
as an official task claim.

---

# 12. TASK CLAIM RECORD

Use this record in a GitHub Issue.

## Task Claim

Task ID:
CSA-083

Assigned Agent:
CLAUDE

Confirmed By:
PROJECT LEAD

Status:
CLAIMED

Allowed Scope:
lib/features/marketplace/**

Restricted Shared Files:
lib/app/router/**
lib/app/theme/**
pubspec.yaml

Branch:
feat/csa-083-course-grid

Workspace:
acedra-claude-csa-083

Dependencies:
CSA-039
CSA-047
CSA-077
CSA-079

Contract:
Approved course catalog interface

The dependencies above must be
actually satisfied before implementation
dependent on them is considered ready.

A task claim must be visible
to both agents through GitHub.

---

# 13. CONCURRENCY POLICY

Recommended initial limit:

CLAUDE:
One active implementation task.

CODEX:
One active implementation task.

INTEGRATION:
One coordinated integration task
when necessary.

This is an operating policy.

It is not a technical limit
of the Claude or Codex products.

Increase concurrency only after:

- Task ownership is reliable.
- Git isolation works.
- Shared files are managed.
- Merge conflicts are controlled.
- CI is stable.
- Integration testing works.

Avoid excessive work in progress.

Finishing and merging a small task
is generally preferable to leaving
many branches partially implemented.

---

# 14. PARALLEL TASK COMPATIBILITY

## SAFE TO RUN IN PARALLEL

- Independent feature modules
- Separate Flutter UI components
- Separate backend functions
- Independent tests
- Independent approved documentation
- Frontend/backend with stable API contracts

## REQUIRES COORDINATION

- Changes to shared routing
- Changes to design tokens
- Shared domain model changes
- Shared dependency configuration
- Authentication integration
- API contract modifications
- Compatible database migrations

## SEQUENTIAL BY DEFAULT

- Same source file modifications
- Conflicting database migrations
- Same financial state machine changes
- Same privileged database function
- Unapproved API redesign
- Shared production configuration changes

Parallelism must respect dependencies.

A task is not ready merely because
its files do not overlap.

---

# 15. GIT REPOSITORY STRATEGY

Default branch:

main

Each agent uses:

- Unique task branch
- Isolated working directory
- Independent commits
- Separate pull request

Branch format:

<type>/csa-<id>-<description>

Examples:

feat/csa-083-course-grid

security/csa-102-payment-webhook

feat/csa-143-pdf-reader

fix/csa-076-session-handling

docs/csa-237-parallel-workflow

Never push routine development
changes directly to main.

Never force-push main.

---

# 16. WORKTREE SETUP - SAME COMPUTER

Use Git worktrees when Claude and Codex
operate on the same computer.

Example project directory:

workspace/
  acedra/
  acedra-claude-csa-083/
  acedra-codex-csa-102/

## Step 1 - Fetch Latest Changes

From the primary repository:

```bash
git fetch origin
```

## Step 2 - Create Claude Worktree

```bash
git worktree add \
  ../acedra-claude-csa-083 \
  -b feat/csa-083-course-grid \
  origin/main
```

## Step 3 - Create Codex Worktree

```bash
git worktree add \
  ../acedra-codex-csa-102 \
  -b security/csa-102-payment-webhook \
  origin/main
```

## Step 4 - Check Worktrees

```bash
git worktree list
```

## Step 5 - Assign Working Directories

Claude works in:

../acedra-claude-csa-083

Codex works in:

../acedra-codex-csa-102

Each agent must confirm its directory.

Do not execute implementation commands
in the other agent's worktree.

---

# 17. WORKSPACE SETUP - SEPARATE COMPUTERS

If Claude and Codex operate through
separate machines or cloud environments,
use separate Git clones.

Example:

Claude environment:

```bash
git clone <REPOSITORY_URL> acedra-claude
cd acedra-claude
git switch -c feat/csa-083-course-grid
```

Codex environment:

```bash
git clone <REPOSITORY_URL> acedra-codex
cd acedra-codex
git switch -c security/csa-102-payment-webhook
```

Replace the repository URL
with the real authorized repository.

Both environments must:

- Authenticate to GitHub independently.
- Use approved access permissions.
- Use different task branches.
- Fetch approved changes.
- Follow task ownership rules.
- Submit separate pull requests.

Do not share personal access tokens
between agents or accounts.

---

# 18. WORKSPACE VERIFICATION

Before modifying files, every agent runs:

```bash
pwd
git status --short
git branch --show-current
git rev-parse --show-toplevel
```

Verify:

- Correct project
- Correct branch
- Correct task
- Correct worktree/clone
- Expected working tree state

If the branch or directory is incorrect:

STOP.

Do not write code until resolved.

Never use destructive cleanup commands
as an automatic response to unexpected
uncommitted changes.

---

# 19. WORKTREE SECURITY RULES

Worktrees isolate source files.

They do not automatically isolate:

- Backend services
- Local databases
- Network ports
- Cloud storage
- Test fixtures
- Payment sandbox transactions
- Environment credentials

Mandatory rules:

- Do not share mutable test databases
  without an isolation strategy.
- Do not run conflicting local services.
- Do not use production customer data.
- Do not copy production secrets.
- Do not delete another agent's files.
- Do not clean another agent's worktree.
- Do not use the same writable output path
  for conflicting test processes.

If proper isolation is unavailable,
serialize affected operations.

---

# 20. SHARED FILE OWNERSHIP

Some files are used by
multiple application modules.

Examples:

AGENTS.md
PLAN.md
TASKS.md
ARCHITECTURE.md
SECURITY.md
DESIGN_SYSTEM.md
CONTRIBUTING.md
CLAUDE.md

pubspec.yaml
pubspec.lock

lib/app/**
lib/core/**
lib/shared/**

supabase/migrations/**

.github/workflows/**

docs/api-contracts/**

These resources need coordination.

## Shared Ownership Rule

A conflicting shared-file change
must have one designated owner.

Other agents must not independently
edit the same resource during
the reserved integration period.

No permanent lock is implied.

Ownership ends through an explicit
handoff or approved integration.

---

# 21. SHARED FILE LOCK RECORD

Use the following logical lock format.

## Shared Resource Reservation

Resource:
lib/app/router/app_router.dart

Owner:
CLAUDE

Task:
CSA-083

Reason:
Marketplace route integration

Status:
RESERVED

Created:
Record actual timestamp.

Expected Release:
After approved integration or handoff.

Linked Issue:
Record actual Issue URL.

Linked PR:
Record actual PR URL when available.

## Lock Rules

- Lock records must be visible on GitHub.
- Only one conflicting owner is allowed.
- Locks must reference active tasks.
- Locks must have a release condition.
- Agents must check ownership before editing.
- Unused locks must be released.
- Conflicting claims require lead resolution.

GitHub labels and comments are
logical coordination mechanisms.

They are not atomic distributed locks.

The lead must resolve competing claims
before work begins.

Do not automatically assume ownership
because a lock appears stale.

---

# 22. SHARED FILE CHANGE PROCEDURE

When Claude needs a shared file:

1. Identify the file.
2. Review existing reservations.
3. Check Codex's active scope.
4. Request temporary ownership.
5. Record the approved change.
6. Modify only the necessary code.
7. Run relevant tests.
8. Open or update the PR.
9. Release ownership after approved integration.

The same procedure applies to Codex.

## Preferred Alternative

If possible:

- Implement the feature in an isolated module.
- Avoid modifying the shared router directly.
- Expose an approved integration interface.
- Assign a separate integration task.

This reduces merge conflicts.

Do not create unnecessary abstractions
only to avoid minor file coordination.

---

# 23. DATABASE MIGRATION COORDINATION

Supabase uses PostgreSQL migrations.

Migrations are high-risk shared changes.

## Rules

- One owner per migration.
- Approved schema contracts.
- Explicit migration dependencies.
- Reviewed grants and RLS.
- Reviewed database functions.
- No uncoordinated production changes.
- No edits to already-applied migrations
  without an approved correction strategy.

## Example Conflict

CLAUDE requires:

courses.thumbnail_url

CODEX requires:

courses.publication_status

Preferred workflow:

1. Agree on the target schema.
2. Assign the migration task to one owner.
3. Implement the approved schema.
4. Test migration behavior.
5. Publish the updated contract.
6. Continue dependent frontend/backend work.

Separate compatible migrations may be
authored concurrently only when
their dependencies are understood.

Migration integration must verify ordering.

## Required Checks

- Schema constraints
- Foreign keys
- Indexes
- Table grants
- RLS policies
- Transaction correctness
- Migration compatibility

Never disable RLS to fix a development error.

---

# 24. API CONTRACT-FIRST WORKFLOW

Frontend and backend development
may happen in parallel.

However, shared interfaces must
be approved before implementation.

## Contract Requirements

Every shared API contract must specify:

- Operation name
- Purpose
- Request structure
- Response structure
- Authentication
- Authorization
- Validation
- Error codes
- State transitions
- Idempotency requirements
- Relevant data models

## Example

Operation:
create-checkout-order

Frontend Owner:
CLAUDE

Backend Owner:
CODEX

Request:

course_id
payment_method

Response:

order_id
order_status
checkout_information

Security:

The backend determines the trusted price.

The frontend must not grant enrollment
based on checkout initialization.

## Contract Change Procedure

1. Propose the contract change.
2. Identify dependent tasks.
3. Notify affected owners through GitHub.
4. Review compatibility.
5. Approve the change.
6. Update documentation and tests.
7. Implement coordinated changes.

Never silently change shared contracts.

---

# 25. CONTRACT DOCUMENTATION

Recommended directory:

docs/
  api-contracts/
    authentication.md
    courses.md
    checkout.md
    payments.md
    bank-transfers.md
    enrollments.md
    protected-content.md
    admin.md

An optional index may be maintained at:

docs/API_CONTRACTS.md

Do not duplicate conflicting
contract definitions.

Each contract should identify
its current approved revision.

A contract change that breaks dependent
code requires explicit coordination.

---

# 26. PARALLEL EXECUTION WAVES

Work is organized into dependency-aware waves.

## WAVE 0 - REQUIREMENTS

CLAUDE:

- Review design requirements.
- Identify reusable UI elements.
- Review responsive layouts.

CODEX:

- Draft data architecture.
- Identify backend boundaries.
- Review RLS and payment threats.

LEAD:

- Approve business policies.
- Approve architecture.
- Approve critical provider decisions.

Gate:
Required decisions documented.

## WAVE 1 - FOUNDATION

CLAUDE:

- Flutter architecture
- Theme foundation
- Reusable UI components

CODEX:

- Supabase setup
- Database tooling
- Backend test setup

LEAD:

- Repository access
- GitHub task coordination
- CI policy

Gate:
Both environments operational.

## WAVE 2 - AUTH AND CATALOG

CLAUDE:

- Login and registration UI
- Course marketplace UI

CODEX:

- Profiles and roles
- Course schema
- RLS policies

Gate:
Auth and course contracts integrated.

## WAVE 3 - COMMERCE

CLAUDE:

- Checkout UI
- Bank transfer upload interface
- Payment status screens

CODEX:

- Orders
- Verified payment callbacks
- Bank approval transactions
- Enrollment grants

Gate:
Sandbox purchase journeys pass.

## WAVE 4 - LEARNING

CLAUDE:

- My Courses
- Learning workspace
- PDF reader UI
- Video player UI

CODEX:

- Content authorization
- Private media delivery
- Progress persistence
- Watermark generation

Gate:
Authorized learning workflows pass.

## WAVE 5 - ADMINISTRATION

CLAUDE:

- Admin dashboard
- Course editor
- Receipt review UI

CODEX:

- Trusted admin operations
- Reporting APIs
- Audit logs
- Role verification

Gate:
Admin workflows pass authorization tests.

## WAVE 6 - RELEASE QUALITY

CLAUDE:

- Responsive testing
- UI regression
- Accessibility review

CODEX:

- Backend regression
- Security tests
- Financial concurrency tests

LEAD:

- Release acceptance
- Production authorization

Gate:
Release requirements satisfied.

Waves may overlap when dependencies allow.

They are not automatic background tasks.

---

# 27. DAILY OPERATING PROCEDURE

Use this process whenever beginning
a new parallel development session.

## PROJECT LEAD

1. Review GitHub Issues.
2. Review active PRs.
3. Review blocked tasks.
4. Check shared-file reservations.
5. Check current integration status.
6. Identify READY independent tasks.
7. Confirm Claude assignment.
8. Confirm Codex assignment.
9. Review dependency conflicts.
10. Record task ownership.

## CLAUDE

1. Read CLAUDE.md.
2. Follow AGENTS.md.
3. Read assigned GitHub Issue.
4. Confirm branch/worktree.
5. Review task requirements.
6. Check available relevant skills.
7. Implement assigned work.
8. Run applicable tests.
9. Review diff.
10. Submit PR/handoff.

## CODEX

1. Read AGENTS.md.
2. Read assigned GitHub Issue.
3. Confirm branch/workspace.
4. Review relevant backend contracts.
5. Review security implications.
6. Implement assigned work.
7. Run applicable tests.
8. Review diff.
9. Submit PR/handoff.
10. Record blockers if any.

## INTEGRATION

1. Review submitted PRs.
2. Check dependencies.
3. Check CI.
4. Obtain required reviews.
5. Merge in dependency order.
6. Verify combined behavior.
7. Update task statuses.
8. Release shared reservations.

---

# 28. CLAUDE SUPERPOWERS INTEGRATION

Claude may use the Superpowers
development workflow when installed.

Relevant skills may include:

- brainstorming
- writing-plans
- using-git-worktrees
- test-driven-development
- systematic-debugging
- verification-before-completion
- requesting-code-review
- receiving-code-review
- finishing-a-development-branch

Use skills only when available
and relevant to the actual task.

Do not invent unavailable tools
or claim a skill ran when it did not.

## Subagent Rules

Claude subagents remain inside
Claude's assigned task boundaries.

Subagents must not:

- Claim Codex-owned tasks
- Modify Codex's active files
- Ignore shared-file reservations
- Change contracts without approval
- Execute conflicting migrations
- Perform unauthorized deployment

Superpowers is an implementation aid.

It does not replace GitHub ownership,
project requirements, or human approval.

---

# 29. CODEX EXECUTION RULES

Codex uses AGENTS.md as the
shared repository instruction file.

Codex should:

- Inspect the assigned task.
- Verify actual source state.
- Respect branch isolation.
- Follow scoped file ownership.
- Implement small testable changes.
- Verify security-sensitive behavior.
- Run relevant checks.
- Prepare reviewable commits.
- Report accurate results.

Codex must not assume Claude's
task is completed based on a chat message.

Verify shared repository evidence.

A separate CODEX.md is not required.

---

# 30. TESTING WORKFLOW

Every implementation task must
include appropriate verification.

## Flutter Checks

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

## Supabase Checks

When configured:

```bash
supabase test db
```

## Additional Tests

Run relevant:

- Edge Function tests
- RLS tests
- Integration tests
- Security tests
- Payment sandbox tests
- Widget tests
- Accessibility checks

Tests must be executed in
appropriate isolated environments.

Never use actual customer payments
for routine automated testing.

---

# 31. TEST ENVIRONMENT COORDINATION

Parallel tasks may share
external development services.

This can create interference.

## Potential Conflicts

- Supabase local ports
- Mutable database data
- Test user accounts
- Storage objects
- Payment sandbox transactions
- Temporary files
- Shared test reports

## Preferred Solutions

Option A:
Separate isolated local environments.

Option B:
Separate test schemas or namespaces
where supported and appropriate.

Option C:
Unique test identifiers and fixtures.

Option D:
Serialized tests for shared resources.

## Rules

- Do not reset shared databases unexpectedly.
- Do not delete another task's fixtures.
- Do not reuse test transaction IDs.
- Do not assume separate worktrees
  imply independent databases.
- Do not run destructive commands
  against production services.

An integration test environment must
represent the approved combined system.

---

# 32. COMMIT WORKFLOW

Each agent must use
focused commits.

Commit format:

type(scope): description

Examples:

feat(marketplace): add responsive grid

feat(auth): implement login screen

security(payments): verify provider callback

test(enrollment): cover invalid access

fix(pdf): correct page navigation

## Before Commit

```bash
git status
git diff
```

Verify:

- Files belong to the task.
- No unrelated changes.
- No secrets.
- No private student data.
- No unexpected generated files.

Stage only relevant files.

Do not modify another agent's commits.

---

# 33. PULL REQUEST WORKFLOW

Every implementation task should
result in a pull request.

## Required PR Fields

Task ID:
Assigned Agent:
Confirmed Owner:
Related GitHub Issue:
Branch:
Base Branch:
Implementation Summary:
Files Changed:
Shared File Changes:
API Contract Changes:
Database Migration Changes:
Tests Executed:
Security Considerations:
UI/UX Verification:
Known Limitations:
Dependencies:

## PR Requirements

- Focused change scope
- Relevant tests
- Honest test results
- Reviewed diff
- Security impact documented
- Shared-file coordination
- No leaked secrets
- Applicable CI checks

A PR does not count as completed
until accepted according to project policy.

---

# 34. CROSS-AGENT CODE REVIEW

Claude may review Codex changes.

Codex may review Claude changes.

## Review Checklist

- Requirements satisfied?
- Architecture followed?
- File scope respected?
- Contracts compatible?
- Correct error handling?
- Relevant tests implemented?
- Authorization secure?
- Financial logic correct?
- UI consistent?
- Performance impact acceptable?
- Documentation updated?

## Important

AI cross-review may improve quality.

It does not automatically replace
independent human approval.

Critical changes require authorized
review under SECURITY.md.

Examples:

- Payment verification
- Enrollment authorization
- Role assignments
- RLS policies
- Privileged database functions
- Production infrastructure

The implementing agent must not claim
self-review is independent review.

---

# 35. CI/CD INTEGRATION GATE

Before a PR merges:

- [ ] Task ownership confirmed.
- [ ] Required dependencies satisfied.
- [ ] No unresolved shared-file conflicts.
- [ ] No unapproved API changes.
- [ ] Database migration order reviewed.
- [ ] Relevant tests pass.
- [ ] Flutter analysis passes if applicable.
- [ ] Backend security checks pass if applicable.
- [ ] Secrets scan reviewed where configured.
- [ ] Required reviewers approved.
- [ ] No known release-blocking regression.

GitHub branch protection and
required-review enforcement depend
on the repository's plan and settings.

If automated enforcement is unavailable,
follow an equivalent documented
manual approval process.

Never describe manual policy
as automatically enforced protection.

---

# 36. MERGE ORDER POLICY

Merge in dependency order.

Example:

1. Shared database schema
2. Backend API
3. Frontend integration
4. End-to-end tests

Independent PRs may merge
in either order after validation.

## Merge Procedure

1. Verify PR readiness.
2. Check latest main state.
3. Check CI and review status.
4. Merge through approved method.
5. Verify relevant combined behavior.
6. Update dependent task branches.
7. Record merge completion.
8. Release shared-file ownership.

## Updating Dependent Branches

From the dependent feature branch:

```bash
git fetch origin
git merge origin/main
```

Resolve any conflicts deliberately.

Run affected tests after merging.

Do not rebase or rewrite another
agent's active shared branch.

History rewriting is permitted only
under the project's approved
branch ownership rules.

---

# 37. MERGE CONFLICT PROCEDURE

If a conflict occurs:

STOP AUTOMATIC INTEGRATION.

Then:

1. Preserve both branches.
2. Identify conflicting files.
3. Identify task owners.
4. Review the intended behaviors.
5. Identify correct combined changes.
6. Assign an integration owner.
7. Resolve changes deliberately.
8. Run affected tests.
9. Review security implications.
10. Obtain required approval.

Never:

- Discard the other agent's work silently.
- Force-push main.
- Delete failing tests to pass CI.
- Weaken security rules.
- Change business invariants casually.
- Auto-resolve conflicts without review.

Complex conflicts require
a dedicated integration task.

---

# 38. HANDOFF PROCEDURE

If an agent cannot finish a task,
it must produce a handoff record.

## Handoff Template

Task ID:
Title:
Current Owner:
Status:
Branch:
Commit:
Pull Request:
Base Revision:

## Completed Work

Describe verified implementation.

## Files Changed

List affected files.

## Shared Contracts

List important changes.

## Tests Executed

Commands:
Results:
Checks Not Performed:

## Remaining Work

List unfinished requirements.

## Blockers

Identify missing dependencies.

## Risks

Record technical or security concerns.

## Next Owner

Specify the approved next owner.

A task transfer must be recorded
through shared coordination.

Do not rely only on chat history.

---

# 39. BLOCKER ESCALATION

When an agent is blocked:

1. Identify the issue.
2. Record it in the GitHub task.
3. Mark the task BLOCKED.
4. Identify dependency owner.
5. Describe the required resolution.
6. Avoid unsafe temporary workarounds.
7. Continue independent approved work
   if one is available.

Examples:

CLAUDE BLOCKED:
Checkout API contract not approved.

CODEX BLOCKED:
Payment provider not selected.

PROJECT LEAD ACTION:
Resolve decision or dependency.

Do not duplicate another agent's
task to remove a blocker.

---

# 40. SHARED DOCUMENTATION UPDATES

The following files should not be
edited concurrently without coordination:

PLAN.md
TASKS.md
AGENTS.md
ARCHITECTURE.md
DESIGN_SYSTEM.md
SECURITY.md
CONTRIBUTING.md
PARALLEL_WORKFLOW.md

GitHub Issues are the live source
of task status and ownership.

TASKS.md should be reconciled
at defined milestones.

Do not make both agents update TASKS.md
after every small status change.

Prefer:

- Agent updates its Issue.
- Agent submits PR.
- Project lead reconciles milestones.

Technical documentation changes should
be included in the related scoped PR
when ownership is clear.

---

# 41. PRACTICAL PARALLEL EXAMPLE

Scenario:

Develop Course Marketplace UI
and Course Data Services.

## Prerequisites

- Flutter project initialized.
- Supabase development configured.
- Design tokens available.
- Course schema contract approved.
- Publication policy defined.
- Tasks and ownership confirmed.

## CLAUDE TASK

Task:
CSA-083

Title:
Responsive Course Grid

Files:
lib/features/marketplace/**

Responsibilities:

- Course cards
- Responsive grid
- Loading states
- Empty states
- Light/dark styling
- Widget tests

Branch:
feat/csa-083-course-grid

## CODEX TASK

Task:
CSA-079

Title:
Course Publication Policies

Files:
Approved database migration and tests

Responsibilities:

- Public course visibility
- Draft course restrictions
- Authorized publication policies
- RLS tests

Branch:
security/csa-079-course-policies

## Dependency Note

CSA-083 depends on the course data
contract and relevant approved schema.

If CSA-079 is not yet complete,
Claude may build isolated UI behavior
against an approved synthetic fixture.

Real backend integration must wait
until the required policies are verified.

## Integration

1. Review both PRs.
2. Verify the shared course contract.
3. Merge in dependency order.
4. Connect UI to real course data.
5. Verify published course visibility.
6. Verify draft course isolation.
7. Run integration tests.

Do not mark the combined marketplace
feature complete until integrated.

---

# 42. CHECKOUT PARALLEL EXAMPLE

Scenario:

Build Checkout UI and
Trusted Checkout Backend.

## CLAUDE

Assigned Work:

- Checkout layout
- Payment method selection
- Order summary display
- Payment status UI

Allowed Scope:

lib/features/checkout/**

## CODEX

Assigned Work:

- Trusted order creation
- Authoritative price lookup
- Payment provider initialization
- Backend error handling
- Financial tests

Allowed Scope:

supabase/functions/create-checkout-order/**
Approved financial migrations/tests

## Shared Contract

Required:

create-checkout-order

Input:

course_id
payment_method

Output:

order_id
order_status
checkout_information

## Security Requirements

- Client cannot set trusted price.
- Client cannot confirm payment.
- Client cannot create enrollment.
- Provider callback must be verified.
- Pending payments do not unlock courses.

## Integration

1. Contract approved.
2. Both implementations developed.
3. Backend tests pass.
4. UI tests pass.
5. Real sandbox integration passes.
6. Financial authorization tests pass.
7. Required security review completes.

This workflow is mandatory for
payment-related parallel development.

---

# 43. PDF READER PARALLEL EXAMPLE

Scenario:

Develop Premium PDF Reader and
Protected Document Delivery.

## CLAUDE

Responsibilities:

- PDF reader layout
- Page navigation
- Zoom
- Fit-to-width
- Reader loading states
- Reading progress UI
- Accessibility

## CODEX

Responsibilities:

- Private PDF storage
- User authorization
- Entitlement verification
- Controlled content access
- Approved watermark generation
- Access denial tests

## Shared Contract

Operation:

authorize-course-content

Input:

lesson_id

Output:

Authorized content access information

## Security Rules

- Paid PDF requires active enrollment.
- Storage must remain private.
- Unauthorized requests must be denied.
- Access authorization should be limited.
- Content-copy limitations must be documented.

## Important Limitation

Flutter Web cannot guarantee
preventing screenshots,
screen recordings, or extraction
of browser-delivered content.

Never promise absolute protection.

## Integration Gate

- [ ] Authorized PDF opens.
- [ ] Unauthorized PDF denied.
- [ ] Revoked enrollment blocks new access.
- [ ] Reader renders correctly.
- [ ] Watermark behavior reviewed.
- [ ] Mobile and desktop verified.
- [ ] Security limitations documented.

---

# 44. SECURITY-SENSITIVE TASK POLICY

The following changes require
additional review:

- Payment verification
- Bank receipt approval
- Enrollment authorization
- RLS policies
- Administrator role changes
- Privileged database functions
- Private content delivery
- Secret management
- Production deployment

Mandatory requirements:

1. Confirm task owner.
2. Review threat model.
3. Define security acceptance tests.
4. Implement within approved scope.
5. Run positive and negative tests.
6. Review permissions.
7. Record actual results.
8. Obtain authorized review.

No agent may independently
approve its own critical security change
as production-ready.

---

# 45. EMERGENCY INCIDENT WORKFLOW

If a critical vulnerability is found:

1. Report the issue privately.
2. Assess severity.
3. Stop affected unsafe operations.
4. Pause conflicting parallel changes.
5. Assign one incident implementation owner.
6. Preserve evidence.
7. Implement a focused fix.
8. Run regression tests.
9. Obtain authorized review.
10. Deploy through approved procedures.
11. Verify recovery.
12. Record lessons learned.

Examples:

- Payment verification bypass
- Unauthorized enrollment
- Public financial receipts
- Privilege escalation
- Leaked production credentials

Do not continue normal parallel
implementation in affected shared modules
until the incident is controlled.

---

# 46. WORKTREE CLEANUP

After a task is merged:

1. Confirm the PR is merged.
2. Confirm no required work remains.
3. Confirm no uncommitted changes remain.
4. Release shared-file reservations.
5. Confirm the worktree can be removed.
6. Remove the completed worktree.
7. Refresh the main repository.

Check worktrees:

```bash
git worktree list
```

Example cleanup:

```bash
git worktree remove ../acedra-claude-csa-083
```

Do not use forced removal
without explicit approval.

Do not delete active uncommitted work.

Only delete merged task branches
after the project's cleanup checks pass.

---

# 47. PROGRESS REPORTING

Every meaningful task update should record:

- Task ID
- Current owner
- Status
- Branch
- PR
- Completed work
- Remaining work
- Relevant test results
- Blockers
- Shared contract changes
- Next action

## Weekly or Milestone Review

Review:

- Completed tasks
- Active Claude tasks
- Active Codex tasks
- Blocked tasks
- Open PRs
- Integration conflicts
- Security risks
- Shared-file reservations
- Next READY tasks

Do not fabricate progress percentages.

A checked TASKS.md item must have
actual completion evidence.

---

# 48. INITIAL SETUP CHECKLIST

Before starting regular parallel work:

- [ ] AGENTS.md v2 approved.
- [ ] TASKS.md v2 approved.
- [ ] CONTRIBUTING.md v2 approved.
- [ ] PLAN.md v2 approved.
- [ ] CLAUDE.md created.
- [ ] PARALLEL_WORKFLOW.md approved.
- [ ] GitHub repository configured.
- [ ] GitHub Issues enabled.
- [ ] Task ownership fields configured.
- [ ] PR templates configured.
- [ ] CODEOWNERS reviewed.
- [ ] Branch protection configured
      where supported.
- [ ] Flutter environment configured.
- [ ] Supabase environment configured.
- [ ] CI pipeline operational.
- [ ] Isolated workspaces tested.
- [ ] Shared-file ownership tested.
- [ ] API contract process established.
- [ ] Database migration process established.
- [ ] Security review policy defined.

---

# 49. FIRST TWO-AGENT DRY-RUN

Related Task:
CSA-250

Goal:

Verify the parallel workflow
before implementing critical payments.

## Preparation

The project lead must:

- Choose two independent READY tasks.
- Confirm each task's owner.
- Confirm file scopes do not conflict.
- Approve branch names.
- Confirm isolated environments.

## CLAUDE

Suggested dry-run work:

Create or improve a small,
isolated Flutter UI component.

Requirements:

- Task scope defined
- Widget test
- Theme compatibility
- Reviewable PR

## CODEX

Suggested dry-run work:

Create or improve an independent
backend test or tooling component.

Requirements:

- Task scope defined
- Relevant test
- No conflicting files
- Reviewable PR

## Integration Test

1. Confirm separate branches.
2. Confirm separate workspaces.
3. Verify both task records.
4. Run local tests.
5. Push branches.
6. Open PRs.
7. Run CI checks.
8. Obtain reviews.
9. Merge safely.
10. Verify combined repository state.

## Success Criteria

- [ ] Both tasks claimed correctly.
- [ ] No shared workspace modification.
- [ ] No conflicting file edits.
- [ ] Both PRs reviewed.
- [ ] Relevant tests pass.
- [ ] Merge sequence completed.
- [ ] Integrated checks pass.
- [ ] Task records reconciled.

Do not mark the dry-run complete
unless it was actually executed.

---

# 50. DEFINITION OF READY

A parallel task is READY when:

- [ ] Task exists.
- [ ] Requirements approved.
- [ ] Dependencies satisfied.
- [ ] File ownership scope clear.
- [ ] No unresolved overlap.
- [ ] API contracts approved if needed.
- [ ] Security concerns identified.
- [ ] Tests defined.
- [ ] Acceptance criteria testable.

Task claiming happens after READY.

---

# 51. DEFINITION OF DONE

A parallel task is DONE when:

- [ ] Implementation complete.
- [ ] Assigned scope respected.
- [ ] Architecture followed.
- [ ] Relevant tests pass.
- [ ] Security checks performed.
- [ ] UI verified if applicable.
- [ ] Shared changes coordinated.
- [ ] CI checks pass.
- [ ] Required reviews complete.
- [ ] Changes merged or formally accepted.
- [ ] Integration behavior verified.
- [ ] Documentation updated.
- [ ] Completion evidence recorded.
- [ ] Shared locks released.

An AI-generated implementation
is not automatically complete.

---

# 52. NON-NEGOTIABLE PROHIBITIONS

Claude and Codex must never:

- Claim the same active task independently.
- Modify the same mutable worktree.
- Overwrite another agent's unmerged code.
- Ignore shared-file ownership.
- Create uncoordinated conflicting migrations.
- Silently change API contracts.
- Force-push main.
- Remove tests to bypass CI.
- Claim passing tests without execution.
- Disable RLS for convenience.
- Grant enrollments without trusted verification.
- Approve bank receipts automatically.
- Expose production secrets.
- Publicly expose paid PDFs.
- Use production student data casually.
- Deploy production changes without approval.
- Claim all screenshots can be blocked.
- Hide important blockers.
- Mark unfinished tasks DONE.

---

# 53. FINAL OPERATING DIRECTIVE

Acedra uses controlled parallel
multi-agent engineering.

CLAUDE and CODEX may work simultaneously
on approved independent tasks.

Every task requires:

- One accountable owner
- Clear dependencies
- Approved scope
- Isolated workspace
- Unique branch
- Stable contracts
- Security-aware implementation
- Meaningful tests
- Reviewable PR
- Controlled integration
- Verified completion

GitHub provides the shared record.

AGENTS.md provides shared engineering rules.

TASKS.md provides the master backlog.

PARALLEL_WORKFLOW.md defines execution.

CLAUDE.md configures Claude-specific behavior.

CONTRIBUTING.md governs source contributions.

PLAN.md governs development strategy.

PARALLEL WHERE SAFE.
SEQUENTIAL WHERE REQUIRED.
ONE TASK - ONE OWNER.
ONE BRANCH - ONE WORKSPACE.
NO SILENT SHARED-FILE CHANGES.
NO UNVERIFIED PAYMENT ACCESS.
TEST BEFORE MERGE.
REVIEW BEFORE RELEASE.
GITHUB AS COORDINATION SOURCE.
SECURITY BY DESIGN.

END OF PARALLEL_WORKFLOW.md
