# ADR-011: Isolated Parallel Engineering

- Status: Proposed workflow; pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-013, CSA-016

## Context

The project expects work by Claude Code and OpenAI Codex. Parallel changes
can shorten delivery time but can conflict on shared files, contracts,
database migrations, and sensitive state machines.

## Decision

Proposed: allow parallel work only when requirements, ownership, dependencies, file
scopes, and integration points are clear. Give each active task one
accountable owner, use an isolated branch/worktree, coordinate shared files,
and integrate through reviewed pull requests.

## Alternatives considered

- A single serial contributor: reduces coordination overhead but limits
  independent work.
- Uncoordinated shared-tree parallel edits: may appear faster, but risks
  overwrites, inconsistent contracts, and untraceable ownership.

## Consequences and tradeoffs

- Independent modules can proceed concurrently when boundaries are stable.
- Conflicting migrations, payment changes, and shared architecture work
  must be serialized or coordinated.
- Isolation and reviews add setup and integration overhead.
- Suggested owner labels in `TASKS.md` do not replace confirmed assignment
  or live issue ownership.

## Security and privacy impact

Parallelism does not relax security, test, or review requirements. Agents
must not edit another owner's worktree or change shared contracts silently.

## Approval

Pending Project Lead approval of the proposed workflow and related
`AGENTS.md`/`docs/PARALLEL_WORKFLOW.md` policies.
