
# PLAN.md
# Acedra - Master Software Development Plan

Document ID: CSA-PLAN-001
Version: 2.0
Status: Approved Documentation Baseline - Implementation and Release Gates Retained
Approval: Project owner, 2026-10-11; see docs/requirements/CSA-011-017-APPROVAL.md.
Project: Acedra Course Selling Application
Project Type: Commercial E-Learning Platform
Primary Platform: Flutter Web
Future Platforms: Android and iOS
Backend: Supabase + PostgreSQL
Architecture: Feature-First Clean Architecture
Development Model: Parallel Multi-Agent Engineering
AI Agents: Claude Code + OpenAI Codex
Version Control: Git + GitHub
Methodology: Agile + Specification-First + TDD
Classification: Internal Project Documentation

---

# 1. PROJECT VISION

Build a modern, professional, secure,
and scalable course-selling application.

Students will be able to:

- Create an account
- Log in securely
- Browse available courses
- Search and filter courses
- View course information
- Purchase courses online
- Pay using bank transfer
- Submit bank transfer receipts
- View payment status
- Access purchased courses
- Watch video lessons
- Read text and image lessons
- Read protected PDF documents
- Resume learning
- Track learning progress

Administrators will be able to:

- Manage courses
- Manage curriculum and lessons
- Upload learning materials
- Manage students
- Review financial transactions
- Verify bank transfer receipts
- Approve or reject bank payments
- Manage course enrollments
- Review operational statistics
- Manage authorized roles
- Inspect audit records

The product must prioritize:

1. Security
2. Correctness
3. Student Privacy
4. Financial Integrity
5. Reliability
6. Accessibility
7. User Experience
8. Maintainability
9. Performance
10. Cost Efficiency

---

# 2. PROJECT DEVELOPMENT STRATEGY

Acedra will be developed using:

- Modular Monolith Architecture
- Feature-First Clean Architecture
- Flutter Web
- Supabase
- PostgreSQL
- Row Level Security
- Trusted Backend Operations
- GitHub Version Control
- Automated Testing
- CI/CD
- Parallel AI-Assisted Engineering

Two primary coding agents:

CLAUDE:
Claude Code

CODEX:
OpenAI Codex

Both agents may work simultaneously
on independent approved tasks.

Parallelism must not compromise
system correctness or code quality.

The development process is:

REQUIREMENTS
    |
    v
ARCHITECTURE
    |
    v
TASK DECOMPOSITION
    |
    v
PARALLEL TASK ALLOCATION
    |
    v
ISOLATED DEVELOPMENT
    |
    v
AUTOMATED TESTING
    |
    v
CODE REVIEW
    |
    v
CONTROLLED INTEGRATION
    |
    v
SYSTEM VERIFICATION
    |
    v
PRODUCTION RELEASE

---

# 3. PROJECT DOCUMENTATION

The project documentation consists of:

PLAN.md
TASKS.md
AGENTS.md
SRS.md
ARCHITECTURE.md
DATABASE_DESIGN.md
DESIGN_SYSTEM.md
SECURITY.md
CONTRIBUTING.md
docs/TESTING.md
CLAUDE.md

docs/
  PARALLEL_WORKFLOW.md
  decisions/
  API_CONTRACTS.MD

## Document Responsibilities

PLAN.md:
Master roadmap and development strategy.

TASKS.md:
Task backlog, dependencies, and assignments.

AGENTS.md:
Mandatory shared AI development rules.

SRS.md:
Functional and non-functional requirements.

ARCHITECTURE.md:
System components and technical boundaries.

DATABASE_DESIGN.md:
Database schema, RLS, and data integrity.

DESIGN_SYSTEM.md:
Visual design and UI/UX rules.

SECURITY.md:
Security policy and mandatory controls.

CONTRIBUTING.md:
GitHub and contribution workflow.

docs/TESTING.md:
Testing and quality assurance standards.

CLAUDE.md:
Claude-specific entrypoint.

PARALLEL_WORKFLOW.md:
Operational multi-agent coordination.

Do not treat uncreated documents
or unapproved decisions as completed.

---

# 4. MASTER INSTRUCTION POLICY

All contributors must follow:

1. Applicable platform and safety instructions
2. Current authorized user requirements
3. AGENTS.md
4. Relevant scoped agent instructions
5. Approved engineering documentation
6. Existing repository conventions

Conflicts must be resolved explicitly.

Do not silently weaken security.

Do not invent financial policies.

Do not implement unapproved
architecture changes.

Do not claim unverified work is complete.

---

# 5. MVP SCOPE

The initial release will include:

## Student

- Registration
- Login/logout
- Email verification
- Password recovery
- Student profile
- Course marketplace
- Search and filtering
- Course details
- Curriculum preview
- Online payment checkout
- Bank transfer checkout
- Receipt upload
- Payment status
- My Courses
- Learning workspace
- Video lessons
- Text lessons
- Image lessons
- Protected PDF reader
- Lesson progress
- Resume learning

## Administration

- Admin authentication and permissions
- Admin dashboard
- Course creation and editing
- Curriculum builder
- Lesson content upload
- Course publishing
- Student management
- Payment management
- Bank receipt review
- Manual verification and approval
- Enrollment management
- Basic reporting
- Audit logging

## Platform

- Flutter Web
- Responsive layouts
- Light/dark themes
- Supabase backend
- PostgreSQL database
- Secure RLS policies
- Private content storage
- Trusted financial operations
- Testing and CI/CD
- Production monitoring

---

# 6. OUT OF SCOPE FOR MVP

The following require future approval:

- Native Android application
- Native iOS application
- Live classes
- Multi-instructor marketplace
- Course subscriptions
- Affiliate marketing
- Course bundles
- Advanced quizzes
- Certificates
- AI tutors
- Community forums
- Offline paid content downloads
- Gamification
- Advanced recommendations

Do not introduce post-MVP features
into active work without approval.

---

# 7. APPROVED TECHNOLOGY BASELINE

## Frontend

Framework:
Flutter

Language:
Dart

UI:
Material 3 + Custom Design System

State Management:
Riverpod

Navigation:
go_router

Architecture:
Feature-First Clean Architecture

## Backend

Platform:
Supabase

Authentication:
Supabase Auth

Database:
PostgreSQL

Authorization:
Row Level Security

Backend Logic:
Supabase Edge Functions

Atomic Operations:
PostgreSQL Transactions/Functions

Storage:
Supabase Storage

