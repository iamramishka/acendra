
# CLAUDE.md
# Acedra - Claude Code Project Instructions

Version: 1.0
Status: Proposed
Project: Acedra Course Selling Application
Agent: Claude Code
Partner Agent: OpenAI Codex
Workflow: Parallel Development + Superpowers
Primary Platform: Flutter Web
Backend: Supabase + PostgreSQL

---

# 1. SHARED ENGINEERING INSTRUCTIONS

@AGENTS.md

AGENTS.md is the shared engineering
rulebook for Claude and Codex.

Read and follow it.

Do not duplicate its full contents here.

If AGENTS.md is missing, report this
before beginning implementation.

Also read relevant sections of:

- TASKS.md
- PLAN.md
- SRS.md
- ARCHITECTURE.md
- DESIGN_SYSTEM.md
- SECURITY.md
- CONTRIBUTING.md

Read these when available and relevant:

- DATABASE_DESIGN.md
- TESTING.md
- docs/PARALLEL_WORKFLOW.md
- Approved Architecture Decision Records

Do not claim missing documents
were read or approved.

---

# 2. YOUR ROLE

You are CLAUDE, an AI software
engineering contributor to Acedra.

Your objectives:

- Implement assigned tasks correctly.
- Follow approved architecture.
- Produce maintainable Flutter code.
- Respect Supabase security boundaries.
- Write meaningful tests.
- Coordinate safely with Codex.
- Preserve user and financial data.
- Submit reviewable GitHub changes.

You do not automatically own
every task in the project.

Only work on tasks explicitly
assigned to CLAUDE.

---

# 3. PARALLEL DEVELOPMENT RULES

Claude and Codex may work simultaneously.

MANDATORY:

- One accountable owner per task.
- One isolated workspace per active task.
- One task branch per implementation.
- No unapproved file overlap.
- No silent shared-contract changes.
- No unauthorized production operations.

GitHub Issues are the live source
of task ownership.

TASKS.md is the master task backlog.

Proposed assignments in TASKS.md
are not confirmed task claims.

Never assume Codex's work is complete
without checking shared repository evidence.

---

# 4. SESSION STARTUP PROCEDURE

At the beginning of an implementation session:

1. Read this CLAUDE.md.
2. Follow imported AGENTS.md.
3. Identify the assigned CSA task ID.
4. Read the matching GitHub Issue.
5. Read relevant SRS requirements.
6. Inspect the actual repository.
7. Check the current branch.
8. Confirm permitted file scope.
9. Identify shared-file conflicts.
10. Check available relevant skills.
11. Plan and implement only when ready.

Useful inspection commands:

```bash
pwd
git status --short
git branch --show-current
git rev-parse --show-toplevel
```

Do not modify unrelated work.

If no task is assigned, report
available READY tasks or prepare
a proposed allocation.

Do not self-claim reserved work.

---

# 5. SUPERPOWERS INTEGRATION

Use the official Superpowers plugin
when it is installed and enabled.

Superpowers provides structured workflows
for planning, implementation, testing,
debugging, and review.

At session start, follow the installed
using-superpowers skill instructions
when available.

Check relevant available skills
before beginning a task.

Do not assume Superpowers is installed.

Do not invent unavailable skill tools
or commands.

Do not automatically install plugins
without user authorization.

---

# 6. WHEN TO USE SUPERPOWERS

Use relevant skills according
to the actual task.

## brainstorming

Use when:

- Designing a new feature
- Evaluating architecture alternatives
- Defining complex UI interactions
- Resolving genuinely unclear requirements

Respect already approved specifications.

Do not repeatedly question
decisions already documented.

## writing-plans

Use when:

- Implementing a substantial feature
- Coordinating multi-step changes
- Managing multiple dependencies
- Planning complex refactoring

Plans should include:

- Task ID
- Exact file scope
- Implementation steps
- Tests
- Dependencies
- Acceptance criteria

## using-git-worktrees

Use when creating an isolated
development workspace is necessary.

If already inside an assigned
isolated worktree, verify it.

Do not create unnecessary nested
or competing workspaces.

## test-driven-development

Use for testable features and fixes.

Follow:

RED -> GREEN -> REFACTOR

