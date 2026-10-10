# ADR-008: Private Course Content with Entitlement Authorization

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-006, CSA-010, CSA-011, CSA-016

## Context

Paid PDF, video, image, and text lessons are proprietary course assets.
Access depends on an active entitlement for the correct user and course.
Browser-delivered bytes cannot be made impossible to copy.

## Decision

store protected assets privately and authorize each protected delivery
using trusted identity and entitlement state. Verify ownership, course,
resource, entitlement status, expiry, and revocation at the trusted
delivery boundary. PDF delivery follows accepted CSA-010 proxy/derivative rules;
video provider selection remains open under CSA-011.

## Alternatives considered

- Public object storage or obscured object paths: convenient, but paths
  are discoverable or shareable and do not enforce entitlement.
- Frontend-only route guards: improve navigation, but do not protect direct
  API or object access.
- Claiming complete download or screenshot prevention: not technically
  supportable for content rendered in an authorized browser.

## Consequences and tradeoffs

- Delivery services must integrate with entitlement state and revocation.
- Access checks may add server or storage-policy work to content requests.
- Short-lived credentials, proxying, watermarking, and caching behavior
  need separate design and privacy review.
- An authorized user may still capture displayed content or delivered bytes.

## Security and privacy impact

Fail closed when entitlement checks fail. Do not expose private object
references in public catalog data or logs. Disclose approved watermark
practices and avoid collecting unrelated learner data.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
