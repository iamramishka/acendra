# ADR-009: Protected PDF Delivery

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-010, CSA-016

## Context

PDF lessons must be readable at useful quality while access remains
limited to authorized learners. Private storage and entitlement checks are
required. CSA-010 now selects authenticated proxy delivery.

## Decision

Select authenticated proxy delivery of private, server-watermarked personalized
PDF derivatives under the accepted CSA-010 policy. Reauthorize descriptor, GET,
HEAD and range requests against surviving valid grant sources and restrictions.
Do not expose original Storage paths or redirect to signed download URLs. Preserve
immutable derivative versions and fail closed when transformation fails.
See [PDF policy](../requirements/CSA-010-PDF-DELIVERY.md) for watermark, privacy,
cache and range semantics. Runtime/library/reader compatibility and operational
limits remain implementation gates; already delivered bytes cannot be recalled.

## Alternatives considered

- Short-lived signed access to a private object after a trusted entitlement
  check: relatively direct delivery, but the resulting bytes or URL may be
  copied during their usable lifetime.
- An authenticated backend proxy or range-capable streaming endpoint:
  provides a stronger per-request control point, but adds bandwidth,
  performance, and operational cost and must preserve seeking and range
  behavior.
- A specialized document delivery service or viewer: may provide additional
  controls, but introduces provider, privacy, accessibility, integration,
  and cost decisions.

The authenticated proxy strategy is selected; other alternatives remain documented tradeoffs.

## Tradeoffs and evaluation criteria

- Current entitlement and revocation checks at delivery.
- Private storage and least-privilege access.
- Reading quality, zoom, page navigation, fit-to-width, and accessibility.
- Browser cache behavior, link lifetime, range requests, and failure modes.
- Watermark usefulness and privacy disclosure.
- Provider capability, data location, cost, and recovery requirements.
- Honest residual-risk statement: screenshots, recording, and copying by an
  authorized learner cannot be fully prevented in Flutter Web.

## Security and privacy impact

Do not equate signed URLs with uncopiable files. Do not expose service-role
credentials. Do not log full signed URLs or private object paths.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
