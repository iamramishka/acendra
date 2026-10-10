# Draft Architecture Decision Records

Status: Proposed; none of these records is approved.

These records capture the initial architecture proposals requested by
CSA-016. They are design drafts, not evidence that a choice is implemented
or authorized for production. The Project Lead must approve or reject each
record, and unresolved product or provider decisions remain open until
recorded by the appropriate task owner.

## Records

| Record | Topic | Current status |
| --- | --- | --- |
| [ADR-001](ADR-001-flutter-web.md) | Flutter Web as the MVP platform | Proposed |
| [ADR-002](ADR-002-feature-first-architecture.md) | Feature-First Clean Architecture | Proposed |
| [ADR-003](ADR-003-state-management.md) | Riverpod state management | Proposed |
| [ADR-004](ADR-004-navigation.md) | go_router navigation | Proposed |
| [ADR-005](ADR-005-supabase-backend.md) | Supabase backend | Proposed |
| [ADR-006](ADR-006-postgresql-rls.md) | PostgreSQL and Row Level Security | Proposed |
| [ADR-007](ADR-007-trusted-payments.md) | Trusted payment verification and finalization | Proposed invariant; provider open |
| [ADR-008](ADR-008-private-course-content.md) | Private course content and entitlement checks | Proposed invariant; delivery details open |
| [ADR-009](ADR-009-protected-pdf-delivery.md) | Protected PDF delivery | Pending Project Lead decision |
| [ADR-010](ADR-010-protected-video-delivery.md) | Protected video delivery | Pending Project Lead decision |
| [ADR-011](ADR-011-parallel-engineering.md) | Isolated parallel engineering | Proposed workflow |
| [ADR-012](ADR-012-controlled-github-integration.md) | Reviewed GitHub integration | Proposed workflow |

## Approval and numbering notes

- `PLAN.md` section 42 defines twelve topics and is the numbering basis
  used for this draft set. `ARCHITECTURE.md` section 4 currently contains
  a shorter summary whose ADR-009 and ADR-010 topics use different
  numbering. This set does not silently rewrite that shared document;
  reconcile the summaries as part of the Project Lead's architecture
  approval before accepting any records.
- `ARCHITECTURE.md`, `PLAN.md`, and `TASKS.md` are marked Proposed or have
  unchecked approval tasks. Their statements are treated as proposals or
  constraints, not as approved project policy.
- Records with pending decisions list constraints and candidate tradeoffs
  only. They do not select a payment, PDF, video, hosting, or monitoring
  provider, or set business, privacy, budget, or retention policy.
- To approve a record, the Project Lead should set its status to Accepted,
  record the approver and date, and move it from `drafts/` to the approved
  `docs/decisions/` directory. Rejected or superseded records should remain
  available with their status and a link to the replacing decision.
