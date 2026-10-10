# ADR-010: Protected Video Delivery

- Status: Decision pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-011, CSA-016

## Context

Video lessons need reliable playback while paid content remains available
only to authorized learners. The project requires a separate protected
video provider decision and has not approved a provider or delivery design.

## Decision

No provider or delivery mechanism is selected in this record. CSA-011
must compare providers and obtain Project Lead approval before the client
or backend adopts a provider-specific contract.

## Alternatives considered

- Private object storage with authenticated short-lived delivery: may fit
  simple assets, but a browser receives media data and copying remains
  possible; adaptive streaming and bandwidth economics need evaluation.
- Managed streaming with signed playback credentials: may provide adaptive
  playback and operational features, but adds provider dependence, cost,
  data-processing terms, and token integration.
- Self-managed streaming infrastructure: offers operational control, but
  requires encoding, delivery capacity, monitoring, and maintenance that
  may exceed MVP needs.

These are categories for evaluation, not provider recommendations.

## Tradeoffs and evaluation criteria

- Entitlement and revocation checks before playback authorization.
- Browser/device compatibility, adaptive playback, captions, and
  accessibility.
- Credential lifetime, replay risk, CDN behavior, and access logging.
- Privacy terms, data location, availability, cost, and operational burden.
- Honest residual risk: browser playback cannot prevent screen recording,
  external capture, or copying by an authorized learner.

## Security and privacy impact

Keep signing credentials server-side. Do not treat unlisted URLs or client
route guards as authorization. Minimize playback telemetry and document
approved monitoring.

## Approval

Pending CSA-011 and Project Lead approval. No provider selection or
production commitment is made by this draft.
