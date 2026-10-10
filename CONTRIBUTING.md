
# CONTRIBUTING.md
# Acedra - Multi-Agent Contribution Guidelines

Document ID: CSA-CONTRIB-001
Version: 2.0
Status: Proposed - Pending Approval
Project: Acedra Course Selling Application
Primary Platform: Flutter Web
Future Platforms: Android and iOS
Backend: Supabase + PostgreSQL
Architecture: Feature-First Clean Architecture
Development Model: Parallel Multi-Agent Engineering
AI Agents: Claude Code + OpenAI Codex
Version Control: Git + GitHub
Methodology: Agile + Specification-First + TDD
Classification: Internal Engineering Documentation

---

# 1. PURPOSE

This document defines the official
contribution workflow for Acedra.

Acedra is a secure commercial platform
for selling and delivering digital courses.

The application includes:

- Student authentication
- Course marketplace
- Online payment processing
- Bank transfer receipt uploads
- Administrative payment approval
- Secure course enrollments
- Video, text, image, and PDF lessons
- Protected PDF reader
- Learning progress tracking
- Student dashboards
- Administrative dashboards
- Responsive light and dark themes

Development involves:

1. Claude Code
2. OpenAI Codex
3. Authorized human contributors

Claude and Codex may implement
independent tasks simultaneously.

All contributions must preserve:

- Security
- Correctness
- Student privacy
- Financial integrity
- Architecture consistency
- Maintainability
- Accessibility
- Reliability
- Performance
- Test coverage
- Git history integrity

Parallel development must be coordinated,
isolated, reviewed, and verified.

---

# 2. CORE CONTRIBUTION PRINCIPLES

Every contributor must follow:

1. Security First
2. Correctness Before Speed
3. Privacy by Design
4. Least Privilege
5. Clean Architecture
6. Single Task Ownership
7. Isolated Development Workspaces
8. Small Reviewable Changes
9. Test-Driven Development
10. Controlled Integration
11. Transparent Communication
12. Verified Completion

Never compromise security to
finish a task faster.

Never claim unverified work is complete.

Never overwrite another contributor's
active or unmerged changes.

---

# 3. PROJECT DOCUMENTATION

Before contributing, read:

- README.md
- PLAN.md
- TASKS.md
- AGENTS.md
- SRS.md
- ARCHITECTURE.md
- DATABASE_DESIGN.md
- DESIGN_SYSTEM.md
- SECURITY.md
- TESTING.md
- CONTRIBUTING.md
- docs/PARALLEL_WORKFLOW.md

Claude Code must also read:

- CLAUDE.md

Important:

AGENTS.md is the shared engineering
rulebook for all agents.

CLAUDE.md contains Claude-specific
entry instructions.

CLAUDE.md must not duplicate or
contradict the shared engineering policies.

Missing or draft documentation must
not be treated as approved.

---

# 4. CONTRIBUTOR ROLES

## 4.1 PROJECT LEAD

Identifier:
LEAD

Responsibilities:

- Approve development priorities
- Allocate tasks
- Resolve ownership conflicts
- Approve shared-file changes
- Coordinate integration
- Review architecture changes
- Approve security-sensitive work
- Control production deployments
- Approve completed milestones

## 4.2 CLAUDE CODE

Identifier:
CLAUDE

Suggested initial responsibilities:

- Flutter UI development
- Responsive layouts
- Design system
- Authentication screens
- Course marketplace
- Student learning screens
- PDF reader UI
- Admin dashboard UI
- Widget tests

Actual responsibilities are determined
by assigned GitHub tasks.

Claude may implement backend functionality
when explicitly assigned.

## 4.3 OPENAI CODEX

Identifier:
CODEX

Suggested initial responsibilities:

- Supabase backend
- PostgreSQL database
- Database migrations
- RLS policies
- Payment verification
- Bank transfer processing
- Enrollment authorization
- Protected content delivery
- Backend security tests
- CI/CD configuration

Actual responsibilities are determined
by assigned GitHub tasks.

Codex may implement Flutter features
when explicitly assigned.

## 4.4 HUMAN CONTRIBUTORS

Human contributors may:

- Implement features
- Review code
- Test functionality
- Review security
- Maintain infrastructure
- Approve changes
- Coordinate releases

Access must follow least privilege.

---

# 5. MULTI-AGENT DEVELOPMENT MODEL

Claude and Codex operate as
independent development workers.

Recommended workflow:

               PROJECT LEAD
                     |
               GitHub Issues
                     |
              Task Allocation
                     |
           +---------+---------+
           |                   |
       CLAUDE CODE           CODEX
           |                   |
       Assigned Task A    Assigned Task B
           |                   |
       Worktree A          Worktree B
           |                   |
       Branch A            Branch B
           |                   |
       Implementation     Implementation
           |                   |
       Local Tests         Local Tests
           |                   |
       Pull Request A     Pull Request B
           |                   |
           +---------+---------+
                     |
              Integration Review
                     |
               GitHub Actions
                     |
                Code Review
                     |
               Approved Merge
                     |
                  main

Important:

Claude and Codex may use different
accounts and execution environments.

Do not assume both agents share
the same local filesystem.

Use GitHub for shared coordination.

Neither agent may silently control
the other agent's active task.

