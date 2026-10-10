# Architecture Decision Records

Reconciled: 2026-10-11. Approver: project owner through accepted CSA-007 and
related CSA-001..008/010 baselines. Acceptance approves design; implementation,
configuration and production verification remain separate. CSA-013 governance
review remains open.

| Record | Decision | Status |
| --- | --- | --- |
| [ADR-001](ADR-001-flutter-web.md) | Flutter Web MVP | Accepted |
| [ADR-002](ADR-002-feature-first-architecture.md) | Feature-first clean architecture | Accepted |
| [ADR-003](ADR-003-state-management.md) | Riverpod | Accepted |
| [ADR-004](ADR-004-navigation.md) | go_router | Accepted |
| [ADR-005](ADR-005-supabase-backend.md) | Supabase backend | Accepted; operational gates |
| [ADR-006](ADR-006-postgresql-rls.md) | PostgreSQL and RLS | Accepted; migration/test gates |
| [ADR-007](ADR-007-trusted-payments.md) | Trusted payments; PayHere/LKR | Accepted; verification gates |
| [ADR-008](ADR-008-private-course-content.md) | Private content and grant checks | Accepted |
| [ADR-009](ADR-009-protected-pdf-delivery.md) | Authenticated personalized PDF proxy | Accepted; runtime/reader gates |
| [ADR-010](drafts/ADR-010-protected-video-delivery.md) | Protected video delivery | Pending CSA-011 |
| [ADR-011](ADR-011-parallel-engineering.md) | Isolated coordinated work | Accepted architectural boundary |
| [ADR-012](ADR-012-controlled-github-integration.md) | Reviewed GitHub integration | Accepted; protections/CI gates |

See [completion reconciliation](../requirements/CSA-009-016-RECONCILIATION.md)
for approval provenance and remaining work. Draft history remains in Git/PR #2.
