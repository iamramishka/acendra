# ADR-003: Riverpod for Client State Management

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-007, CSA-016

## Context

The Flutter client needs to compose asynchronous authentication, catalog,
checkout, and learning state while remaining testable and responsive.
Project documents propose Riverpod.

## Decision

use Riverpod for application-level dependency injection and state where
shared or asynchronous state needs an explicit lifecycle. Keep short-lived
widget state local when that is simpler.

## Alternatives considered

- Flutter's built-in state primitives: suitable for local state and small
  flows, but may become difficult to coordinate for application-wide
  asynchronous dependencies.
- BLoC/Cubit: provides explicit event/state patterns, but would introduce a
  different project-wide convention and dependency choice.

## Consequences and tradeoffs

- Providers offer testable seams and explicit dependency composition.
- Teams need consistent provider naming, scope, and disposal practices.
- Do not move every local UI value into global state or duplicate server
  authorization in client state.

## Security and privacy impact

Client state is mutable and can be inspected or changed by the user.
Provider state must not hold privileged secrets or serve as proof of a
role, payment, or entitlement.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