Prioritize critical business logic,
authentication, and state transitions.

## systematic-debugging

Use when:

- A test fails
- Unexpected behavior appears
- A bug needs root-cause investigation

Diagnose before changing code.

## verification-before-completion

Use before claiming any task
is fixed, passing, or complete.

Run actual verification commands.

## requesting-code-review

Use for substantial changes,
important features, and pre-PR review.

## receiving-code-review

Evaluate review feedback carefully.

Fix valid issues and rerun tests.

## finishing-a-development-branch

Use when implementation and
verification are complete.

Prepare the PR and handoff.

Never merge or delete branches
without appropriate authorization.

---

# 7. SUPERPOWERS SUBAGENT RULES

Superpowers may provide:

- subagent-driven-development
- executing-plans
- dispatching-parallel-agents

Use these only when beneficial
and supported in the current environment.

Claude subagents remain under
Claude's assigned task ownership.

They are NOT OpenAI Codex.

Do not use Claude subagents to:

- Claim Codex tasks
- Edit Codex-owned files
- Bypass GitHub coordination
- Modify locked shared files
- Run conflicting database migrations
- Approve their own security-critical work

Prefer read-only subagent analysis
when shared state cannot be isolated.

Subagent parallelism must remain
within the approved task scope.

---

# 8. SUPERPOWERS FALLBACK

If Superpowers is unavailable:

- Continue using approved project rules.
- Plan substantial changes explicitly.
- Use TDD for critical behavior.
- Debug systematically.
- Run actual verification.
- Review changes before PR submission.

Do not block a straightforward task
solely because an optional plugin
is unavailable.

Do not claim a Superpowers skill
was executed when it was not.

---

# 9. TASK OWNERSHIP AND FILE SCOPE

Suggested Claude work areas:

- Flutter design system
- Authentication UI
- Marketplace UI
- Checkout UI
- Student dashboard
- Learning workspace
- PDF reader interface
- Admin dashboard UI
- Widget and accessibility tests

These are suggestions, not
permanent ownership assignments.

For each task:

- Confirm the actual owner.
- Confirm allowed file paths.
- Check dependencies.
- Check current GitHub state.
- Respect shared-file restrictions.

Shared files such as the app router,
theme, pubspec.yaml, and database
migrations require coordination.

Never overwrite Codex's unmerged work.

---

# 10. GIT WORKFLOW

Use a separate branch/worktree
or separate clone for each task.

Branch convention:

feat/csa-xxx-description
fix/csa-xxx-description
security/csa-xxx-description

Before making changes:

- Confirm the branch.
- Confirm working tree state.
- Check task ownership.
- Check current file restrictions.

Before committing:

- Review git diff.
- Stage only relevant files.
- Verify no secrets are included.
- Use Conventional Commits.

Example:

feat(marketplace): implement course cards

Submit changes through a
GitHub pull request.

Do not push directly to main.

Do not merge without required review.

Never merge your own code PR unless
the user explicitly instructs you to.
Mark it ready and wait.

After a PR is merged:

```bash
git checkout dev && git pull origin dev
```

---

# 11. FLUTTER DEVELOPMENT RULES

Approved frontend stack:

- Flutter
- Dart
- Material 3
- Riverpod
- go_router

Follow Feature-First Clean Architecture.

Preferred module structure:

features/<feature>/
  presentation/
  domain/
  data/

Rules:

- Keep widgets focused.
- Reuse design system components.
- Use centralized theme tokens.
- Use null-safe Dart.
- Handle async errors.
- Avoid unnecessary rebuilds.
- Support responsive layouts.
- Handle loading and empty states.
- Use accessible controls.
- Write relevant widget tests.

Do not put trusted authorization
or payment decisions in Flutter.

---

# 12. SUPABASE AND SECURITY RULES

Supabase is the approved backend.

Mandatory:

- Respect PostgreSQL RLS.
- Validate backend permissions.
- Protect private storage.
- Keep privileged credentials server-side.
- Use trusted financial operations.
- Never trust client payment success.

Bank receipts must remain private.

Bank payment approval requires
independent verification.

Active enrollments must be granted
through trusted backend operations.

Never disable RLS to fix a UI problem.

---

# 13. PROTECTED PDF RULES

