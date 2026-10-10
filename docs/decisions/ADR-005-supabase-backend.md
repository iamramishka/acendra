# ADR-005: Supabase as the Backend Platform

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-007, CSA-016, CSA-032

## Context

The application needs authentication, a relational database, private
object storage, and trusted server-side functions. Project documents
propose Supabase as an integrated backend platform.

## Decision

use Supabase services for the initial backend: Supabase Auth, PostgreSQL,
private Supabase Storage, and Edge Functions, subject to separate review
of production configuration, provider capabilities, budget, and operational
requirements.

## Alternatives considered

- Assemble separately operated identity, database, storage, and function
  providers: offers provider choice at each layer but increases integration
  and operational work.
- Build and operate a custom backend platform: allows control over the
  service boundary but adds infrastructure and maintenance beyond the
  proposed MVP.

## Consequences and tradeoffs

- A managed platform can reduce initial infrastructure work.
- Platform coupling, service limits, availability, pricing, and export or
  recovery capabilities require review before production commitment.
- Supabase service-role credentials remain privileged and server-side.
- Selecting Supabase does not select payment, video, email, hosting, or
  monitoring providers.

## Security and privacy impact

Use least-privilege grants and Row Level Security. Treat service-role
access as capable of bypassing RLS. Never place privileged credentials in
Flutter Web assets or client configuration.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
