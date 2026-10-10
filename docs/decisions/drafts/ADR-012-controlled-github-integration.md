# ADR-012: Controlled GitHub Integration

- Status: Proposed workflow; pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-013, CSA-016

## Context

Independent changes need a shared review and integration point. The project
documents identify GitHub issues and pull requests as that coordination
mechanism, while production and security-sensitive changes require human
review.

## Decision

Proposed: use GitHub Issues to record live ownership, dependencies, allowed file
scope, acceptance criteria, and completion evidence once configured. Submit
task branches through pull requests targeting the repository's configured
default branch. Require review and applicable CI before integration; do not
merge a pull request without the required approval.

## Alternatives considered

- Direct commits to the shared default branch: reduces ceremony, but weakens
  review, traceability, and conflict controls.
- Ad hoc chat-only coordination: convenient, but task ownership and
  technical decisions are difficult to audit and hand off.

## Consequences and tradeoffs

- Reviewable diffs and issue records improve traceability.
- Repository settings, branch protection, CI requirements, and required
  approvers must be configured and verified separately.
- Creating a pull request is not evidence of approval or merge readiness.
- No integration policy can substitute for explicit production release
  authorization.

## Security and privacy impact

Protect repository and deployment credentials, use least-privilege
workflow permissions, and keep secrets out of issues, pull requests, logs,
and source. Security-sensitive database, payment, and authorization work
needs appropriate review.

## Approval

Pending Project Lead approval and repository-protection verification.