## Learning Content

PDF:
Evaluated Flutter PDF reader

Video:
Approved protected streaming provider

Text:
Structured learning content

Images:
Optimized authorized media delivery

## Engineering

Git
GitHub
GitHub Actions
Flutter Test
Integration Tests
Dart Analyzer
Supabase CLI
VS Code

## External Providers

Payment Gateway:
PayHere / LKR (approved CSA-004; merchant readiness gates retained)

Protected Video Provider:
Mux Basic signed 1080p VOD (approved CSA-011; renewal/privacy PoC required)

Transactional Email:
PENDING SELECTION

Production Hosting:
PENDING SELECTION

Monitoring Provider:
PENDING SELECTION

Use free-first tools where practical.

Production infrastructure may require
paid hosting, bandwidth, video delivery,
email services, and transaction fees.

All provider selections require
security, cost, and compatibility review.

---

# 8. SOFTWARE ENGINEERING PRINCIPLES

All development must follow:

SOLID
DRY
KISS
YAGNI
SEPARATION OF CONCERNS
SECURITY BY DESIGN
PRIVACY BY DESIGN
ACCESSIBILITY BY DESIGN
TESTABILITY
LEAST PRIVILEGE
DEFENSE IN DEPTH

## Important Rules

- Favor simple maintainable solutions.
- Keep business logic out of widgets.
- Keep privileged operations server-side.
- Reuse approved design components.
- Avoid circular dependencies.
- Implement only approved requirements.
- Write tests for critical business behavior.
- Review security-sensitive changes.
- Document important technical decisions.

Never sacrifice authorization or
financial correctness for performance.

---

# 9. MULTI-AGENT DEVELOPMENT STRATEGY

The project uses coordinated
parallel development.

Agents:

CLAUDE
CODEX

Coordinator:

PROJECT LEAD

## 9.1 Suggested Agent Responsibilities

CLAUDE:

- Flutter project structure
- Design system
- Student-facing UI
- Authentication UI
- Course marketplace UI
- Checkout UI
- Learning workspace
- PDF reader UI
- Admin dashboard UI
- Widget and visual testing

CODEX:

- Supabase configuration
- PostgreSQL schema
- Row Level Security
- Authentication backend
- Course data services
- Payment verification
- Bank transfer processing
- Enrollment authorization
- Protected file delivery
- Backend testing
- CI/CD infrastructure

These are proposed areas,
not permanent restrictions.

Actual ownership is task-based.

## 9.2 Ownership Model

ONE TASK = ONE ACCOUNTABLE OWNER.

A task may have:

- One implementation owner
- Multiple reviewers
- Multiple dependent tasks
- One or more integration requirements

No two agents may independently
own the same active implementation task.

## 9.3 Initial Concurrency Limit

Recommended starting policy:

Claude:
One active implementation task.

Codex:
One active implementation task.

Integration:
One coordinated integration task
when needed.

Increase concurrency only after
the workflow proves reliable.

An explicit project-owner request may authorize a bounded parallel
documentation review before that dry-run. Record isolated worktrees,
exclusive file scopes and local coordination evidence. This exception
does not establish readiness for concurrent production implementation.

---

# 10. GITHUB COORDINATION MODEL

GitHub is the shared development
coordination environment.

Use:

GitHub Issues:
Task assignments and live statuses.

GitHub Pull Requests:
Code reviews and integration.

GitHub Actions:
Automated checks.

Git Branches:
Independent development history.

Git Worktrees:
Separate local workspaces.

GitHub Projects:
Optional task visualization.

## Task Source of Truth

GitHub Issues:
Live task ownership and status.

TASKS.md:
Stable master backlog and milestones.

PLAN.md:
Overall development strategy.

Major changes require documentation
and task reconciliation.

Do not rely only on conversation history.

Claude and Codex may run through
different accounts and environments.

They cannot be assumed to share
memory, tools, or local files.

---

# 11. TASK ALLOCATION PROCEDURE

Before assigning work:

1. Select a task from TASKS.md.
2. Confirm its SRS requirements.
3. Check task dependencies.
4. Check architecture readiness.
5. Identify affected files.
6. Identify required shared contracts.
7. Check overlapping active work.
8. Select the appropriate agent.
9. Confirm task ownership.
10. Record the assignment on GitHub.

## Required Task Information

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
Worktree:
Acceptance Criteria:
Required Tests:
Related Pull Request:

## Task Claiming

Agents must not assume that a
suggested allocation is a confirmed claim.

The project coordinator must explicitly
confirm ownership.

If two agents claim the same task,
resolve ownership before implementation.

---

# 12. WORKSPACE ISOLATION

Claude and Codex must work in
separate development workspaces.

## Same Computer

Preferred:
Separate Git worktrees.

## Different Computers or Cloud Environments

Preferred:
Separate Git clones and branches.

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

Both agents must:

- Work only in assigned workspaces.
- Use unique branches.
- Avoid overwriting shared changes.
- Avoid unrelated file modifications.
- Avoid force-pushing main.
- Keep local test resources isolated.

Git worktrees do not automatically
isolate shared external services.

Test databases, ports, storage,
and provider sandboxes require
additional isolation or coordination.

---

# 13. SHARED FILE OWNERSHIP

The following require
explicit coordination:

AGENTS.md
PLAN.md
TASKS.md
ARCHITECTURE.md
DATABASE_DESIGN.md
DESIGN_SYSTEM.md
SECURITY.md
CONTRIBUTING.md
docs/TESTING.md
CLAUDE.md

pubspec.yaml
pubspec.lock