---

# 6. SINGLE TASK OWNERSHIP

Every implementation task must
have one accountable owner.

Example:

Task:
CSA-083 - Responsive Course Grid

Owner:
CLAUDE

Task:
CSA-102 - Payment Provider Webhook

Owner:
CODEX

Both tasks may run in parallel.

However:

- Each task has one implementation owner.
- Other agents may review the work.
- Ownership must be recorded.
- Scope changes require coordination.
- Reassignment must be explicit.

Do not implement a task already
owned by another active contributor.

---

# 7. GITHUB AS SOURCE OF TRUTH

GitHub is the central collaboration platform.

Use:

GitHub Issues:
Task ownership and active status.

GitHub Pull Requests:
Code review and integration.

GitHub Actions:
Automated verification.

GitHub Branches:
Isolated implementation history.

GitHub Projects:
Optional visual task board.

Project files:

TASKS.md:
Stable master task backlog.

PLAN.md:
Phase-level development roadmap.

AGENTS.md:
Agent engineering rules.

## Source-of-Truth Rules

GitHub Issues should contain
live task assignments.

TASKS.md should be synchronized
during planned reconciliation.

Do not rely solely on AI chat history.

Do not assume one agent can automatically
read the other agent's conversation.

Important decisions must be written
to shared project artifacts.

---

# 8. TASK ALLOCATION PROCEDURE

Before an agent begins a task:

1. Read AGENTS.md.
2. Read TASKS.md.
3. Identify the task ID.
4. Review the GitHub Issue.
5. Check dependencies.
6. Review related SRS requirements.
7. Review relevant architecture.
8. Identify writable files.
9. Identify shared files.
10. Check active ownership.
11. Obtain approved task assignment.
12. Record the confirmed owner.
13. Create an isolated workspace.
14. Begin implementation.

## Required Task Information

Task ID:
Title:
Priority:
Phase:
Assigned Agent:
Confirmed Owner:
Status:
Dependencies:
Allowed File Scope:
Restricted Shared Files:
Branch:
Worktree:
Related Requirements:
Acceptance Criteria:
Required Tests:
Related PR:
Completion Evidence:

## Task Assignment Example

Task ID:
CSA-083

Title:
Implement Responsive Course Grid

Priority:
P1

Proposed Agent:
CLAUDE

Confirmed Owner:
UNASSIGNED until approved.

