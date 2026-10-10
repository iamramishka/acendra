
# AGENTS.md
# Acedra - AI Engineering & Parallel Development Rules

Document ID: CSA-AGENTS-001
Version: 2.0
Status: Proposed - Pending Approval
Project: Acedra Course Selling Application
Primary Platform: Flutter Web
Backend: Supabase + PostgreSQL
Architecture: Feature-First Clean Architecture
Development Model: Parallel Multi-Agent Development
AI Agents: Claude Code + OpenAI Codex
Version Control: Git + GitHub
Development Method: Specification-First + TDD
Classification: Internal Engineering Documentation

---

# 1. PURPOSE

This document establishes mandatory engineering
instructions for all AI coding agents and
developers contributing to Acedra.

The project uses two primary AI coding agents:

1. Claude Code
2. OpenAI Codex

These agents may implement independent tasks
simultaneously.

The objective is to increase development
productivity without compromising:

- Security
- Correctness
- Student privacy
- Financial integrity
- Architecture consistency
- Code quality
- Reliability
- Accessibility
- Maintainability
- Test coverage
- Git history
- Production stability

Parallel development must be coordinated.

Never prioritize parallel execution
over correctness or security.

---

# 2. CORE ENGINEERING DIRECTIVE

All contributors must follow:

SECURITY FIRST.
CORRECTNESS BEFORE SPEED.
PRIVACY BY DESIGN.
CLEAN ARCHITECTURE.
SMALL REVIEWABLE CHANGES.
TEST-DRIVEN DEVELOPMENT.
CLEAR TASK OWNERSHIP.
ISOLATED WORKSPACES.
CONTROLLED INTEGRATION.
HONEST VERIFICATION.

No agent may weaken these principles
to complete a task faster.

---

# 3. INSTRUCTION PRIORITY

Follow applicable instructions in this order:

1. System and platform safety instructions
2. Current authorized user requirements
3. Repository-wide AGENTS.md
4. Scoped agent instructions for relevant paths
5. Approved project specifications and policies
6. Existing code conventions

Relevant project documentation includes:

- PLAN.md
- TASKS.md
- SRS.md
- ARCHITECTURE.md
- DATABASE_DESIGN.md
- DESIGN_SYSTEM.md
- SECURITY.md
- CONTRIBUTING.md
- TESTING.md
- docs/PARALLEL_WORKFLOW.md
- Approved architecture decision records

Important:

Specialized instructions must not
silently override security requirements.

When instructions conflict:

- Identify the conflict.
- Follow higher-priority instructions.
- Preserve secure behavior.
- Seek an authorized decision when required.
- Document material deviations.

Do not invent missing business policies.

Do not claim unavailable documentation
was reviewed.

---

# 4. MULTI-AGENT DEVELOPMENT MODEL

Acedra uses a coordinated parallel
development model.

Conceptual structure:

                  PROJECT OWNER
                        |
                 PLAN.md / SRS.md
                        |
               GitHub Task Backlog
                        |
              Task Allocation Process
                        |
             +----------+----------+
             |                     |
        CLAUDE CODE             CODEX
             |                     |
         Task Owner A          Task Owner B
             |                     |
         Worktree A            Worktree B
             |                     |
         Branch A              Branch B
             |                     |
         Tests + PR            Tests + PR
             |                     |
             +----------+----------+
                        |
                Integration Review
                        |
                 CI / Security QA
                        |
                  Approved Merge
                        |
                  MAIN BRANCH

Claude and Codex are independent workers.

Neither agent may assume control
of the other agent's active task.

Both agents must use the same approved
project architecture and requirements.

---

# 5. AGENT IDENTITIES AND RESPONSIBILITIES

## 5.1 Claude Code

Agent Identifier:
CLAUDE

Responsibilities may include:

- Flutter development
- UI/UX implementation
- Feature development
- Backend implementation
- Testing
- Code review
- Documentation

Claude is not permanently restricted
to frontend work.

Task assignments determine responsibility.

## 5.2 OpenAI Codex

Agent Identifier:
CODEX

Responsibilities may include:

- Flutter development
- Backend implementation
- Database migrations
- API development
- Testing
- Code review
- Documentation

Codex is not permanently restricted
to backend work.

Task assignments determine responsibility.

## 5.3 Ownership Rule

A development task must have
one accountable implementation owner.

Example:

CSA-083:
Owner = CLAUDE

CSA-102:
Owner = CODEX

Both agents may review a task.

Only the assigned owner may modify
its implementation unless reassignment
or coordinated collaboration is approved.

## 5.4 Agent Independence

Each agent must:

- Maintain its own worktree or clone.
- Use its assigned branch.
- Follow its assigned scope.
- Commit its own changes.
- Run relevant tests.
- Submit its own PR.
- Report actual results.

Agents must not silently edit
each other's working files.

---

# 6. TASK ALLOCATION RULES

TASKS.md maintains the master task registry.

GitHub Issues should become the live
coordination source once configured.

Each active task must contain:

