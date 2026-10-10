# ADR-006: PostgreSQL with Row Level Security

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-007, CSA-008, CSA-016

## Context

Acedra stores relational course, identity, order, enrollment, and learning
records. Users must not access another student's records by changing a
client query or identifier. The proposed backend uses Supabase/PostgreSQL.

## Decision

use PostgreSQL as the source of truth for relational records and enable
Row Level Security for exposed tables. Define database grants and policies
alongside trusted function authorization; RLS is a defense layer, not a
replacement for correct transaction design.

## Alternatives considered

- Application-only access checks: easier to centralize in one service,
  but a missed endpoint or direct database API path can expose records.
- A non-relational primary database: could fit some document-oriented
  workloads, but does not match the proposed relational entities and
  integrity constraints.

## Consequences and tradeoffs

- Foreign keys and constraints can preserve relationships and valid state.
- Policies need explicit tests for owner, role, and unauthenticated cases.
- Privileged functions require narrow grants and careful review because
  elevated execution can bypass ordinary caller restrictions.
- The schema design follows accepted CSA-008; migrations and negative tests remain required.

## Security and privacy impact

Default to deny. Test cross-user reads and writes, direct API access, and
privileged function execution. Do not disable RLS to work around a failing
query.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