Allowed Files:
lib/features/marketplace/**

Restricted Shared Files:
lib/app/theme/**
lib/app/router/**
pubspec.yaml

Proposed Branch:
feat/csa-083-course-grid

Acceptance Criteria:
- Responsive course cards
- Light and dark themes
- Loading state
- Empty state
- Accessible interactions
- Widget tests

Actual ownership must be recorded
before implementation begins.

---

# 9. TASK STATUS LIFECYCLE

Allowed statuses:

BACKLOG
READY
CLAIMED
IN_PROGRESS
BLOCKED
IN_REVIEW
DONE
CANCELLED

BACKLOG:
Task not ready.

READY:
Requirements and dependencies satisfied.

CLAIMED:
Owner officially assigned.

IN_PROGRESS:
Implementation started.

BLOCKED:
Work cannot safely proceed.

IN_REVIEW:
Pull request or verification pending.

DONE:
Acceptance criteria verified and
changes merged or formally accepted.

CANCELLED:
Task removed by approved scope change.

Never mark a task DONE because
source code was generated.

---

# 10. PARALLEL TASK ELIGIBILITY

Tasks may run in parallel when:

- Dependencies are satisfied.
- Requirements are defined.
- File scopes are independent.
- Shared contracts are stable.
- Database changes are compatible.
- Test environments are isolated.
- No conflicting task ownership exists.
- Integration risks are understood.

## Parallel-Safe Example

Claude:

Implement marketplace course cards.

Files:
lib/features/marketplace/**

Codex:

Implement payment webhook tests.

Files:
supabase/functions/payment-provider-webhook/**

These tasks may run independently
when their prerequisites are satisfied.

## Parallel-Unsafe Example

Claude:

Refactor app_router.dart.

Codex:

Modify the same app_router.dart.

These tasks require coordination
or sequential implementation.

## API Dependency Example

Claude:

Implement checkout interface.

Codex:

Implement checkout backend.

Parallel implementation is possible
after the API contract is approved.

---

# 11. DEVELOPMENT WORKSPACE ISOLATION

Every active task must have
an independent development workspace.

Preferred on the same computer:
Git worktrees.

Preferred on different computers:
Separate Git clones.

Do not run both agents against
the same mutable working directory.

## Why Isolation Matters

Isolation prevents:

- Accidental file overwrites
- Conflicting uncommitted changes
- Shared branch corruption
- Confusing Git state
- Unintended staging
- Unrelated commits

Git worktrees isolate working files
and branches, but share repository metadata.

They do not automatically isolate:

- Database servers
- Local service ports
- External Supabase projects
- Shared cloud resources
- Production credentials

These require separate controls.

---

# 12. GIT WORKTREE SETUP

## 12.1 Update Main Repository

From the main checkout:

```bash
git fetch origin
git switch main
git pull --ff-only
```

## 12.2 Create Claude Worktree

Example:

```bash
git worktree add \
  ../acedra-claude-csa-083 \
  -b feat/csa-083-course-grid \
  origin/main
```

Claude should work in:

../acedra-claude-csa-083

## 12.3 Create Codex Worktree

Example:

```bash
git worktree add \
  ../acedra-codex-csa-102 \
  -b security/csa-102-payment-webhook \
  origin/main
```

Codex should work in:

../acedra-codex-csa-102

## 12.4 Verify Worktrees

```bash
git worktree list
```

## 12.5 Worktree Rules

- One active task branch per worktree.
- Never modify another agent's worktree.
- Never delete an active worktree.
- Never overwrite another agent's files.
- Never use the same branch in two worktrees.
- Never clean another agent's uncommitted files.
- Keep task build artifacts local.

## 12.6 Different Account Environments

If Claude and Codex execute in separate
cloud or local environments:

- Clone the same authorized repository.
- Use unique task branches.
- Fetch updates from GitHub.
- Use GitHub Issues to coordinate.
- Submit independent pull requests.

Git worktrees are not required
across physically separate clones.

Branch and task isolation remain mandatory.

---

# 13. BRANCH NAMING CONVENTIONS

Default branch:

main

Approved branch prefixes:

feat/
fix/
refactor/
test/
docs/
security/
hotfix/
chore/

Required format:

<type>/csa-<id>-<short-description>

Examples:

feat/csa-063-registration

feat/csa-083-course-grid

feat/csa-143-pdf-reader

security/csa-102-payment-webhook

fix/csa-076-session-handling

docs/csa-007-architecture-review

## Branch Rules

- Create branches from the approved base.
- Keep one logical scope per branch.
- Do not push directly to main.
- Do not force-push main.
- Do not rewrite another agent's commits.
- Avoid long-lived branches.
- Integrate completed tasks promptly.

---

# 14. GIT DEVELOPMENT WORKFLOW

## Step 1 - Enter Your Worktree

Example:

```bash
cd ../acedra-claude-csa-083
```

## Step 2 - Verify Branch

```bash
git status
git branch --show-current
```

## Step 3 - Implement Changes

Work only within assigned scope.

## Step 4 - Review Changes

```bash
git diff
git status
```

## Step 5 - Stage Relevant Files

```bash
git add <relevant-files>
```

Never stage unrelated changes.

## Step 6 - Commit

Example:

```bash
git commit -m "feat(marketplace): add course grid"
```

## Step 7 - Push Branch

```bash
git push -u origin feat/csa-083-course-grid
```

## Step 8 - Open Pull Request

Use the approved PR template.

GitHub CLI example:

```bash
gh pr create \
  --base main \
  --head feat/csa-083-course-grid \
  --title "[CSA-083] Add course grid" \
  --fill
```

Review the generated PR description
and complete all required fields.

Do not merge automatically
without the required verification.

---

# 15. COMMIT MESSAGE STANDARD

Use Conventional Commits.

Format:

type(scope): description

## Approved Types

feat
fix
refactor
test
docs
style
perf
chore
build
ci

The project also permits:

security

for explicitly security-focused changes.

## Examples

feat(auth): add registration form

feat(marketplace): implement course search

feat(payments): add verified webhook

fix(pdf): correct reader navigation

fix(auth): handle expired session

test(enrollment): cover unauthorized access

refactor(courses): simplify repository

docs(architecture): document storage flow

ci(flutter): add analysis workflow

## Commit Rules

- Keep commits focused.
- Use meaningful descriptions.
- Avoid unrelated changes.
- Do not commit generated secrets.
- Do not commit customer data.
- Do not disguise large changes
  as small maintenance commits.

Avoid meaningless messages such as:

update

fixed

final

working

changes

---

# 16. FILE OWNERSHIP POLICY

Every active task must define
its expected writable paths.

Example:

CLAUDE:
lib/features/marketplace/**

CODEX:
supabase/functions/payment-provider-webhook/**

Agents must respect task ownership.

## Ownership Rules

- One task owner per implementation scope.
- No silent modification outside scope.
- No unrelated file rewrites.
- No overwriting unmerged agent changes.
- Shared file changes require coordination.

File ownership is task-based.

Do not permanently assume Claude
owns frontend code or Codex owns backend code.

---

# 17. SHARED FILE RESTRICTIONS

The following files and directories
require explicit coordination:

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
Shared domain models
Shared design tokens

## Shared File Modification Process

1. Identify affected shared files.
2. Review active ownership.
3. Declare proposed changes.
4. Request temporary ownership.
5. Obtain coordination approval.
6. Make focused modifications.
7. Run affected tests.
8. Submit changes for review.
9. Release ownership after the
   approved integration stage.

Avoid simultaneous modification
of the same shared source file.

---

# 18. SHARED FILE LOCKING

Use a logical ownership record.

GitHub Issues or the approved project
coordination mechanism should record locks.

Example:

Resource:
lib/app/router/app_router.dart

Owner:
CLAUDE

Task:
CSA-083

Reason:
Marketplace route integration.

Status:
LOCKED

Release:
After integration PR is merged
or ownership is explicitly transferred.

## Lock Rules

- Every lock has an owner.
- Every lock references an active task.
- Locks must be visible to both agents.
- Do not silently override locks.
- Do not keep locks indefinitely.
- Release locks after approved integration.

GitHub comments and labels are not
atomic filesystem locks.

The project lead resolves simultaneous
or conflicting claims.

If a shared file is unavailable:

- Continue independent work.
- Use an approved interface.
- Request an integration task.
- Wait for ownership coordination
  before modifying the protected scope.

---

# 19. DATABASE MIGRATION COORDINATION

Database changes must follow
ARCHITECTURE.md and SECURITY.md.

## Rules

- One accountable owner per migration.
- Review table relationships.
- Review database grants.
- Review RLS policies.
- Review function privileges.
- Use appropriate constraints.
- Maintain migration ordering.
- Test migrations locally.
- Preserve financial history.

## Parallel Migration Policy

Separate migrations may be authored
concurrently only when their dependencies
and resulting schema are compatible.

Conflicting schema changes must be
serialized by an integration owner.

Never modify another agent's previously
applied or shared migration silently.

Avoid assuming timestamp-based ordering
alone guarantees semantic compatibility.

## Database Testing

Run configured tests:

```bash
supabase test db
```

Test:

- Ownership
- Authorization
- Constraints
- Transaction integrity
- Idempotency
- Migration compatibility

Never use destructive database reset
operations against staging or production
without explicit authorization.

---

# 20. API CONTRACT COORDINATION

Frontend/backend parallel development
requires stable API contracts.

Before implementation, document:

- Function or endpoint name
- Authentication requirements
- Authorization requirements
- Request fields
- Response fields
- Error codes
- Validation rules
- Idempotency
- Expected business-state transitions

## Example

Contract:
create-checkout-order

Frontend:
CLAUDE

Backend:
CODEX

Request:
course_id
payment_method

Response:
order_id
order_status
checkout_information

Sensitive validation:
Backend only.

## Contract Rules

- Approve the contract before parallel work.
- Use typed models where practical.
- Use synthetic mocks during UI development.
- Coordinate breaking contract changes.
- Update both client and server tests.
- Document error responses.

Never use mocked success responses
as evidence that payments were verified.

---

# 21. DEPENDENCY MANAGEMENT

Dependency configuration is shared.

Files:

pubspec.yaml
pubspec.lock

## Adding a Package

Before adding:

1. Check necessity.
2. Review existing alternatives.
3. Check maintenance.
4. Check Flutter Web compatibility.
5. Review security advisories.
6. Check license compatibility.
7. Evaluate bundle-size impact.
8. Explain the dependency in the PR.
9. Coordinate shared file ownership.

## Dependency Rules

- Avoid unnecessary packages.
- Prefer stable supported releases.
- Pin or constrain versions appropriately.
- Commit expected lockfile changes.
- Do not perform unrelated upgrades.
- Run regression tests.
- Coordinate simultaneous dependency changes.

Do not overwrite another agent's
pending dependency modifications.

---

# 22. FLUTTER ARCHITECTURE STANDARDS

Use Feature-First Clean Architecture.

Recommended structure:

lib/
  app/
    router/
    theme/
    layout/

  core/
    constants/
    errors/
    security/
    widgets/

  features/
    authentication/
    marketplace/
    courses/
    checkout/
    payments/
    enrollments/
    learning/
    pdf_reader/
    video_player/
    profile/
    admin/

Feature structure:

presentation/
domain/
data/

Use only necessary layers.

## Rules

- UI must not contain trusted
  financial authorization logic.
- Keep widgets focused.
- Keep data access behind clear boundaries.
- Use descriptive Dart naming.
- Follow null safety.
- Handle async operations safely.
- Dispose of resources correctly.
- Avoid unnecessary widget rebuilds.
- Avoid circular dependencies.
- Prefer simple maintainable abstractions.

Follow:

SOLID
DRY
KISS
YAGNI
SEPARATION OF CONCERNS

---

# 23. UI/UX CONTRIBUTION RULES

All Flutter UI work must follow:

DESIGN_SYSTEM.md

Required:

- Light mode
- Dark mode
- Mobile responsiveness
- Tablet responsiveness
- Desktop responsiveness
- Consistent typography
- Semantic colors
- Shared spacing tokens
- Reusable components
- Accessible interaction
- Loading states
- Error states
- Empty states

Reference layout widths:

Mobile:
390 logical pixels

Tablet:
768 logical pixels

Desktop:
1440 logical pixels

Also test relevant narrow
and intermediate widths.

## Shared Design Rules

Changes to global design tokens
require explicit coordination.

Do not independently modify:

- Primary brand colors
- Typography scale
- Global button themes
- Shared navigation shell
- Shared component APIs
- Responsive breakpoint definitions

## UI PR Requirements

Include relevant:

- Screenshots
- Responsive verification
- Light/dark verification
- Accessibility considerations
- Widget tests

Use synthetic data in screenshots.

---

# 24. STATE MANAGEMENT RULES

Approved:
Riverpod

## Guidelines

- Use immutable state where practical.
- Keep one source of truth.
- Avoid duplicate provider state.
- Keep local UI state local.
- Handle loading and errors.
- Invalidate stale remote data.
- Clear private state after logout.
- Avoid business-critical decisions
  based only on client state.

Riverpod must not replace
backend authorization.

---

# 25. ROUTING RULES

Approved:
go_router

Supported navigation:

- Public routes
- Student routes
- Admin routes
- Checkout routes
- Learning routes
- Protected reader routes

## Rules

- Preserve browser back navigation.
- Support approved deep links.
- Handle unknown routes.
- Handle expired sessions.
- Provide role-aware UI navigation.
- Coordinate edits to shared router files.

Frontend navigation guards improve UX.

Backend checks provide authorization.

Never assume a hidden admin route
is a security boundary.

---

# 26. AUTHENTICATION SECURITY

Authentication changes must follow
SECURITY.md.

Required:

- Approved Supabase Auth integration
- Email verification
- Safe password recovery
- Secure session handling
- Backend authorization
- Least privilege
- Cross-user access testing

Never:

- Store plaintext passwords.
- Log authentication tokens.
- Expose service-role credentials.
- Trust client-generated admin roles.
- Rely only on route guards.

Security-sensitive authentication changes
require appropriate review.

---

# 27. PAYMENT SECURITY CONTRIBUTIONS

Payments are P0-sensitive functionality.

## Mandatory Rules

- Backend determines order price.
- Provider callback is verified.
- Amount and currency are validated.
- Duplicate events are handled safely.
- Financial updates use transactions.
- Course access follows verified payment.
- Audit events are preserved.

Never unlock a course using:

- Frontend success page
- Redirect parameters
- Unverified provider response
- Client-supplied payment status
- Uploaded bank receipt alone

## Parallel Ownership

Only one coordinated implementation
should modify a financial state machine
at a time.

Other agents may implement UI
against the approved API contract.

## Required Tests

- Valid payment
- Invalid notification
- Forged callback
- Amount mismatch
- Currency mismatch
- Duplicate callback
- Concurrent callback
- Failure recovery
- Unauthorized enrollment attempt

Financial correctness is mandatory.

---

# 28. BANK TRANSFER CONTRIBUTIONS

Bank transfer receipts are private
financial documents.

## Requirements

- Authorized receipt uploads
- Private storage
- File validation
- Restricted reviewer access
- Verified bank settlement
- Audited approval/rejection
- Atomic entitlement updates

## Important Rule

Receipt submitted does not mean
payment completed.

A finance administrator must verify
the actual incoming bank transfer.

## Required Tests

- Pending receipt remains locked.
- Rejected receipt remains locked.
- Non-admin cannot approve.
- Duplicate approval is prevented.
- Concurrent review is handled.
- Authorized approval grants enrollment.
- Private receipt access is restricted.

---

# 29. PROTECTED COURSE CONTENT

Paid content must be protected.

Content types:

- PDF
- Video
- Text
- Image

## Backend Requirements

- Authenticate student.
- Verify active entitlement.
- Validate lesson ownership.
- Restrict private storage.
- Apply approved delivery controls.
- Handle access revocation.
- Return safe errors.

## PDF Requirements

- Smooth reading
- Page navigation
- Zoom
- Fit-to-width
- Responsive toolbar
- Progress persistence
- Personalized watermark
- Private document delivery

## Browser Limitation

Flutter Web cannot guarantee blocking
of screenshots, screen recording,
or copying by authorized users.

Do not claim impossible security guarantees.

Protection must balance:

- Security
- Readability
- Accessibility
- Performance

---

# 30. TESTING STRATEGY

Testing is mandatory for
meaningful functionality.

## Types

Unit Tests:
Domain logic.

Widget Tests:
Flutter component interactions.

Integration Tests:
Complete user workflows.

Database Tests:
Constraints, transactions, and RLS.

Security Tests:
Unauthorized and adversarial inputs.

Accessibility Tests:
Keyboard and screen-reader behavior.

## Required Test Rules

- Test success paths.
- Test failure paths.
- Use synthetic data.
- Keep tests deterministic.
- Isolate mutable test state.
- Mock external services appropriately.
- Verify critical permissions against
  actual database policies.
- Do not use production customer data.

---

# 31. TEST-DRIVEN DEVELOPMENT

Follow TDD for critical behavior.

RED:
Write a meaningful failing test.

GREEN:
Implement the smallest correct solution.

REFACTOR:
Improve internal structure.

VERIFY:
Run regression tests.

Prioritize TDD for:

- Payments
- Enrollments
- Bank transfer approval
- Administrative permissions
- Course authorization
- Database functions
- Important state transitions

UI features should use widget,
golden, and interaction tests
where appropriate.

Never delete meaningful assertions
to make tests pass.

---

# 32. REQUIRED VERIFICATION COMMANDS

Run applicable commands from
the agent's isolated workspace.

## Dart Formatting

```bash
dart format --output=none --set-exit-if-changed .
```

## Flutter Analysis

```bash
flutter analyze
```

## Flutter Tests

```bash
flutter test
```

## Flutter Web Build

```bash
flutter build web --release
```

## Supabase Database Tests

After local test infrastructure
is configured:

```bash
supabase test db
```

Also run:

- Affected integration tests
- Edge Function tests
- Payment sandbox tests
- Security tests
- Migration validation

## Verification Reporting

For each check, report:

- Command
- Result
- Relevant failures
- Checks not executed

Never claim a command passed
unless it actually ran successfully.

---

# 33. PARALLEL TEST ENVIRONMENTS

Separate worktrees do not automatically
provide isolated backend state.

Agents must avoid conflicting use of:

- Mutable test databases
- Shared local Supabase services
- Service ports
- Shared temporary directories
- Storage fixtures
- Payment sandbox transactions
- Shared environment configuration

## Recommended Approach

Each agent uses:

- Its own workspace
- Its own local configuration
- Isolated or namespaced test data
- Unique test identifiers
- Controlled external provider mocks

If true isolation is unavailable:

Serialize tests that modify
shared infrastructure.

Never run destructive tests
against a shared production resource.

---

# 34. GITHUB PULL REQUEST RULES

Every meaningful change should
be submitted through a PR.

## PR Title

[CSA-XXX] type(scope): description

Example:

[CSA-083] feat(marketplace): add course grid

## Required PR Fields

Task ID:
Agent:
Confirmed Owner:
Branch:
Base Branch:
Related Issue:
Requirements:
Dependencies:
Summary:
Files Changed:
Shared Files Changed:
Tests Executed:
Security Review:
UI/UX Verification:
Known Limitations:
Related Contracts:

## PR Size

Prefer focused, reviewable changes.

A PR should normally implement
one bounded task.

Avoid combining unrelated:

- UI redesign
- Backend refactor
- Dependency upgrade
- Database migration
- Security configuration changes

Split large work into
independent PRs where practical.

---

# 35. PULL REQUEST TEMPLATE

Suggested template:

## Task Information

Task ID:
Owner:
Agent:
Related Issue:

## Summary

Describe the implementation.

## Requirements

List SRS requirement identifiers.

## Files Changed

List important files.

## Shared File Coordination

Were protected/shared files modified?

If yes, record approved ownership.

## API/Schema Changes

List changed contracts and migrations.

## Testing

- [ ] Formatting checked
- [ ] Static analysis passed
- [ ] Unit tests passed
- [ ] Widget tests passed
- [ ] Integration tests passed
- [ ] Database tests passed
- [ ] Security tests passed

Only check items actually verified.

## UI/UX

- [ ] Light theme checked
- [ ] Dark theme checked
- [ ] Mobile layout checked
- [ ] Tablet layout checked
- [ ] Desktop layout checked
- [ ] Accessibility checked

Use N/A when appropriate.

## Security Review

Describe relevant authorization,
privacy, or payment implications.

## Risks

List known issues or limitations.

## Documentation

List updated project documents.

## Review Notes

Identify areas requiring attention.

---

# 36. CROSS-AGENT CODE REVIEW

Claude may review Codex PRs.

Codex may review Claude PRs.

## Review Responsibilities

- Correctness
- Architecture consistency
- Scope compliance
- Security
- Test quality
- API compatibility
- Database integrity
- Accessibility
- Maintainability
- Performance implications

## Example

Claude implements:
Course catalog UI.

Codex reviews:
Data model assumptions and test behavior.

Codex implements:
Bank payment verification.

Claude reviews:
API contract and integration behavior.

## Important Limitation

AI cross-review is useful but does not
automatically count as an independent
human security approval.

High-risk changes require authorized
review according to SECURITY.md.

Agents must not claim their own
self-review is independent review.

---

# 37. CODE REVIEW REQUIREMENTS

Before approving a PR:

1. Read the task requirements.
2. Review the complete diff.
3. Check scope boundaries.
4. Check shared-file changes.
5. Review business correctness.
6. Evaluate security.
7. Evaluate tests.
8. Check dependency changes.
9. Check UI/UX where applicable.
10. Verify CI status.
11. Confirm documentation.
12. Identify unresolved risks.

## Review Outcomes

APPROVE:
Ready under project policy.

REQUEST CHANGES:
Corrections required.

COMMENT:
Clarification or optional improvement.

Do not approve known critical
financial or authorization defects.

Review must be constructive
and technically grounded.

---

# 38. MERGE STRATEGY

Recommended merge method:

Squash Merge

Each merged PR should have
a traceable task identifier.

## Merge Requirements

- Required CI checks pass.
- Required reviews complete.
- Task acceptance criteria satisfied.
- No unresolved critical conflicts.
- Shared contracts compatible.
- Database migration ordering reviewed.
- Security-sensitive tests pass.
- Documentation updated.

## Integration Order

Follow dependency order.

Example:

Database schema
  -> Backend authorization
  -> API contract integration
  -> Frontend integration
  -> End-to-end verification

Independent PRs may merge
in either order after validation.

## Main Branch Rules

- No routine direct pushes.
- No unauthorized force-push.
- No unreviewed sensitive changes.
- No known release-blocking regressions.

If GitHub plan restrictions prevent
automated enforcement, follow the
equivalent documented manual workflow.

---

# 39. MERGE CONFLICT RESOLUTION

When two branches conflict:

1. Stop automatic integration.
2. Preserve both branches.
3. Identify conflicting files.
4. Identify responsible owners.
5. Review intended changes.
6. Determine correct combined behavior.
7. Assign an integration owner.
8. Resolve conflicts deliberately.
9. Re-run affected tests.
10. Request appropriate review.

Never:

- Automatically discard another agent's work.
- Use blanket ours/theirs resolution
  without reviewing the conflict.
- Force-push main.
- Delete tests to simplify integration.
- Silently weaken database permissions.
- Change financial rules only
  to make a merge succeed.

Complex conflicts require
a dedicated integration task.

---

# 40. DEPENDENCY-AWARE INTEGRATION

Before integrating parallel branches,
review the combined architecture.

## Questions

- Are API contracts compatible?
- Are database migrations ordered?
- Are domain models consistent?
- Do routes conflict?
- Are shared dependencies compatible?
- Are authorization policies correct?
- Do payment states remain valid?
- Does the integrated UI still work?
- Are tests passing together?

## Integration Verification

Passing isolated task tests
does not prove the combined
application is correct.

Run appropriate integration tests
after combining changes.

Do not mark a milestone complete
before integrated acceptance.

---

# 41. GITHUB ACTIONS / CI

CI must validate code quality.

Minimum Flutter pipeline:

1. Dart formatting
2. Flutter analysis
3. Unit/widget tests
4. Flutter Web build

Add when configured:

5. Database migration tests
6. RLS security tests
7. Edge Function tests
8. Payment verification tests
9. Dependency scanning
10. Secret scanning
11. Integration tests

## CI Security Rules

- Use minimal workflow permissions.
- Restrict deployment credentials.
- Do not expose secrets to untrusted PR code.
- Review third-party GitHub Actions.
- Prefer pinning third-party Actions
  to reviewed immutable commit SHAs.
- Avoid unsafe shell interpolation.
- Review pull_request_target usage carefully.
- Never disable CI simply
  to make a PR mergeable.

## Failed CI

When a check fails:

1. Inspect actual logs.
2. Identify the root cause.
3. Fix the underlying issue.
4. Re-run relevant checks.
5. Submit corrected changes.

Do not suppress legitimate failures.

---

# 42. TASK COMPLETION AND HANDOFF

Each agent must provide
a completion or handoff report.

## Task Details

Task ID:
Title:
Agent:
Confirmed Owner:
Status:

## Source Control

Branch:
Commit:
Pull Request:
Base Revision:

## Implementation Summary

Describe actual completed work.

## Files Changed

List affected files.

## Shared Contracts

List changed APIs and schemas.

## Testing

Commands executed:
Results:
Checks not executed:

## Security

Describe relevant verification.

## UI/UX

Describe tested sizes and themes.

## Limitations

Describe remaining work or risks.

## Next Action

Identify follow-up work.

Never rely on undocumented
conversation history for handoffs.

---

# 43. BLOCKER MANAGEMENT

When blocked:

1. Identify the blocker.
2. Record the affected task.
3. Identify the dependency.
4. Identify the responsible owner.
5. Update the GitHub Issue.
6. Explain the necessary decision.
7. Continue independent approved work
   when possible.

Do not duplicate another agent's task
merely to bypass a dependency.

Do not introduce insecure temporary
workarounds for critical functionality.

---

# 44. DOCUMENTATION SYNCHRONIZATION

Project documentation must accurately
reflect approved implementation behavior.

## Source Responsibilities

PLAN.md:
Roadmap and phase status.

TASKS.md:
Master task registry.

SRS.md:
System requirements.

ARCHITECTURE.md:
Technical boundaries.

DESIGN_SYSTEM.md:
UI/UX standards.

SECURITY.md:
Security requirements.

CONTRIBUTING.md:
Contribution process.

AGENTS.md:
Agent execution rules.

PARALLEL_WORKFLOW.md:
Agent coordination details.

## Synchronization Rules

- Keep task progress in GitHub.
- Reconcile TASKS.md at milestones.
- Coordinate shared documentation edits.
- Update relevant ADRs.
- Preserve requirement traceability.
- Do not invent completed features.
- Do not leave important contract
  changes undocumented.

---

# 45. ETHICS AND PROFESSIONAL CONDUCT

All contributors must act responsibly.

## Expected Conduct

- Respect other contributors.
- Communicate clearly.
- Provide constructive reviews.
- Acknowledge mistakes.
- Protect confidential information.
- Respect software licenses.
- Respect copyright.
- Avoid discriminatory behavior.
- Report important risks honestly.

## Product Ethics

Never implement:

- Deceptive payment messages
- Fake reviews
- Artificial scarcity without evidence
- Secret student screen recording
- Unnecessary personal data collection
- Hidden financial manipulation
- False PDF protection guarantees

Students must receive accurate
information about payments,
course access, and privacy.

---

# 46. SECURITY INCIDENT PROCEDURE

Examples:

- Payment bypass
- Unauthorized course access
- Exposed bank receipts
- Compromised credentials
- Privilege escalation
- Production outage

## Emergency Steps

1. Report the incident.
2. Determine severity.
3. Contain immediate risk.
4. Pause conflicting changes.
5. Assign one incident owner.
6. Create a focused hotfix.
7. Run critical tests.
8. Obtain appropriate review.
9. Deploy through approved procedure.
10. Verify recovery.
11. Document the incident.

During critical incidents,
conflicting parallel development
must be paused.

No agent may independently
deploy sensitive emergency changes
without authorization.

---

# 47. CONTRIBUTOR DEFINITION OF READY

A task is READY when:

- [ ] Task ID exists.
- [ ] Requirements are clear.
- [ ] Priority is assigned.
- [ ] Dependencies are resolved.
- [ ] Acceptance criteria are testable.
- [ ] Architecture is defined.
- [ ] Security impact is considered.
- [ ] API contracts exist if required.
- [ ] File scope is documented.
- [ ] Shared ownership conflicts resolved.
- [ ] No critical decision blocks work.

READY is not the same as CLAIMED.

Implementation begins only
after confirmed assignment.

---

# 48. CONTRIBUTOR DEFINITION OF DONE

A contribution is DONE only when:

- [ ] Requirements are satisfied.
- [ ] Scope is respected.
- [ ] Architecture rules are followed.
- [ ] Relevant tests are implemented.
- [ ] Tests actually pass.
- [ ] Static analysis passes.
- [ ] Security boundaries are verified.
- [ ] Error handling is implemented.
- [ ] UI follows the design system.
- [ ] Relevant responsive layouts checked.
- [ ] Accessibility considered.
- [ ] No secrets committed.
- [ ] No private student data exposed.
- [ ] Shared-file changes coordinated.
- [ ] Documentation updated.
- [ ] CI checks pass.
- [ ] Required reviews complete.
- [ ] Changes merged or formally accepted.
- [ ] Completion evidence recorded.

Generated code is not automatically
verified code.

An open PR is normally IN_REVIEW,
not DONE.

---

# 49. PARALLEL WORKFLOW ACCEPTANCE

Before regular two-agent development:

- [ ] AGENTS.md v2 approved.
- [ ] TASKS.md v2 approved.
- [ ] CONTRIBUTING.md v2 approved.
- [ ] CLAUDE.md created.
- [ ] PARALLEL_WORKFLOW.md created.
- [ ] GitHub Issue workflow configured.
- [ ] Agent ownership fields defined.
- [ ] Branch naming rules approved.
- [ ] Worktree isolation demonstrated.
- [ ] Shared-file coordination tested.
- [ ] CI pipeline operational.
- [ ] PR review policy defined.
- [ ] Integration procedure documented.
- [ ] Controlled two-agent dry-run completed.

Do not increase parallelism
until the coordination process
is operating reliably.

---

# 50. RECOMMENDED INITIAL AGENT ALLOCATION

The following is a proposed division.

CLAUDE:

- Flutter project layout
- Light/dark theme
- Reusable UI components
- Authentication screens
- Marketplace UI
- Checkout UI
- Learning workspace
- PDF reader UI
- Admin dashboard UI

CODEX:

- Supabase setup
- PostgreSQL schema
- RLS permissions
- Authentication backend
- Course data policies
- Payment verification
- Bank transfer backend
- Enrollment authorization
- Protected media access
- Backend testing
- CI/CD infrastructure

These are suggestions.

Actual ownership must be recorded
through GitHub tasks.

Do not begin work when required
contracts or prerequisites are missing.

---

# 51. MULTI-AGENT CONTRIBUTION CHECKLIST

Before starting:

- [ ] Read project rules.
- [ ] Confirm task ownership.
- [ ] Check dependencies.
- [ ] Identify file scope.
- [ ] Check shared-file locks.
- [ ] Create isolated workspace.

During implementation:

- [ ] Follow architecture.
- [ ] Respect scope.
- [ ] Preserve security.
- [ ] Add relevant tests.
- [ ] Avoid unrelated changes.
- [ ] Coordinate contract changes.

Before PR:

- [ ] Review diff.
- [ ] Run relevant checks.
- [ ] Check secrets.
- [ ] Check permissions.
- [ ] Verify UI if applicable.
- [ ] Update documentation.
- [ ] Prepare handoff notes.

Before merge:

- [ ] CI passes.
- [ ] Required reviews complete.
- [ ] Contracts are compatible.
- [ ] No unresolved conflicts.
- [ ] Acceptance criteria satisfied.

After merge:

- [ ] Verify integration.
- [ ] Update task status.
- [ ] Release temporary locks.
- [ ] Refresh dependent branches.
- [ ] Remove worktree when safe.

---

# 52. FINAL CONTRIBUTION DIRECTIVE

Acedra must be built through
disciplined professional engineering.

Claude and Codex may work simultaneously
only when their tasks are independent
or correctly coordinated.

Every contribution must have:

- Clear requirements
- One accountable owner
- Explicit file scope
- Isolated workspace
- Approved architecture
- Stable shared contracts
- Secure implementation
- Relevant tests
- Reviewable commits
- A tracked GitHub pull request
- Verified integration
- Accurate completion reporting

No agent may silently overwrite
another agent's work.

No agent may bypass payment verification.

No agent may disable access controls
to resolve development problems.

No agent may invent passing tests.

No agent may deploy without authorization.

No agent may misrepresent the security
capabilities of Flutter Web.

Every change must improve the product
without weakening student trust.

ONE TASK - ONE OWNER.
ONE TASK - ONE BRANCH.
ISOLATED WORKSPACES.
SHARED CONTRACTS.
CONTROLLED INTEGRATION.
SECURITY BY DESIGN.
TEST BEFORE MERGE.
REVIEW CRITICAL CHANGES.
VERIFIABLE QUALITY.

END OF CONTRIBUTING.md