Task ID:
Task Title:
Priority:
Assigned Agent:
Status:
Dependencies:
Allowed File Scope:
Restricted Shared Files:
Git Branch:
Worktree or Clone:
Related SRS Requirements:
Acceptance Criteria:
Required Tests:
Related Pull Request:
Completion Evidence:

Example:

Task ID:
CSA-083

Title:
Implement Responsive Course Grid

Priority:
P1

Assigned Agent:
CLAUDE

Status:
IN_PROGRESS

Dependencies:
CSA-039, CSA-047, CSA-077

Allowed File Scope:
lib/features/marketplace/**

Restricted Shared Files:
lib/app/router/**
pubspec.yaml

Branch:
feat/csa-083-course-grid

Worktree:
../acedra-claude-csa-083

Acceptance Criteria:
Responsive course grid renders correctly
in light and dark themes.

The owner must not expand the task scope
without coordination.

---

# 7. TASK STATUS LIFECYCLE

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

Task is identified but not ready.

## READY

Requirements and dependencies are ready.

## CLAIMED

An agent has been assigned ownership.

## IN_PROGRESS

Implementation has started.

## BLOCKED

Task cannot proceed safely.

## IN_REVIEW

Implementation is awaiting review,
CI verification, or acceptance.

## DONE

All acceptance requirements are verified.

## CANCELLED

Task was removed through approved
scope change.

Never mark a task DONE because
code was merely generated.

---

# 8. TASK CLAIMING PROTOCOL

Before starting implementation:

1. Read AGENTS.md.
2. Read the relevant GitHub Issue.
3. Read the task in TASKS.md.
4. Confirm prerequisites are complete.
5. Check the current task owner.
6. Check the allowed file scope.
7. Check for active overlapping tasks.
8. Confirm the branch naming convention.
9. Confirm workspace isolation.
10. Record task ownership.
11. Only then begin implementation.

If a task is already assigned:

DO NOT claim it again.

If another agent is working
on the same feature or files:

STOP and coordinate.

Never assume an inactive terminal
means a task has been abandoned.

A reassignment must be recorded
through the agreed coordination process.

---

# 9. PARALLEL TASK ELIGIBILITY

Tasks may run in parallel only when:

- Requirements are sufficiently defined.
- Dependencies are satisfied.
- File ownership does not conflict.
- Database changes do not conflict.
- API contracts are stable.
- No critical shared state is being modified.
- Both tasks have independent acceptance criteria.
- Integration risks are understood.

Parallel development is preferred
for independent modules.

Sequential development is required
when one task depends on unfinished
output from another.

---

# 10. PARALLEL EXECUTION EXAMPLES

## SAFE EXAMPLE

Claude:

Task:
CSA-083 - Course Grid UI

Files:
lib/features/marketplace/**

Codex:

Task:
CSA-102 - Payment Provider Webhook

Files:
supabase/functions/payment-provider-webhook/**

These tasks can proceed in parallel
after their shared API/data contracts
and dependencies are approved.

## UNSAFE EXAMPLE

Claude:

Task:
Modify authentication session service.

Codex:

Task:
Refactor the same authentication service.

Problem:

Both agents may change the same files
and assumptions.

Required Action:

- Divide ownership more precisely, or
- Complete tasks sequentially.

## DEPENDENCY EXAMPLE

Claude:

Implement student checkout UI.

Codex:

Implement checkout backend.

Parallel work is allowed if:

- Request/response contracts are approved.
- Error codes are agreed.
- Mock responses are clearly identified.
- Neither agent changes the contract silently.

Contract changes require coordination.

---

# 11. PARALLELISM DECISION MATRIX

| Situation | Policy |
|-----------|--------|
| Separate feature modules | Parallel allowed |
| Same file | Sequential by default |
| Same shared API contract | Coordinate first |
| Same database table migration | Serialize |
| Same payment state machine | Serialize |
| Independent UI and tests | Parallel allowed |
| Independent documentation | Parallel allowed |
| Shared architecture changes | Controlled ownership |
| Different worktrees | Required |
| Shared working directory | Prohibited |

Parallelism is not an excuse
to duplicate or overwrite work.

---

# 12. GIT WORKTREE POLICY

Each active agent task must use
an isolated Git working directory.

Preferred:
Git worktrees for a shared local repository.

Alternative:
Separate clones for agents running
on different machines or environments.

Do not run Claude and Codex
in the same mutable working tree
at the same time.

## 12.1 Claude Worktree Example

From the main repository:

```bash
git fetch origin

git worktree add \
  ../acedra-claude-csa-083 \
  -b feat/csa-083-course-grid \
  origin/main
```

Claude must work inside:

../acedra-claude-csa-083

## 12.2 Codex Worktree Example

```bash
git fetch origin

git worktree add \
  ../acedra-codex-csa-102 \
  -b feat/csa-102-payment-webhook \
  origin/main
```

Codex must work inside:

../acedra-codex-csa-102

## 12.3 Worktree Rules

- One worktree per active task branch.
- Never edit another agent's worktree.
- Never delete an active agent's worktree.
- Never use the same branch in two worktrees.
- Do not run destructive Git operations
  against other active tasks.
- Keep temporary build files local.
- Use separate local runtime configuration
  where concurrent services could conflict.

## 12.4 Cleanup

After successful merge and verification:

```bash
git worktree list
```

Remove only the completed,
safe-to-delete worktree.

Example:

```bash
git worktree remove ../acedra-claude-csa-083
```

Do not remove a worktree containing
important uncommitted work.

---

# 13. BRANCH MANAGEMENT

Default branch:

main

Allowed task branches:

feat/
fix/
refactor/
test/
docs/
security/
hotfix/
chore/

Branch format:

<type>/csa-<task-id>-<description>

Examples:

feat/csa-083-course-grid

feat/csa-143-pdf-reader

security/csa-102-payment-webhook

fix/csa-076-session-expiry

docs/csa-007-architecture-update

## Mandatory Rules

- Do not commit directly to main.
- Do not force-push main.
- Do not share an active implementation branch
  between independent agents.
- Do not rewrite another agent's commits.
- Do not merge unreviewed critical changes.
- Do not use unrelated branches for task work.

If an agent needs another agent's changes,
use the agreed integration process.

Do not silently copy incomplete code
between branches.

---

# 14. FILE OWNERSHIP AND CONFLICT PREVENTION

Each task must define its writable scope.

## 14.1 Feature Ownership

Example:

Claude owns:

lib/features/marketplace/**

Codex owns:

supabase/functions/payment-provider-webhook/**

Neither agent may modify files
outside its agreed task scope
without authorization.

## 14.2 Shared Files

The following require special coordination:

- AGENTS.md
- PLAN.md
- TASKS.md
- ARCHITECTURE.md
- SECURITY.md
- DESIGN_SYSTEM.md
- CONTRIBUTING.md
- pubspec.yaml
- pubspec.lock
- lib/app/router/**
- lib/app/theme/**
- lib/core/**
- supabase/migrations/**
- .github/workflows/**
- Shared API contracts
- Shared domain models

These files are not permanently owned
by one particular agent.

They require temporary ownership
or a designated integration task.

## 14.3 Shared File Rule

Before modifying a shared file:

1. Check active tasks.
2. Confirm no conflicting owner exists.
3. Obtain temporary ownership.
4. Record the intended modification.
5. Make the smallest required change.
6. Run relevant tests.
7. Release ownership after review
   or completion of the agreed stage.

An agent must not overwrite
another agent's pending shared-file change.

---

# 15. SHARED FILE LOCKING

Use a lightweight logical locking system.

GitHub Issues or a dedicated coordination
board may record temporary shared ownership.

Example:

Resource:
lib/app/router/app_router.dart

Owner:
CLAUDE

Reason:
Register marketplace navigation

Related Task:
CSA-083

State:
LOCKED

Release Condition:
Associated integration change merged
or ownership explicitly handed off.

## Locking Rules

- Locks must have clear owners.
- Locks must reference actual work.
- Locks are logical coordination rules,
  not Git filesystem locks.
- Do not silently override active locks.
- Do not keep locks indefinitely.
- Release locks promptly when safe.
- Escalate stale locks for review.

If a shared file is locked:

Do not edit it.

Instead:

- Work on independent files.
- Use an approved extension point.
- Create a follow-up integration task.
- Coordinate a handoff.

---

# 16. DATABASE MIGRATION OWNERSHIP

Database migrations are high-risk
shared architectural changes.

Concurrent migration development
requires strict coordination.

## Rules

- One accountable owner per migration.
- Migration dependencies must be explicit.
- Avoid conflicting schema assumptions.
- Do not modify another agent's migration
  after it has been applied or shared.
- Do not create inconsistent table policies.
- Review grants and RLS together.
- Test migration ordering.
- Never reset production data.

## Migration Coordination

If Claude requires a new column
and Codex requires a different column
on the same table:

1. Agree on the target schema.
2. Assign a migration owner.
3. Create the approved migration.
4. Test the schema change.
5. Publish the finalized contract.
6. Allow dependent agents to proceed.

Independent migrations may be developed
in parallel only if ordering and
compatibility have been reviewed.

Production database changes
require explicit release approval.

---

# 17. API CONTRACT COORDINATION

Shared API contracts must be defined
before dependent implementation.

Contracts should document:

- Endpoint or function name
- Authentication requirements
- Authorization requirements
- Request structure
- Response structure
- Error codes
- Validation rules
- Idempotency expectations
- Relevant data models

## Example

Function:
create-checkout-order

Request:
course_id
payment_method

Response:
order_id
payment_method
checkout_information
order_status

Backend:
Codex assigned

Frontend:
Claude assigned

The frontend may use synthetic mocks
matching the agreed contract.

Mock responses must not be presented
as real verified payment results.

## Contract Change Rule

If the backend contract changes:

- Notify affected task owners through
  the agreed GitHub coordination channel.
- Record the changed contract.
- Review frontend impact.
- Update relevant tests.
- Approve the change before integration.

Never silently break another agent's API.

---

# 18. CLAUDE AND CODEX COMMUNICATION

Claude and Codex must coordinate
through shared repository artifacts.

Preferred communication channels:

1. GitHub Issues
2. Pull request descriptions and reviews
3. docs/PARALLEL_WORKFLOW.md
4. Approved shared technical documentation
5. Task handoff notes

Do not assume agents can directly
communicate across account sessions.

Do not depend on undocumented memory
or private chat context.

All critical decisions must be recorded
in an accessible project artifact.

## Required Handoff Information

Task:
Owner:
Branch:
Commit/PR:
Completed Work:
Remaining Work:
Files Changed:
Shared Contracts Changed:
Tests Executed:
Known Risks:
Dependencies:
Next Action:

A handoff must be sufficiently clear
for another agent or human developer
to continue without guessing.

---

# 19. MERGE AND INTEGRATION STRATEGY

Both agents develop against
an approved base branch.

Integration occurs through
reviewed pull requests.

## Required Process

1. Agent completes assigned changes.
2. Agent runs applicable local checks.
3. Agent reviews its own diff.
4. Agent pushes its task branch.
5. Agent opens a pull request.
6. CI executes required checks.
7. Review identifies issues.
8. Agent addresses issues.
9. Required approval is obtained.
10. PR is merged through approved process.
11. Dependent branches refresh their base.
12. Integration tests verify combined behavior.

## Merge Order

Merge according to dependencies.

Example:

Database schema
  -> Backend API
  -> Frontend integration
  -> End-to-end verification

Independent changes may merge
in either order after verification.

Do not merge dependent code
before its required contract exists.

## Merge Authority

Agents must not assume permission
to merge production-sensitive changes.

Financial, authorization, and infrastructure
changes require authorized review.

The project owner or designated maintainer
controls final production integration.

---

# 20. CONFLICT RESOLUTION PROTOCOL

If a Git merge conflict occurs:

1. Stop automatic integration.
2. Identify conflicting files.
3. Identify task owners.
4. Read both intended changes.
5. Determine the correct combined behavior.
6. Check architectural consequences.
7. Resolve the conflict deliberately.
8. Run affected tests again.
9. Request review where required.
10. Record important integration decisions.

Never:

- Automatically discard the other agent's code.
- Use blanket "ours" or "theirs" resolution
  without reviewing the conflict.
- Force-push main.
- Delete tests to resolve merge problems.
- Change public contracts without review.
- Claim integration succeeded without testing.

For complicated conflicts,
assign a dedicated integration task.

---

# 21. PARALLEL WORK LIMITATIONS

Not every task should run simultaneously.

Use sequential development for:

- Conflicting database migrations
- Changes to the same payment state machine
- Major application routing refactors
- Central design token changes
- Shared authentication architecture
- Unapproved API contract redesigns
- Sensitive production infrastructure changes

Parallel execution should focus on
independent modules and well-defined contracts.

Do not create artificial parallel work
that increases merge complexity.

---

# 22. REQUIRED AGENT DEVELOPMENT WORKFLOW

Each agent must follow:

UNDERSTAND
    |
    v
INSPECT
    |
    v
PLAN
    |
    v
CLAIM TASK
    |
    v
VERIFY ISOLATION
    |
    v
IMPLEMENT
    |
    v
TEST
    |
    v
SELF REVIEW
    |
    v
PULL REQUEST
    |
    v
CI + REVIEW
    |
    v
APPROVED MERGE
    |
    v
UPDATE TASK STATUS

## Step 1 - Understand

Read requirements and acceptance criteria.

## Step 2 - Inspect

Examine the actual repository state.

## Step 3 - Plan

Create a focused implementation plan.

## Step 4 - Claim

Confirm ownership and dependencies.

## Step 5 - Isolate

Use a separate branch and worktree.

## Step 6 - Implement

Follow approved architecture.

## Step 7 - Test

Execute applicable tests.

## Step 8 - Self Review

Inspect security, correctness, and scope.

## Step 9 - PR

Submit changes for review.

## Step 10 - Verify

Pass required automated checks.

## Step 11 - Merge

Merge only through approved workflow.

## Step 12 - Report

Record verified completion.

---

# 23. SUPERPOWERS-STYLE DEVELOPMENT

Use a disciplined specification-first
and test-driven workflow.

For substantial features:

1. Clarify requirements.
2. Identify assumptions.
3. Create an implementation plan.
4. Break work into bounded tasks.
5. Identify independent tasks.
6. Allocate task ownership.
7. Write tests for critical behavior.
8. Implement incrementally.
9. Review changes.
10. Verify integration.

When an approved Superpowers tool or
skill is available, follow its actual
supported instructions.

Do not claim a plugin is installed
unless its availability is verified.

Never let an AI workflow bypass
repository security or review rules.

---

# 24. TEST-DRIVEN DEVELOPMENT

Use TDD for critical business logic.

RED:
Write a meaningful failing test.

GREEN:
Implement the smallest correct change.

REFACTOR:
Improve code without changing behavior.

RETEST:
Run relevant tests again.

Prioritize TDD for:

- Payment verification
- Enrollment grants
- Bank transfer approval
- Admin permissions
- Role assignment
- Course access authorization
- Database permission functions
- Financial state transitions

For UI tasks, apply relevant:

- Widget tests
- Golden tests
- Accessibility checks
- Integration tests

Never modify tests merely
to hide real failures.

---

# 25. TECHNOLOGY STACK RULES

Approved baseline:

Frontend:
- Flutter
- Dart
- Material 3
- Riverpod
- go_router

Backend:
- Supabase
- Supabase Auth
- PostgreSQL
- Row Level Security
- Supabase Edge Functions
- Private Object Storage

Course Content:
- Evaluated Flutter PDF viewer
- Protected video delivery
- Text and image lesson components

Engineering:
- Git
- GitHub
- GitHub Actions
- Flutter Test
- Supabase CLI
- Dart Analyzer

Use approved stable and supported
dependency versions.

New dependencies require justification.

Avoid unnecessary packages.

Agents must coordinate before changing
shared dependency configuration.

---

# 26. SOFTWARE ARCHITECTURE RULES

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

Each feature may contain:

presentation/
domain/
data/

Rules:

- Keep business logic separate from widgets.
- Keep repositories behind clear interfaces.
- Avoid unnecessary abstractions.
- Avoid circular dependencies.
- Keep modules independently testable.
- Do not duplicate trusted backend logic.
- Do not introduce microservices without approval.
- Preserve stable module contracts.

Follow:

SOLID
DRY
KISS
YAGNI
SEPARATION OF CONCERNS

---

# 27. FLUTTER DEVELOPMENT RULES

All Flutter contributions must:

- Follow effective Dart conventions.
- Use null-safe Dart.
- Use descriptive names.
- Prefer immutable state.
- Use const constructors where appropriate.
- Avoid unnecessary widget rebuilds.
- Handle async operations safely.
- Dispose of owned resources.
- Separate UI and data access.
- Reuse approved components.
- Support responsive layouts.
- Respect browser navigation.
- Handle loading, success, and failure states.

Use Riverpod for appropriate
application-level state.

Use go_router for navigation.

Frontend route guards must never be
treated as authorization security controls.

---

# 28. UI/UX DESIGN RULES

All agents must follow DESIGN_SYSTEM.md.

Requirements:

- Light theme
- Dark theme
- Mobile responsiveness
- Tablet responsiveness
- Desktop responsiveness
- Consistent typography
- Consistent spacing
- Semantic colors
- Accessible controls
- Keyboard navigation
- Loading states
- Error states
- Empty states

Reference widths:

Mobile:
390 logical pixels

Tablet:
768 logical pixels

Desktop:
1440 logical pixels

Also test narrow and intermediate widths.

## Design Ownership

Changes to global design tokens
require coordination.

Do not silently change:

- Primary palette
- Typography scale
- Spacing scale
- Button styling
- Navigation shell design
- Shared component APIs

Feature-specific UI may proceed
independently when global contracts
remain unchanged.

---

# 29. AUTHENTICATION AND AUTHORIZATION

Authentication:
Verify the user's identity.

Authorization:
Determine what the user may access.

Rules:

- Use Supabase Auth.
- Never store plaintext passwords.
- Never expose privileged credentials.
- Never trust client-supplied roles.
- Enforce permissions on trusted backend systems.
- Use RLS for protected database records.
- Review database grants.
- Apply least privilege.
- Test cross-user access attempts.
- Protect administrative operations.

Students must not be able to
assign administrative roles.

Frontend navigation restrictions
do not replace backend authorization.

---

# 30. PAYMENT SECURITY

All payment-related work is P0-sensitive.

Never unlock a paid course based only on:

- Frontend success messages
- Payment redirect URLs
- Client-supplied transaction status
- Uploaded bank receipts
- Unverified provider callbacks

The trusted backend must verify:

- Provider authenticity
- Order identifier
- Amount
- Currency
- Transaction status
- Provider reference
- Existing event processing state

Use atomic financial transactions.

Use idempotency protections.

Test duplicate, delayed, forged,
and concurrent payment events.

## Payment Parallelism Rule

Agents must not independently modify
the same financial state machine.

Assign one owner for changes
to critical payment invariants.

Other agents may implement dependent UI
against an approved interface contract.

---

# 31. BANK TRANSFER SECURITY

Bank receipts contain sensitive data.

Mandatory rules:

- Private receipt storage
- Authorized uploads
- File validation
- Finance-role authorization
- Independent bank credit verification
- Auditable approval decisions
- Safe concurrent processing
- Transactional enrollment updates

Receipt submission does not
mean payment is verified.

Only trusted authorized operations
may approve bank transfers.

A rejected or pending payment
must not grant paid access.

---

# 32. ENROLLMENT AND COURSE ACCESS

Paid content access requires
an active valid entitlement.

Before protected content delivery:

1. Authenticate the user.
2. Verify entitlement ownership.
3. Verify course identity.
4. Check entitlement status.
5. Check expiry and revocation.
6. Authorize the requested resource.

Do not allow the Flutter client
to create active paid enrollments directly.

Administrative grants must be
authorized and audited.

Test direct unauthorized API requests.

---

# 33. PDF AND MEDIA SECURITY

Course PDFs are valuable proprietary assets.

Required protection:

- Private storage
- Authenticated access
- Entitlement validation
- Controlled file delivery
- Limited resource access where appropriate
- Personalized watermarking
- Secure reader integration
- Appropriate access logging

Important:

Flutter Web cannot guarantee prevention of:

- Screenshots
- Screen recordings
- Browser developer tool access
- External camera recording
- Copying by determined authorized users

Never claim complete capture prevention.

Signed URLs do not guarantee
that delivered file bytes cannot be copied.

## PDF Reading Experience

Preserve:

- High-quality rendering
- Zoom
- Page navigation
- Fit-to-width
- Comfortable scrolling
- Reading progress
- Responsive controls
- Accessibility

Security and readability
must be evaluated together.

---

# 34. DATABASE DEVELOPMENT RULES

Use reviewed PostgreSQL migrations.

Requirements:

- Primary keys
- Foreign keys
- Appropriate constraints
- Required indexes
- Consistent timestamps
- Exact currency representations
- Transactional financial operations
- Row Level Security
- Reviewed database grants

Never:

- Disable RLS to fix a failing query.
- Modify production data casually.
- Edit another agent's migration silently.
- Expose privileged database functions.
- Delete financial audit history without approval.

Security-sensitive migrations
require additional review.

---

# 35. ENVIRONMENT AND SECRET RULES

Separate:

- Development
- Staging
- Production

Flutter Web may expose:

- Supabase project URL
- Supabase publishable key
- Public feature configuration

Flutter Web must not contain:

- Supabase secret/service-role credentials
- Database administrator passwords
- Payment verification secrets
- Private email service keys
- Private video signing credentials

Do not commit secrets.

Use synthetic test data.

Keep production access restricted.

Agents may not run destructive
production commands without explicit approval.

---

# 36. ERROR HANDLING RULES

Never silently ignore unexpected failures.

Handle:

- Authentication errors
- Authorization errors
- Network errors
- Validation errors
- Payment errors
- Storage errors
- Content access errors
- Database errors
- Unexpected application errors

User-facing errors must be understandable.

Do not expose:

- Internal stack traces
- Credentials
- Sensitive database details
- Private storage references
- Another student's data

Fail closed for security-sensitive operations.

A payment verification failure
must never unlock course access.

---

# 37. PRIVACY AND ETHICS

All development must respect:

- Privacy by Design
- Security by Design
- Data minimization
- Transparency
- Fairness
- Accessibility
- Copyright
- Responsible monitoring

Never implement:

- Secret student screen recording
- Unauthorized personal data collection
- Fake payment confirmations
- Misleading discounts
- Fabricated course reviews
- Hidden financial manipulation
- False claims about PDF security

Payment receipts and financial information
must only be visible to authorized personnel.

Watermark practices must be disclosed.

---

# 38. PERFORMANCE AND RELIABILITY

Optimize based on measured problems.

Focus on:

- Flutter Web startup
- Widget rebuild efficiency
- Course catalog loading
- Database query performance
- Protected content delivery
- PDF rendering
- Video playback
- Image optimization
- Proper loading states
- Safe caching

Do not compromise authorization
to improve perceived performance.

Use pagination for large datasets.

Avoid unnecessary network requests.

Do not cache restricted data beyond
the approved security policy.

---

# 39. DEPENDENCY MANAGEMENT

Before adding a dependency:

1. Explain the requirement.
2. Check existing project solutions.
3. Review maintenance status.
4. Check Flutter/Dart compatibility.
5. Review license compatibility.
6. Check security risks.
7. Consider performance.
8. Consider production costs.
9. Coordinate shared file changes.

Files requiring coordination:

pubspec.yaml
pubspec.lock

Do not independently modify
the dependency graph while another
agent owns a conflicting package update.

Dependency updates must be tested.

---

# 40. REQUIRED VERIFICATION COMMANDS

Before submitting a PR,
run applicable quality checks.

Formatting:

```bash
dart format --output=none --set-exit-if-changed .
```

Static Analysis:

```bash
flutter analyze
```

Unit and Widget Tests:

```bash
flutter test
```

Production Web Build:

```bash
flutter build web --release
```

Database Tests:

```bash
supabase test db
```

Also run relevant backend,
integration, and security tests.

Commands must be run in the
agent's own isolated workspace.

If a check cannot be performed:

- State which check was skipped.
- Explain the limitation.
- Report what remains unverified.

Never invent passing results.

---

# 41. PARALLEL TEST EXECUTION RULES

Agents may run independent tests
at the same time when isolated.

However:

- Do not share mutable test databases.
- Do not share conflicting local ports.
- Do not overwrite shared test fixtures.
- Do not use the same mutable storage bucket
  without an isolation strategy.
- Do not depend on production data.
- Avoid shared temporary output paths.

Each agent should use isolated
test databases or test namespaces
where relevant.

Shared integration tests run after
combined changes are available.

Passing isolated tests does not guarantee
the merged application works.

---

# 42. GITHUB PULL REQUEST RULES

Each agent must create a PR
for its assigned implementation.

## Required PR Information

Task ID:
Agent:
Branch:
Related Issue:
Requirements:
Summary:
Files Changed:
Tests Executed:
Security Impact:
UI/UX Impact:
Shared Contracts Changed:
Known Limitations:
Dependencies:

## PR Rules

- One primary task owner per PR.
- Keep changes focused.
- Explain shared-file modifications.
- Include relevant test evidence.
- Review the full diff.
- Ensure CI runs.
- Resolve relevant review comments.
- Do not merge known critical failures.

For UI changes:
Include relevant screenshots if practical.

For payment/security changes:
Include negative test evidence.

For migrations:
Include migration and policy test results.

---

# 43. CROSS-AGENT CODE REVIEW

Claude and Codex may review
each other's pull requests.

Example:

Claude:
Implements marketplace UI.

Codex:
Reviews data handling and tests.

Codex:
Implements payment callback.

Claude:
Reviews API behavior and test coverage.

Cross-agent reviews can improve quality.

However:

- An AI review is not equivalent
  to independent human approval.
- Financial and authorization changes
  require authorized review.
- The implementing agent must not
  falsely claim independent review.
- All review findings must be actionable.

A second agent may identify problems,
but reviewers must still verify
critical implementation behavior.

---

# 44. CONTINUOUS INTEGRATION RULES

GitHub Actions should verify each PR.

Minimum checks:

- Dart formatting
- Flutter static analysis
- Unit tests
- Widget tests
- Flutter Web build

Add relevant:

- Supabase database tests
- RLS tests
- Edge Function tests
- Payment tests
- Secret detection
- Dependency security checks
- Integration tests

## CI Security

- Minimize workflow permissions.
- Protect deployment credentials.
- Do not expose secrets to untrusted PR code.
- Review external GitHub Actions.
- Avoid unsafe command injection.
- Do not disable checks to force a merge.

Repository-plan limitations must be documented.

---

# 45. TASK COMPLETION REPORT

Each agent must provide
a structured completion report.

## Task Information

Task ID:
Task Name:
Agent:
Branch:
Pull Request:

## Implementation Summary

Describe actual completed work.

## Files Changed

List created, modified, and deleted files.

## Tests Executed

Include actual commands and results.

## Security Verification

State which access and privacy
boundaries were checked.

## UI/UX Verification

State tested widths, themes,
and important interactions.

## Shared File Changes

List shared files and coordination outcomes.

## Known Limitations

Explain incomplete or unverified behavior.

## Final Status

IN_REVIEW / DONE / BLOCKED

Only use DONE after acceptance criteria
and required merge/review conditions are met.

---

# 46. HANDOFF AND BLOCKER RULES

When an agent is blocked:

1. Identify the blocker.
2. Record the affected task.
3. Identify the owner of the dependency.
4. Explain the required information.
5. Update the issue status.
6. Avoid implementing insecure shortcuts.
7. Continue independent approved work
   when possible.

Do not duplicate another agent's task
to remove a blocker.

For a handoff:

- Commit safe completed changes.
- Describe unfinished work.
- List files changed.
- Record actual test results.
- State unresolved risks.
- Identify the next owner.

Never claim a handoff occurred
without a corresponding shared record.

---

# 47. DOCUMENTATION SYNCHRONIZATION

Project documentation must reflect
approved and implemented behavior.

## Master Files

PLAN.md:
Roadmap and milestones.

TASKS.md:
Master task registry.

SRS.md:
Product requirements.

ARCHITECTURE.md:
System architecture.

DESIGN_SYSTEM.md:
UI/UX rules.

SECURITY.md:
Security standards.

CONTRIBUTING.md:
Contribution workflow.

AGENTS.md:
AI development instructions.

## Synchronization Rules

GitHub Issues should be the live
coordination source for active work.

TASKS.md should be synchronized
after milestones or approved task changes.

Avoid both agents editing TASKS.md
simultaneously for routine status updates.

Major documentation changes require
explicit ownership and review.

If implementation changes architecture,
the owning agent must update or request
an update to the relevant documentation.

Never leave important changes undocumented.

---

# 48. PROJECT FILE OWNERSHIP MATRIX

Suggested initial allocation:

| Area | Ownership |
|------|-----------|
| Marketplace UI | Assigned per task |
| Learning UI | Assigned per task |
| PDF reader UI | Assigned per task |
| Payment backend | Assigned per task |
| Database migrations | Exclusive owner |
| Authentication | Exclusive per change |
| Shared design system | Controlled owner |
| Shared routing | Controlled owner |
| Security documentation | Reviewed owner |
| CI/CD | Controlled owner |
| Task coordination | Project owner |
| Production deployment | Authorized maintainer |

Ownership is task-based.

Do not permanently assume that
Claude owns UI and Codex owns backend.

Work allocation should reflect
dependencies and available capability.

---

# 49. EMERGENCY SECURITY WORKFLOW

Examples:

- Payment verification bypass
- Unauthorized course access
- Exposed credentials
- Public bank receipts
- Privilege escalation
- Major production outage

Procedure:

1. Report immediately.
2. Assess severity.
3. Contain risk.
4. Identify affected modules.
5. Assign one incident implementation owner.
6. Pause conflicting parallel changes.
7. Implement focused remediation.
8. Run critical regression tests.
9. Obtain authorized review.
10. Deploy through approved procedures.
11. Verify recovery.
12. Document incident findings.

During incidents, security-sensitive
shared modules must not be modified
independently by multiple agents.

Emergency changes must remain auditable.

---

# 50. PROHIBITED MULTI-AGENT BEHAVIOR

Claude and Codex must NEVER:

- Modify the same active worktree.
- Silently take another agent's task.
- Overwrite another agent's unmerged work.
- Ignore shared-file ownership.
- Edit locked files without coordination.
- Create conflicting database migrations.
- Change shared API contracts silently.
- Force-push another agent's branch.
- Automatically discard merge conflicts.
- Merge without required verification.
- Mark incomplete tasks DONE.
- Fabricate test results.
- Bypass payment verification.
- Disable RLS for convenience.
- Expose production credentials.
- Commit real student financial records.
- Deploy production changes without approval.
- Hide security vulnerabilities.
- Introduce unrelated architectural rewrites.
- Claim unavailable tools were executed.
- Claim browser screenshot protection
  is absolute.

These rules apply equally
to both AI coding agents.

---

# 51. DEFINITION OF READY

A task is ready for implementation when:

- [ ] Requirements are clear.
- [ ] Task ID exists.
- [ ] Priority is assigned.
- [ ] Dependencies are satisfied.
- [ ] Architecture is sufficiently defined.
- [ ] Acceptance criteria are testable.
- [ ] Security implications are considered.
- [ ] Assigned agent is identified.
- [ ] File ownership is documented.
- [ ] Shared file conflicts are resolved.
- [ ] Branch and workspace are identified.
- [ ] No critical unresolved decision blocks work.

---

# 52. DEFINITION OF DONE

A task is DONE only when:

- [ ] Requirements are satisfied.
- [ ] Code follows approved architecture.
- [ ] Assigned scope is respected.
- [ ] Relevant tests are implemented.
- [ ] Tests actually pass.
- [ ] Static analysis passes.
- [ ] Security controls are verified.
- [ ] Error states are handled.
- [ ] UI follows the design system.
- [ ] Relevant responsive layouts are checked.
- [ ] Accessibility is evaluated.
- [ ] No secrets or private data are exposed.
- [ ] Shared-file changes were coordinated.
- [ ] Documentation is updated.
- [ ] CI checks pass.
- [ ] Required reviews are completed.
- [ ] Changes are merged or formally accepted.
- [ ] Completion evidence is recorded.

Generating code is not completion.

Passing one test is not full verification.

A successful PR merge does not
automatically prove production readiness.

---

# 53. REQUIRED INTEGRATION GATE

Before merging parallel work:

- [ ] Both task scopes are complete.
- [ ] Shared contracts remain compatible.
- [ ] No unresolved merge conflicts exist.
- [ ] Database migrations are ordered.
- [ ] Required RLS checks pass.
- [ ] Payment invariants remain correct.
- [ ] Flutter analysis passes.
- [ ] Relevant automated tests pass.
- [ ] UI integration is verified if applicable.
- [ ] Documentation is consistent.
- [ ] Security-sensitive changes are reviewed.
- [ ] Required merge approval is recorded.

After merge:

- Refresh dependent branches.
- Run appropriate integration tests.
- Monitor for regressions.
- Update coordination records.
- Release temporary ownership locks.

---

# 54. PROJECT OWNER RESPONSIBILITIES

The project owner or designated
technical lead is responsible for:

- Approving project priorities
- Resolving task ownership conflicts
- Approving architectural decisions
- Reviewing high-risk changes
- Managing access permissions
- Approving production deployments
- Coordinating parallel task dependencies
- Ensuring task records remain accurate
- Accepting completed milestones

AI agents support implementation
and review processes.

They do not replace authorized
project governance.

---

# 55. MULTI-AGENT OPERATING DIRECTIVE

Acedra is built through
controlled parallel engineering.

CLAUDE and CODEX may work simultaneously
when tasks are independent.

Every agent must:

1. Read approved project instructions.
2. Claim an available task.
3. Confirm scope and dependencies.
4. Use an isolated branch and worktree.
5. Respect shared-file ownership.
6. Follow secure architecture.
7. Implement only authorized changes.
8. Test meaningful behavior.
9. Report accurate verification results.
10. Submit a reviewable pull request.
11. Coordinate integration.
12. Update task records after acceptance.

Do not confuse parallel work
with unrestricted simultaneous modification.

Parallel execution must reduce
development time without increasing
uncontrolled integration risk.

SECURITY FIRST.
ONE TASK - ONE ACCOUNTABLE OWNER.
ONE ACTIVE TASK - ONE ISOLATED WORKSPACE.
NO SILENT SHARED-FILE CHANGES.
NO UNVERIFIED PAYMENT ACCESS.
NO FABRICATED TEST RESULTS.
CONTROLLED GITHUB INTEGRATION.
REVIEW BEFORE MERGE.
PROFESSIONAL SOFTWARE QUALITY.

END OF AGENTS.md