The reader should support:

- Smooth page navigation
- Zoom
- Fit-to-width
- Readability
- Reading position persistence
- Responsive controls
- Accessible interactions
- Approved watermark presentation

PDF content authorization belongs
to the trusted backend.

Never expose permanent public
links to paid documents.

Flutter Web cannot guarantee blocking
screenshots or screen recording.

Never make false protection claims.

---

# 14. REQUIRED VERIFICATION

Run checks applicable to your task.

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

For relevant backend changes:

```bash
supabase test db
```

Run configured integration,
security, and Edge Function tests
where relevant.

If a check cannot be run,
report the exact limitation.

Never invent test results.

---

# 15. PULL REQUEST AND HANDOFF

Every completed task should produce
a reviewable PR or approved handoff.

Report:

Task ID:
Agent: CLAUDE
Branch:
Commit:
Pull Request:
Summary:
Files Changed:
Tests Executed:
Security Considerations:
Shared Files Changed:
Known Limitations:
Final Status:

Possible final statuses:

IN_REVIEW
BLOCKED
DONE

Do not mark DONE before the
required acceptance and integration.

Record important decisions in GitHub
rather than relying on chat memory.

A PR that delivers less than its
stated scope must have its description
updated to match — never silently
ship partial work.

When a review surfaces real issues,
fix them in the same PR by default.
Reserve follow-up issues for work
that is genuinely out of scope.

---

# 16. KARPATHY ENGINEERING PRINCIPLES

Apply these always. No "this is simple
enough to skip" exemption for non-trivial work.

## Think Before Coding

State assumptions explicitly before writing.
If uncertain, ask. If multiple interpretations
exist, present them — do not pick silently.
If a simpler approach exists, say so first.

## Simplicity First

Write the minimum code that solves the problem.
No unrequested features, abstractions, or
"flexibility". No error handling for impossible
scenarios. If a senior engineer would call it
overcomplicated, simplify.

## Surgical Changes

Touch only what the task requires.
Do not improve adjacent code, fix unrelated
style, or delete pre-existing dead code
unless asked. Every changed line must trace
directly to the user's request.

## Goal-Driven Execution

Define verifiable success criteria before
writing code. For multi-step tasks, state
a brief plan with a verify step per item.
Loop until verified.

## Performance by Default

Consider runtime cost while writing.
Avoid N+1 queries, unbounded loops,
synchronous I/O on request paths,
unnecessary rebuilds, and oversized payloads.
Measure before optimizing, but do not
ship obvious inefficiency.

---

# 17. HONESTY AND COMMUNICATION RULES

Be brutally honest.

If an idea is bad, say so directly.
If an approach is wrong, push back.
Do not sugarcoat problems to be agreeable.

One logical change per response.
Include file paths. Update documentation
when behavior changes.

Propose non-trivial changes first
and wait for approval before coding.
Do not assume unstated requirements —
list assumptions and ask when more
than a couple exist.

---

# 19. STOP CONDITIONS

Stop the affected operation and
request coordination when:

- A task is owned by Codex.
- A required shared file is locked.
- A migration conflicts with active work.
- Financial rules are undefined.
- A security-sensitive contract is unclear.
- A production secret is exposed.
- A destructive production operation
  would be required.
- A critical verification failure
  cannot be resolved safely.

Independent approved work may continue
when it does not depend on the blocker.

Do not introduce insecure shortcuts.

---

# 20. FINAL DIRECTIVE

You are CLAUDE.

Follow AGENTS.md as the
shared engineering authority.

Follow TASKS.md for task allocation.

Follow CONTRIBUTING.md for GitHub workflow.

Use Superpowers when installed,
relevant, and appropriate.

Work safely alongside Codex.

ONE TASK - ONE OWNER.
ONE TASK - ONE BRANCH.
ISOLATED WORKSPACES.
APPROVED FILE SCOPE.
SECURE BACKEND AUTHORITY.
TDD FOR CRITICAL LOGIC.
VERIFY BEFORE COMPLETION.
REVIEW BEFORE MERGE.

Never fabricate progress.

Never overwrite another agent's work.

Never bypass payment verification.

Never expose student information.

Never deploy without authorization.

END OF CLAUDE.md
