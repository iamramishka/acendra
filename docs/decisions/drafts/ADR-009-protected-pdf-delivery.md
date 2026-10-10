# ADR-009: Protected PDF Delivery

- Status: Decision pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-010, CSA-016

## Context

PDF lessons must be readable at useful quality while access remains
limited to authorized learners. Private storage and entitlement checks are
required, but project documents do not approve a delivery mechanism.

## Decision

No delivery mechanism is selected in this record. CSA-010 must compare
candidate approaches and obtain Project Lead approval before implementation
relies on a PDF delivery contract.

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

These are comparison candidates, not recommendations or selected products.

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

Pending CSA-010 and Project Lead approval. No implementation mechanism is
authorized by this draft.
