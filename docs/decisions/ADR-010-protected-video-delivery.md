# ADR-010: Protected Video Delivery

- Status: Accepted selection; implementation, privacy and playback PoC gates retained
- Decision owner/approver: Project owner
- Date: 2026-10-11 (Asia/Colombo)
- Related tasks: CSA-011, CSA-012, CSA-015, CSA-016, CSA-017
- Approval: owner replied "go ahead" after the six review proposals were presented;
  [PR #7](https://github.com/iamramishka/acendra/pull/7) merged reviewed head 25dda5b.

## Decision

Use Mux Video Basic on-demand, pay-as-you-go, signed playback only, initially
1080p and without DRM. Authorize lesson/media access on the trusted backend from
current identity, course grant and restrictions; keep API/signing keys server-side.
Use a pinned web player through a Flutter Web adapter only after compatibility,
privacy and accessibility validation. No public playback IDs or unrestricted
download renditions for paid lessons. Domain restrictions supplement authorization.

Five-minute tokens refreshed at four minutes are a conditional integration design,
not an established capability. Prove renewal, seeking, background/network recovery
and denial in a representative long lesson. Deny new credentials after access
revocation, while disclosing replay until expiry and already buffered/delivered bytes.
If renewal fails, obtain an accepted exposure/architecture revision; do not silently
lengthen tokens or claim immediate CDN revocation.

## Alternatives and consequences

Mux was selected for signed adaptive delivery and favorable modeled MVP economics.
Cloudflare Stream is the evaluated fallback; Bunny Stream and private/self-managed
delivery require different regional/security/cost assumptions. Full pricing evidence,
comparison and scenarios are in [CSA-011](CSA-011-VIDEO-PROVIDER.md).

Vendor dependence, billing growth, processor telemetry and international processing
remain risks. Disable optional analytics/cookies and verify actual transport metadata.
Retain private source masters for recovery/migration. Credentials and assets are
separated across environments, but free billing allowances are not assumed separate.
Signed delivery cannot prevent copying, screenshots or recording. DRM needs a new
requirement, browser/license evaluation and budget approval.

## Acceptance boundaries

CSA-012's USD 150 infrastructure envelope and CSA-015 control baseline are accepted
planning constraints. Account provisioning, actual vendor quotes/terms, regional
latency, PoC, secure API contract alignment and production readiness remain gates.
Captions, speed and persisted video timestamp resume retain their approved SHOULD
scope; no deferred feature is promoted by this ADR.

See [owner acceptance record](../requirements/CSA-011-017-APPROVAL.md). This ADR
approves selection and constraints, not purchases, working implementation, legal
compliance or production deployment.
