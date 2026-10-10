# ADR-008: Private Course Content with Entitlement Authorization

- Status: Proposed security invariant; delivery details pending
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-006, CSA-010, CSA-011, CSA-016

## Context

Paid PDF, video, image, and text lessons are proprietary course assets.
Access depends on an active entitlement for the correct user and course.
Browser-delivered bytes cannot be made impossible to copy.

## Decision

Proposed: store protected assets privately and authorize each protected delivery
using trusted identity and entitlement state. Verify ownership, course,
resource, entitlement status, expiry, and revocation at the trusted
delivery boundary. Keep the exact PDF and video delivery mechanisms open
for their dedicated decisions.

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

Pending Project Lead approval. The baseline does not settle CSA-010 PDF
delivery or CSA-011 video provider selection.