lib/app/**
lib/core/**
lib/shared/**

supabase/migrations/**

.github/workflows/**

Shared API contracts
Shared data models
Shared design tokens

## Ownership Rules

- One temporary owner for conflicting changes.
- Record ownership in GitHub.
- Do not silently edit another active scope.
- Coordinate contract changes.
- Resolve conflicts before merging.
- Release ownership after integration.

Logical file locks are coordination rules.

They are not guaranteed atomic locks.

---

# 14. PARALLEL DEVELOPMENT RULES

Parallel development is allowed when:

- Tasks are independent.
- Dependencies are satisfied.
- File scopes do not conflict.
- Shared API contracts are approved.
- Database changes are compatible.
- Security boundaries remain clear.
- Tests can execute safely.

Sequential development is required when:

- The same file must be changed.
- An API contract is not yet approved.
- Database migrations conflict.
- Payment state transitions overlap.
- Shared architecture changes are unresolved.
- One task depends on incomplete backend logic.

## Parallel Example

CLAUDE:

Task:
CSA-083 - Course Grid UI

CODEX:

Task:
CSA-102 - Payment Webhook

These are structurally independent,
but CSA-102 must still wait for
its payment schema and provider decisions.

## Coordinated Example

CLAUDE:

Checkout UI

CODEX:

Checkout Backend

These may be developed concurrently
when the API contract is approved.

Frontend may use synthetic mocks
until trusted backend integration exists.

A working mock does not demonstrate
successful payment processing.

---

# 15. DEVELOPMENT PHASES

The project contains ten core phases.

| Phase | Name |
|-------|------|
| 0 | Requirements and Architecture |
| 1 | Project and GitHub Setup |
| 2 | Design System |
| 3 | Authentication |
| 4 | Marketplace |
| 5 | Payments and Enrollments |
| 6 | Learning and Protected Content |
| 7 | Administration |
| 8 | Testing and Security |
| 9 | Production Launch |

Each phase has:

- Objectives
- Task references
- Agent responsibilities
- Dependencies
- Deliverables
- Verification requirements
- Exit gates

Phases may partially overlap
when dependencies permit.

Critical release gates cannot be skipped.

---

# 16. PHASE 0
# REQUIREMENTS AND ARCHITECTURE

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-001 through CSA-017

## Objectives

- Finalize MVP requirements.
- Approve architecture.
- Define business rules.
- Define database design.
- Identify security risks.
- Select payment integration.
- Define PDF delivery strategy.
- Define enrollment policies.
- Establish cost limits.

## CLAUDE WORKSTREAM

Proposed tasks:

- Review UI/UX requirements.
- Refine design system.
- Validate layout coverage.
- Identify reusable UI components.
- Define responsive interface requirements.

Relevant task:
CSA-014

## CODEX WORKSTREAM

Proposed tasks:

- Draft database architecture.
- Define trusted backend boundaries.
- Analyze RLS requirements.
- Prepare threat model.
- Document initial ADRs.

Relevant tasks:
CSA-008
CSA-009
CSA-016

## PROJECT LEAD

Approve:

- Product requirements
- Payment provider
- Supported currency
- Bank transfer rules
- Course access lifetime
- Refund behavior
- Video provider
- PDF protection strategy
- Privacy policy requirements

## Required Deliverables

- Reviewed SRS.md
- Approved architecture baseline
- Database design proposal
- Security threat model
- Initial architecture decisions
- MVP acceptance criteria
- Defined task dependencies

## Phase 0 Exit Gate

- [ ] Requirements approved.
- [ ] MVP scope approved.
- [ ] Payment rules defined.
- [ ] Enrollment policies defined.
- [ ] Architecture reviewed.
- [ ] Security boundaries identified.
- [ ] Database design reviewed.
- [ ] Critical technology decisions recorded.

For CSA-011 through CSA-017, distinguish a submitted proposal from an
accepted decision. Record video-provider approval and playback proof,
environment and budget approval, governance review, design review,
privacy/security baseline approval and the MVP acceptance strategy.
Resolve SRS DEC-009, DEC-011 and DEC-014 before the respective dependent
implementation or release gate. The owner must record who approved which
revision and when; documentation preparation cannot waive these gates.

Do not start security-critical
implementation using unresolved
payment or enrollment assumptions.

---

# 17. PHASE 1
# PROJECT AND GITHUB SETUP

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-018 through CSA-038

Related Coordination Tasks:
CSA-236 through CSA-252

## Objectives

- Initialize Flutter.
- Configure Supabase development.
- Establish GitHub repository.
- Configure CI/CD.
- Create development environments.
- Configure multi-agent task coordination.
- Establish isolated workspaces.

## CLAUDE WORKSTREAM

Proposed tasks:

CSA-018:
Initialize Flutter.

CSA-019:
Pin Flutter/Dart versions.

CSA-020:
Create Flutter architecture structure.

CSA-021:
Configure Riverpod.

CSA-022:
Configure go_router.

CSA-023:
Configure Dart lint rules.

CSA-024:
Create error-handling foundation.

## CODEX WORKSTREAM

Proposed tasks:

CSA-032:
Configure Supabase.

CSA-033:
Configure local backend development.

CSA-034:
Establish safe environment settings.

CSA-035:
Configure migrations and database tests.

CSA-036:
Configure GitHub Actions.

CSA-037:
Configure dependency monitoring.

CSA-038:
Configure baseline tests.

## PROJECT LEAD WORKSTREAM

- Create the private GitHub repository.
- Approve contributor access.
- Add engineering documentation.
- Set up issue and PR templates.
- Configure review policy.
- Establish task ownership.
- Establish worktree conventions.

## Multi-Agent Setup Tasks

CSA-236:
Configure task ownership fields.

CSA-237:
Review existing docs/PARALLEL_WORKFLOW.md and approve its workflow.

CSA-238:
Create CLAUDE.md.

CSA-239:
Define worktree and branch conventions.

CSA-240:
Configure CODEOWNERS.

CSA-241:
Update pull request template.

CSA-242 through CSA-252:
Configure isolation, locks, integration,
review processes, and dry-run testing.

## Required Deliverables

- Working Flutter project
- Working local Supabase environment
- GitHub repository
- Automated quality checks
- Secure environment configuration
- Task allocation process
- Separate agent workspaces
- PR templates and ownership rules

## Phase 1 Exit Gate

- [ ] Flutter application builds.
- [ ] Supabase development works.
- [ ] Repository configuration reviewed.
- [ ] CI pipeline runs.
- [ ] Secrets remain protected.
- [ ] Git worktree workflow verified.
- [ ] Shared-file ownership established.
- [ ] Two-agent dry-run completed.

---

# 18. PHASE 2
# DESIGN SYSTEM AND UI FOUNDATIONS

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-039 through CSA-058

## Objectives

- Implement design tokens.
- Build light/dark themes.
- Create reusable components.
- Build responsive navigation shells.
- Establish accessibility standards.

## CLAUDE WORKSTREAM

Primary responsibility:

- App colors
- Typography
- Spacing
- Component radius
- Responsive breakpoints
- Material 3 theme
- Light/dark switching
- Reusable buttons
- Reusable inputs
- Course cards
- Loading/error states
- Dialogs and notifications
- Public navigation
- Student navigation
- Admin navigation

## CODEX PARALLEL WORKSTREAM

When contracts are approved:

- Prepare profile database schema.
- Prepare trusted role policies.
- Build initial course data model.
- Implement backend test foundations.

Relevant future ranges:
CSA-059 through CSA-062
CSA-077 through CSA-081

Backend tasks may start early only
when their prerequisites are satisfied.

## Design Standards

Brand:
Acedra - working name

Design Direction:
Premium, minimal, indigo-based

Themes:
Light and dark

Reference Widths:

Mobile:
390

Tablet:
768

Desktop:
1440

Also test intermediate widths.

## Deliverables

- Centralized theme system
- Reusable UI library
- Responsive layout foundations
- Student navigation shell
- Admin navigation shell
- Widget tests
- Accessibility foundations

## Phase 2 Exit Gate

- [ ] Light theme works.
- [ ] Dark theme works.
- [ ] Shared components exist.
- [ ] Responsive shells work.
- [ ] Important accessibility checks pass.
- [ ] Relevant widget tests pass.

---

# 19. PHASE 3
# AUTHENTICATION AND USER ACCOUNTS

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-059 through CSA-076

Dependencies:

- Flutter foundation
- Supabase configuration
- Approved identity/role model

## CLAUDE WORKSTREAM

Implement:

- Registration UI
- Login UI
- Email verification UI
- Password recovery UI
- Logout behavior
- Profile screens
- Session restoration UI
- Navigation guards

Relevant tasks:
CSA-063 through CSA-072

## CODEX WORKSTREAM

Implement:

- Profile schema
- Role schema
- RLS policies
- Trusted role assignment
- Auth configuration
- Administrative permissions
- Cross-user authorization tests

Relevant tasks:
CSA-059 through CSA-062
CSA-073 through CSA-075

## Integration

- Connect Flutter Auth with Supabase.
- Confirm session behavior.
- Verify protected profile access.
- Verify role-aware navigation.
- Verify backend authorization.

## Phase 3 Exit Gate

- [ ] Registration works.
- [ ] Login/logout works.
- [ ] Password recovery works.
- [ ] Email verification works.
- [ ] Sessions handled correctly.
- [ ] Profile data protected.
- [ ] Admin permissions enforced.
- [ ] Authorization tests pass.

---

# 20. PHASE 4
# COURSE MARKETPLACE

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-077 through CSA-091

Dependencies:

- Course data model
- Publication policies
- Marketplace API contract
- UI foundations

## CLAUDE WORKSTREAM

Implement:

- Marketplace homepage
- Course listing
- Course cards
- Search UI
- Category filters
- Course details
- Curriculum preview
- Owned/unpurchased states

Relevant tasks:
CSA-082 through CSA-088
CSA-090

## CODEX WORKSTREAM

Implement:

- Course/category schema
- Section/lesson schema
- Course publication policies
- Asset metadata
- Synthetic course seed data
- Authorized course management foundation
- Data access tests

Relevant tasks:
CSA-077 through CSA-081
CSA-089
CSA-091

## Integration

- Connect course catalog to backend.
- Validate published course visibility.
- Validate course details.
- Validate search/filter contracts.
- Test unauthorized draft access.

## Phase 4 Exit Gate

- [ ] Published courses display.
- [ ] Search works.
- [ ] Filters work.
- [ ] Course details work.
- [ ] Curriculum preview works.
- [ ] Draft courses protected.
- [ ] Responsive UI verified.

---

# 21. PHASE 5
# PAYMENTS AND ENROLLMENTS

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-092 through CSA-126

Criticality:
P0 - Financial Security

Dependencies:

- Authentication
- Course model
- Approved payment provider
- Financial database schema
- Enrollment policies
- Approved API contracts

## CLAUDE WORKSTREAM

Implement:

- Checkout UI
- Payment method selection
- Payment status screens
- Bank transfer instructions
- Receipt upload interface
- Receipt review interface
- Receipt resubmission interface

Relevant tasks:

CSA-097
CSA-099
CSA-106
CSA-107
CSA-110
CSA-111
CSA-115

## CODEX WORKSTREAM

Implement:

- Orders
- Payment attempts
- Payment event records
- Bank receipt records
- Enrollment schema
- Payment provider adapter
- Checkout initialization
- Verified webhook
- Payment amount validation
- Currency validation
- Atomic finalization
- Idempotency protection
- Private receipt upload
- Bank approval/rejection
- Enrollment authorization
- Audit logging
- Critical backend tests

Relevant tasks:

CSA-092 through CSA-096
CSA-098
CSA-100 through CSA-105
CSA-108 through CSA-109
CSA-112 through CSA-114
CSA-116 through CSA-126

## Critical Payment Rules

- Frontend success is not verified payment.
- Payment callbacks require validation.
- Order amount must be trusted.
- Currency must be verified.
- Duplicate callbacks must be safe.
- Concurrent approval must be safe.
- Receipt submission never grants access.
- Bank transfer requires actual
  incoming payment verification.
- Entitlement creation must be transactional.

## Integration

Connect:

Checkout UI
    |
Trusted Order API
    |
Payment Provider
    |
Verified Backend Event
    |
Financial Transaction
    |
Enrollment Grant
    |
My Courses

## Phase 5 Exit Gate

- [ ] Sandbox online payment works.
- [ ] Provider verification passes.
- [ ] Duplicate callbacks handled.
- [ ] Bank receipt upload secure.
- [ ] Finance approval secure.
- [ ] Rejected payments remain locked.
- [ ] Enrollments are backend-authorized.
- [ ] Payment state remains consistent.
- [ ] Critical security tests pass.

This is a mandatory security gate.

Do not enable production payment
processing before approval.

---

# 22. PHASE 6
# LEARNING AND PROTECTED CONTENT

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-127 through CSA-156

Dependencies:

- Course curriculum
- Active entitlements
- Protected storage policy
- Approved PDF delivery design
- Video delivery provider

## CLAUDE WORKSTREAM

Implement:

- My Courses
- Learning workspace
- Lesson navigation
- Text reader
- Image reader
- Video player interface
- PDF reader interface
- Page navigation
- Zoom
- Fit-to-width
- Reader toolbar
- Learning progress UI
- Reader loading/error states
- Responsive and accessibility tests

Relevant tasks:

CSA-128 through CSA-132
CSA-134 through CSA-135
CSA-137 through CSA-138
CSA-142 through CSA-147
CSA-149 through CSA-151
CSA-156

## CODEX WORKSTREAM

Implement:

- Progress schema
- Progress persistence
- Video playback authorization
- Private PDF storage
- PDF entitlement validation
- Controlled document delivery
- Watermark generation/delivery
- Protected content tests
- Revoked entitlement tests

Relevant tasks:

CSA-127
CSA-133
CSA-136
CSA-139 through CSA-141
CSA-148
CSA-152 through CSA-155

## PDF Security Principles

- Private document storage
- Backend authorization
- Controlled document access
- Short-lived authorization where appropriate
- Personalized watermarking
- Secure reader integration
- Limited unnecessary controls

Important:

Flutter Web cannot guarantee
prevention of screenshots,
screen recordings, or copying.

Never promise absolute content security.

## Learning UX Requirements

- Smooth lesson navigation
- High-quality PDF rendering
- Comfortable reading
- Video controls
- Mobile responsiveness
- Light/dark reading UI
- Progress persistence
- Accessible interactions

## Phase 6 Exit Gate

- [ ] My Courses works.
- [ ] Authorized lessons open.
- [ ] Unauthorized lessons denied.
- [ ] PDF reader works.
- [ ] Video player works.
- [ ] Learning progress persists.
- [ ] Reader responsiveness verified.
- [ ] PDF security controls tested.
- [ ] Content protection limits documented.

---

# 23. PHASE 7
# ADMINISTRATION SYSTEM

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-157 through CSA-176

Dependencies:

- Authentication
- Trusted roles
- Course management APIs
- Payment system
- Enrollment services

A minimal bank approval UI must already
exist during Phase 5.

Phase 7 completes the full
administrative experience.

## CLAUDE WORKSTREAM

Implement:

- Admin dashboard UI
- Statistics cards
- Course management screens
- Course creation/editing
- Curriculum builder
- Lesson editor
- Student management UI
- Payment review dashboard
- Receipt previews
- Financial status tables
- Responsive admin navigation

## CODEX WORKSTREAM

Implement:

- Trusted admin APIs
- Dashboard statistics
- Course publishing logic
- Secure media uploads
- Student access management
- Audit log infrastructure
- Financial reporting
- Role management
- Admin authorization tests

## Phase 7 Exit Gate

- [ ] Dashboard displays real data.
- [ ] Course management works.
- [ ] Curriculum editing works.
- [ ] Finance workflow works.
- [ ] Admin roles enforced.
- [ ] Sensitive changes audited.
- [ ] Student data access restricted.
- [ ] Admin UI responsive.

---

# 24. PHASE 8
# TESTING, SECURITY, AND OPTIMIZATION

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-177 through CSA-204

Testing must occur throughout
all development phases.

This phase focuses on final
integration and release readiness.

## CLAUDE WORKSTREAM

- Flutter widget tests
- Student journey tests
- Responsive testing
- Theme testing
- PDF reader testing
- Learning UX testing
- Accessibility review
- Browser integration tests
- Frontend performance analysis

## CODEX WORKSTREAM

- Database RLS tests
- Payment verification tests
- Financial concurrency tests
- Bank approval tests
- Enrollment authorization tests
- Backend integration tests
- Upload security tests
- Dependency security review
- Backup verification
- Backend performance testing

## PROJECT LEAD

- Coordinate regression testing.
- Review high-risk findings.
- Prioritize defects.
- Approve risk resolutions.
- Review release acceptance evidence.

## Required End-to-End Journeys

Journey A:
Register -> Login -> Browse -> Purchase
-> Enrollment -> Learning.

Journey B:
Register -> Bank Transfer -> Receipt Upload
-> Admin Verification -> Enrollment.

Journey C:
Admin Login -> Create Course
-> Upload Lessons -> Publish Course.

Journey D:
Purchased Student -> Protected PDF
-> Read -> Save Progress -> Resume.

Journey E:
Unauthorized Student -> Protected Content
-> Backend Denies Access.

## Phase 8 Exit Gate

- [ ] Critical workflows pass.
- [ ] Financial security verified.
- [ ] Database policies tested.
- [ ] Private storage tested.
- [ ] No unresolved release blockers.
- [ ] UI responsive.
- [ ] Accessibility evaluated.
- [ ] Production build verified.
- [ ] Backup restoration tested.
- [ ] Release review completed.

---

# 25. PHASE 9
# PRODUCTION DEPLOYMENT

Status:
NOT VERIFIED COMPLETE

Main Task Range:
CSA-205 through CSA-222

Dependencies:

- Release acceptance
- Security review
- Production infrastructure
- Approved payment provider
- Backup and monitoring strategy

## CODEX WORKSTREAM

Prepare:

- Production hosting configuration
- Backend environment configuration
- Database migrations
- Production RLS policies
- Payment provider integration
- Private storage
- Security headers
- Monitoring
- Backups
- Recovery procedures

## CLAUDE WORKSTREAM

Verify:

- Production Flutter Web build
- Responsive layouts
- Browser navigation
- Authentication flows
- Student checkout screens
- PDF reader functionality
- Admin UI usability

## PROJECT LEAD

Approve:

- Production credentials and access
- Payment readiness
- Security checklist
- Privacy and commercial policies
- Final release
- Deployment and rollback plans

## Release Process

1. Freeze approved release scope.
2. Confirm required CI checks.
3. Verify database migration readiness.
4. Verify critical security controls.
5. Confirm backup strategy.
6. Confirm monitoring.
7. Obtain production approval.
8. Deploy using authorized procedures.
9. Run production smoke tests.
10. Record release evidence.

## Phase 9 Exit Gate

- [ ] Production site available.
- [ ] HTTPS configured.
- [ ] Authentication works.
- [ ] Payment verification works.
- [ ] Bank approval workflow works.
- [ ] Course access enforced.
- [ ] Private content protected.
- [ ] Monitoring active.
- [ ] Backups configured.
- [ ] Recovery procedures verified.
- [ ] Production acceptance recorded.

No agent may independently
deploy production changes
without explicit authorization.

---

# 26. PARALLEL DEVELOPMENT WAVES

The execution plan groups
compatible tasks into waves.

## Wave 0 - Planning

CLAUDE:
Review UI/UX foundation.

CODEX:
Draft database/security architecture.

LEAD:
Approve business decisions.

Integration:
Requirements and contracts approved.

## Wave 1 - Foundations

CLAUDE:
Flutter project and UI foundations.

CODEX:
Supabase and database tooling.

LEAD:
Repository and workflow setup.

Integration:
Build, tests, and worktree dry-run pass.

## Wave 2 - Identity and Catalog

CLAUDE:
Authentication screens and
marketplace components.

CODEX:
Auth policies and course schema.

Integration:
Authentication and catalog APIs work.

## Wave 3 - Commerce

CLAUDE:
Checkout and bank transfer UI.

CODEX:
Payment and enrollment backend.

Integration:
Complete sandbox payment flows verified.

## Wave 4 - Learning

CLAUDE:
Learning workspace and PDF reader UI.

CODEX:
Protected content authorization
and progress services.

Integration:
Authorized learning journeys pass.

## Wave 5 - Administration

CLAUDE:
Admin management interface.

CODEX:
Trusted administrative operations.

Integration:
Admin permissions and workflows verified.

## Wave 6 - Release Quality

CLAUDE:
UI, accessibility, and browser QA.

CODEX:
Backend, payment, and security QA.

LEAD:
Final review and release decisions.

Integration:
All required release gates pass.

Waves may overlap when dependencies permit.

Do not interpret the wave plan
as automatic agent scheduling.

---

# 27. CRITICAL PATH

The critical path for the MVP is:

Business Rules
    |
    v
Database Design
    |
    v
Authentication + Authorization
    |
    v
Course and Order Models
    |
    v
Payment Verification
    |
    v
Enrollment Grant
    |
    v
Protected Content Authorization
    |
    v
End-to-End Security Testing
    |
    v
Production Approval

The UI can progress independently
against approved data contracts.

However, protected learning cannot
be accepted until backend entitlement
and content authorization are verified.

---

# 28. API CONTRACT INTEGRATION

Before parallel frontend/backend work:

1. Define the API operation.
2. Define request fields.
3. Define response fields.
4. Define authentication requirements.
5. Define authorization requirements.
6. Define error codes.
7. Define important state transitions.
8. Define idempotency where needed.
9. Record contract version or revision.
10. Obtain required approval.

Example:

Contract:
create-checkout-order

CLAUDE:
Checkout UI.

CODEX:
Trusted backend function.

Response:
Order reference and provider checkout data.

Do not expose privileged credentials
inside API responses.

Breaking API changes require
cross-agent coordination.

---

# 29. DATABASE CHANGE STRATEGY

Database changes must be managed
through version-controlled migrations.

Rules:

- One migration owner.
- Explicit dependencies.
- Consistent schema contracts.
- Reviewed grants.
- Reviewed RLS policies.
- Controlled financial functions.
- Transactional data integrity.
- Automated migration tests.

Conflicting migrations must be
developed or integrated sequentially.

Parallel agents may use separate
local databases for safe testing.

Do not allow agents to modify
the same production schema independently.

---

# 30. SECURITY DEVELOPMENT GATES

Security must be enforced throughout
the project, not only in Phase 8.

## Gate A - Identity

Before protected account functionality:

- Authentication tested
- Profile ownership enforced
- Admin role assignment protected

## Gate B - Commerce

Before purchase access grants:

- Provider callback verified
- Price and currency validated
- Idempotency tested
- Bank approval controlled
- Transactions atomic

## Gate C - Content

Before protected course delivery:

- Entitlement validated
- Private storage configured
- Unauthorized access denied
- Revocation policy implemented

## Gate D - Administration

Before admin launch:

- Backend roles tested
- Financial permissions tested
- Audit events recorded
- Cross-user data isolation verified

## Gate E - Production

Before release:

- Critical security tests passed
- Production secrets protected
- Backup and recovery ready
- Incident response documented
- Required approvals complete

Failure of a critical gate
blocks dependent release activity.

---

# 31. TESTING STRATEGY

All phases require appropriate testing.

## Frontend

- Unit tests
- Widget tests
- Integration tests
- Responsive checks
- Accessibility checks
- Browser navigation tests

## Backend

- Database tests
- RLS tests
- Edge Function tests
- Payment sandbox tests
- API integration tests
- Concurrency tests
- Authorization tests

## Required Commands

Flutter Formatting:

```bash
dart format --output=none --set-exit-if-changed .
```

Static Analysis:

```bash
flutter analyze
```

Flutter Tests:

```bash
flutter test
```

Production Web Build:

```bash
flutter build web --release
```

Supabase Database Tests:

```bash
supabase test db
```

Run additional tests as configured.

Never report passing results
for commands that were not executed.

---

# 32. PARALLEL TEST ENVIRONMENTS

Agents must not interfere with
each other's tests.

Isolate:

- Local working directories
- Mutable database state
- Test accounts
- Storage fixtures
- Temporary files
- Runtime ports
- Payment sandbox transactions

If a shared service cannot be isolated,
serialize conflicting tests.

Do not use real student financial data
for routine testing.

Do not execute destructive commands
against production environments.

---

# 33. GITHUB BRANCH AND PR STRATEGY

Default Branch:

main

Branch Naming:

feat/csa-xxx-description
fix/csa-xxx-description
security/csa-xxx-description
docs/csa-xxx-description
test/csa-xxx-description
refactor/csa-xxx-description

## Pull Request Rules

- One bounded implementation task per PR.
- Reference task ID.
- Reference related requirements.
- Document actual tests.
- Disclose shared-file changes.
- Disclose API/schema changes.
- Document security considerations.
- Identify known limitations.
- Obtain required review.

Recommended Merge Method:
Squash merge.

## GitHub Protection

Enable available branch protection.

Where private-repository plan limitations
prevent technical enforcement,
use documented manual approvals.

Never claim a rule is enforced
when it is only team policy.

---

# 34. CROSS-AGENT REVIEW

Claude may review Codex work.

Codex may review Claude work.

Review focus:

- Requirements
- Architecture
- Security
- Correctness
- API compatibility
- Tests
- Performance
- Maintainability

Important:

Cross-agent review does not
automatically replace human approval.

P0 payment, enrollment, authorization,
and production changes require
appropriate authorized review.

Reviewers must evaluate evidence.

Do not claim independent review
from an agent's self-review.

---

# 35. INTEGRATION AND MERGE GATE

Before a parallel PR is merged:

- [ ] Task scope satisfied.
- [ ] Relevant dependencies completed.
- [ ] No unresolved merge conflicts.
- [ ] Shared file ownership respected.
- [ ] API contracts compatible.
- [ ] Database migration order valid.
- [ ] Payment invariants preserved.
- [ ] RLS rules tested when relevant.
- [ ] Relevant Flutter checks pass.
- [ ] Relevant backend tests pass.
- [ ] Required review complete.
- [ ] Documentation updated.

After merge:

1. Verify integrated behavior.
2. Refresh dependent branches.
3. Update GitHub task status.
4. Release temporary locks.
5. Remove completed worktrees safely.
6. Record milestone progress.

Passing tests on isolated branches
does not guarantee merged behavior.

---

# 36. CONFLICT RESOLUTION PLAN

When conflicts occur:

1. Pause affected integration.
2. Preserve both branches.
3. Identify conflicting changes.
4. Review expected behavior.
5. Assign integration owner.
6. Resolve deliberately.
7. Run affected tests.
8. Review security implications.
9. Submit integration changes.
10. Record the outcome.

Never:

- Automatically discard the other agent's code.
- Force-push main.
- Remove important tests.
- Weaken security to remove conflicts.
- Change financial rules without review.

Use a dedicated integration task
for complex shared changes.

---

# 37. PROGRESS TRACKING

Development progress is tracked through:

GitHub Issues:
Live implementation state.

GitHub Pull Requests:
Review and integration state.

TASKS.md:
Master backlog and milestone status.

PLAN.md:
Phase and strategic progress.

## Supported Task States

BACKLOG
READY
CLAIMED
IN_PROGRESS
BLOCKED
IN_REVIEW
DONE
CANCELLED

## Reporting

Progress summaries should contain:

- Current phase
- Active Claude task
- Active Codex task
- Tasks completed
- Tasks blocked
- Open pull requests
- Outstanding dependencies
- Security risks
- Required integration work
- Next ready tasks

Only calculate completion percentages
using actual verified task statuses.

Do not invent progress.

---

# 38. SCHEDULE AND ESTIMATION POLICY

Development timing depends on:

- Requirements readiness
- Feature complexity
- Agent availability
- Review capacity
- External provider decisions
- Test infrastructure
- Security findings
- Integration conflicts

Do not create artificial fixed
completion dates without evidence.

Estimate work at the task level.

Suggested size categories:

S:
Small and isolated task.

M:
Moderate feature with tests.

L:
Complex feature requiring integration.

XL:
Too large; split into smaller tasks.

Avoid assigning large unrelated
changes to a single agent task.

Use completed work and measured
throughput to refine future estimates.

---

# 39. RISK MANAGEMENT

## RISK-001
Payment Gateway Complexity

Impact:
High

Mitigation:
Select provider early.
Implement verified callbacks.
Use sandbox tests.

## RISK-002
Unauthorized Course Access

Impact:
Critical

Mitigation:
Backend entitlement verification,
RLS tests, private storage.

## RISK-003
Fake Bank Receipts

Impact:
High

Mitigation:
Independent bank credit verification,
audit logs, authorized review.

## RISK-004
PDF Content Redistribution

Impact:
High

Mitigation:
Private storage, controlled access,
personalized watermarks, transparent limits.

## RISK-005
Parallel Git Conflicts

Impact:
Medium to High

Mitigation:
Task ownership, separate worktrees,
shared-file coordination, small PRs.

## RISK-006
Database Migration Conflicts

Impact:
High

Mitigation:
Schema contracts and controlled
migration ownership.

## RISK-007
AI-Generated Code Defects

Impact:
High

Mitigation:
Testing, code review,
security checks, acceptance criteria.

## RISK-008
Infrastructure Cost Growth

Impact:
Medium

Mitigation:
Usage monitoring, budgets,
provider evaluation.

## RISK-009
Third-Party Service Failure

Impact:
Medium to High

Mitigation:
Error handling, retry policies,
provider monitoring, recovery procedures.

## RISK-010
Production Data Exposure

Impact:
Critical

Mitigation:
Least privilege, secret management,
RLS, restricted logging, security reviews.

Risks must be reviewed during
major architecture and release decisions.

---

# 40. COST MANAGEMENT

Use a free-first development strategy.

Potential costs include:

- Flutter Web hosting
- Supabase production services
- Database compute
- Storage
- Bandwidth
- Video streaming
- Email delivery
- Payment provider fees
- Monitoring
- Domain registration

Before launch:

- Estimate monthly usage.
- Set approved budget limits.
- Monitor infrastructure usage.
- Identify scaling thresholds.
- Document backup and recovery costs.

Do not assume free tiers
are sufficient for production growth.

Do not choose cheaper infrastructure
by eliminating essential security controls.

---

# 41. ETHICS AND PRIVACY

The application must:

- Collect only necessary data.
- Protect student information.
- Respect copyright.
- Handle receipts securely.
- Disclose personalized watermarks.
- Provide fair payment review.
- Avoid deceptive sales patterns.
- Support accessibility.
- Avoid unnecessary surveillance.

Never:

- Secretly record student screens.
- Fake payment status.
- Use unverified testimonials.
- Make false DRM guarantees.
- Expose sensitive financial documents.
- Collect unrelated personal information.

Review applicable privacy obligations
before production deployment.

---

# 42. ARCHITECTURE DECISIONS

Important decisions require ADRs.

Examples:

ADR-001:
Flutter Web as initial platform.

ADR-002:
Feature-first modular architecture.

ADR-003:
Riverpod state management.

ADR-004:
go_router navigation.

ADR-005:
Supabase backend.

ADR-006:
PostgreSQL and RLS.

ADR-007:
Verified payment architecture.

ADR-008:
Private content storage.

ADR-009:
Protected PDF delivery.

ADR-010:
Protected video delivery.

ADR-011:
Parallel Claude/Codex development.

ADR-012:
Controlled GitHub integration.

ADRs must record:

- Context
- Decision
- Alternatives
- Tradeoffs
- Security impact
- Status
- Approval

---

# 43. OPEN DECISIONS

The following decisions require approval.

DEC-001:
Payment gateway provider.

DEC-002:
Primary billing currency.

DEC-003:
Supported countries and payment regions.

DEC-004:
Course entitlement duration.

DEC-005:
Refund and revocation policy.

DEC-006:
Bank receipt validation limits.

DEC-007:
Protected video provider.
Approved: Mux Basic signed 1080p VOD under CSA-011; PoC gates retained.

DEC-008:
PDF watermark generation strategy.

DEC-009:
PDF resource delivery method.

DEC-010:
Production hosting provider.

DEC-011:
Data retention policy.

DEC-012:
Admin MFA and permission requirements.

DEC-013:
Production backup and recovery targets.

DEC-014:
Production cost limits.
Approved CSA-012 infrastructure ceiling: USD 150/month (35 staging, 95 production,
20 contingency); separate payment fees/quotes/recovery approval retained.

DEC-015:
Final branding approval.

DEC-016:
Supported browser matrix.

DEC-017:
Initial localization requirements.

DEC-018:
Final release acceptance thresholds.

DEC-019:
GitHub ownership and review permissions.

DEC-020:
Formal multi-agent coordination process.

Do not silently assume
unresolved decisions are final.

---

# 44. DEFINITION OF READY

A development task may start when:

- [ ] Requirements are clear.
- [ ] Task ID exists.
- [ ] Priority is assigned.
- [ ] Dependencies are satisfied.
- [ ] Architecture is sufficiently defined.
- [ ] Relevant contracts exist.
- [ ] File scope is documented.
- [ ] Shared ownership is resolved.
- [ ] Security implications are reviewed.
- [ ] Acceptance criteria are testable.
- [ ] Agent assignment confirmed.
- [ ] Workspace is isolated.

---

# 45. DEFINITION OF DONE

A task is DONE only when:

- [ ] Requirements implemented.
- [ ] Approved scope respected.
- [ ] Architecture followed.
- [ ] Relevant tests pass.
- [ ] Static analysis passes.
- [ ] Security boundaries verified.
- [ ] Error handling implemented.
- [ ] UI design consistent.
- [ ] Responsive behavior checked.
- [ ] Accessibility considered.
- [ ] No secrets exposed.
- [ ] Shared changes coordinated.
- [ ] Documentation updated.
- [ ] CI passes.
- [ ] Required reviews completed.
- [ ] Changes merged or formally accepted.
- [ ] Completion evidence recorded.

Generated code is not automatically
verified software.

An unmerged pull request is normally
IN_REVIEW, not DONE.

---

# 46. IMMEDIATE NEXT ACTIONS

Before regular parallel implementation:

- [ ] Approve PLAN.md v2.0.
- [ ] Approve AGENTS.md v2.0.
- [ ] Approve TASKS.md v2.0.
- [ ] Approve CONTRIBUTING.md v2.0.
- [ ] Review SECURITY.md.
- [ ] Complete DATABASE_DESIGN.md.
- [ ] Review and approve docs/TESTING.md.
- [ ] Create CLAUDE.md.
- [ ] Review existing docs/PARALLEL_WORKFLOW.md and approve its workflow.
- [ ] Configure GitHub Issues.
- [ ] Configure task ownership.
- [ ] Configure isolated branches.
- [ ] Configure shared-file coordination.
- [ ] Configure PR templates.
- [ ] Configure CI/CD.
- [ ] Run a two-agent dry-run.
- [ ] Finalize critical business decisions.

Only after these prerequisites are
satisfied should the project scale
regular simultaneous development.

---

# 47. PROPOSED FIRST PARALLEL ITERATION

Purpose:

Validate the development workflow
before critical payment implementation.

Prerequisites:

- Flutter project exists.
- Supabase local tooling exists.
- GitHub workflow configured.
- Task ownership process established.
- Worktree isolation available.

## CLAUDE

Suggested task:
A small isolated Flutter UI component
from the approved backlog.

Responsibilities:

- Implement component.
- Add widget tests.
- Verify responsive behavior.
- Submit PR.

## CODEX

Suggested task:
An independent backend testing
or tooling task.

Responsibilities:

- Implement assigned tooling/test work.
- Run relevant checks.
- Submit PR.

## PROJECT LEAD

- Confirm task independence.
- Approve ownership.
- Review PRs.
- Verify CI results.
- Merge in safe order.
- Confirm no shared file conflicts.
- Record dry-run outcome.

## Success Criteria

- [ ] Two separate workspaces.
- [ ] Two separate branches.
- [ ] Two independent tasks.
- [ ] No conflicting ownership.
- [ ] Both PRs pass required checks.
- [ ] Required reviews complete.
- [ ] Both changes integrate safely.
- [ ] GitHub records updated.

This dry-run validates coordination.

It does not validate the final
payment or content-security architecture.

---

# 48. PROJECT SUCCESS CRITERIA

The MVP is successful when:

Students can:

- Register
- Log in
- Discover courses
- Buy a course securely
- Submit bank receipts
- Receive verified access
- Study protected content
- Read PDFs comfortably
- Resume learning

Administrators can:

- Manage courses
- Manage students
- Review receipts
- Verify payments
- Approve or reject transactions
- Manage enrollments
- Review operational records

The platform:

- Uses trusted financial verification.
- Enforces backend authorization.
- Protects private learning materials.
- Supports responsive layouts.
- Supports light/dark themes.
- Has meaningful automated tests.
- Has documented security limitations.
- Has production monitoring.
- Has verified backup/recovery procedures.

Both development agents:

- Follow shared project rules.
- Use isolated workspaces.
- Respect ownership.
- Deliver tested changes.
- Coordinate shared contracts.
- Integrate through reviewed PRs.

---

# 49. FINAL ENGINEERING DIRECTIVE

Acedra must be built as
secure, professional commercial software.

The development process must be:

SPECIFICATION FIRST.
ARCHITECTURE DRIVEN.
TASK BASED.
PARALLEL WHERE SAFE.
SECURE BY DEFAULT.
TEST DRIVEN.
REVIEWED BEFORE MERGE.
VERIFIED BEFORE RELEASE.

Claude and Codex are independent
engineering contributors.

Parallel execution is allowed only
when work is properly isolated
and dependencies are understood.

The project must protect:

- Student data
- Financial transactions
- Paid course access
- Private PDF documents
- Administrative permissions
- Production infrastructure
- Source code integrity

No agent may:

- Bypass payment verification.
- Disable RLS for convenience.
- Expose server secrets.
- Overwrite another agent's work.
- Fabricate test results.
- Silently change shared contracts.
- Deploy without authorization.
- Claim impossible screenshot protection.
- Mark unverified tasks complete.

ONE TASK - ONE OWNER.
ONE TASK - ONE BRANCH.
ISOLATED AGENT WORKSPACES.
GITHUB AS COORDINATION HUB.
SECURE BACKEND AUTHORITY.
CONTROLLED INTEGRATION.
VERIFIED QUALITY.

BUILD INCREMENTALLY.
TEST CONTINUOUSLY.
REVIEW CAREFULLY.
RELEASE RESPONSIBLY.

END OF PLAN.md
