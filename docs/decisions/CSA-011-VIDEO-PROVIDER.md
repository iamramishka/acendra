# CSA-011: Protected video provider selection

Date: 2026-10-11 (Asia/Colombo)
Status: IN_REVIEW - recommendation prepared; Project Owner approval pending
Preparation owner: CODEX video-budget agent
Integration base: e1cf11f (origin/dev); branch: codex/docs/csa-011-phase0-review
Scope: this document only. No account, paid service, dependency or runtime change.

## Recommended decision

Select **Mux Video, Basic on-demand quality, pay-as-you-go, signed playback only**, initially limited to 1080p. Use a trusted Supabase Edge Function to authorize each lesson and sign playback credentials. Use a pinned Mux Player web component through a Flutter Web platform view, subject to the proof-of-concept gates below. This is a proposed selection, not an approved purchase or verified integration.

Mux best fits the small MVP because it combines signed adaptive browser playback, a documented web player, and favorable initial delivery allowances. Cloudflare Stream is the fallback if the Mux integration or privacy review fails. A DRM requirement would reopen selection and budget approval before implementation.

## Requirements and inspected evidence

- TASKS.md: CSA-011; SRS.md: FR-VIDEO-001..008, FR-LEARN-010, FR-ENROLL-003/006/008, NFR-SEC-001..012, NFR-PRIV-001/004/009, section 11.4.
- SECURITY.md section 23: backend entitlement checks, limited sessions, expiry, revocation and honest streaming limitations.
- ARCHITECTURE.md section 38; PLAN.md external providers and cost management; AGENTS.md sections 17, 33, 35 and 39; docs/PARALLEL_WORKFLOW.md.
- Read current origin/dev ADR-010 and approved CSA-003/004/006 policies after the coordinator verified merged PRs #1-5. Paid access is lifetime (no scheduled expiry); refund confirmation invalidates its funding grant and recomputes surviving access. Temporary complimentary grants and broader restrictions remain distinct. Existing approvals are preserved; only the video/provider choices in this record await approval.
- Local ownership and exclusive file scope are recorded in the CSA-011-017 parallel board on the coordinator's CSA-013 branch. No related GitHub issue was available at allocation.

## Provider comparison

Published provider capabilities and prices were checked on 2026-10-11. Dollar values are USD before tax. Browser integration conclusions are engineering assessments, not measurements in this repository.

| Provider | Protected delivery and web integration | Pricing shape | Assessment |
| --- | --- | --- | --- |
| Mux | Signed playback IDs/JWTs and playback restrictions; HTML web component or iframe; optional paid DRM | Basic input free; 1080p storage $0.003/min/month; first 100,000 delivery minutes/month free, then $0.001/min in the initial tier; PAYG $20 monthly usage credit | Recommended; strong initial economics and future DRM option. Token renewal, Flutter focus and telemetry require validation. |
| Cloudflare Stream | Videos are public by default; explicitly require signed URLs. Signed iframe or HLS/DASH manifests | $5/month per prepaid 1,000 stored minutes; $1 per 1,000 delivered minutes; encoding and bandwidth included | Good fallback; simple cost model, but higher delivery cost at the proposed MVP scale. |
| Bunny Stream | Separate embed-token and underlying CDN-token controls; web embed; MediaCage options | Storage from $0.01/GB; delivery from $0.005/GB; $1 monthly minimum | Viable alternative; advertised starting rates are not a Sri Lanka traffic quote. Bitrate, region, replicas and DRM pricing need a separate estimate. Protect both embed and media URLs. |

Sources: [Mux pricing](https://www.mux.com/docs/pricing/overview), [Mux secured playback](https://www.mux.com/docs/guides/secure-video-playback), [Mux web player](https://www.mux.com/docs/guides/player-integrate-in-your-webapp), [Cloudflare protection](https://developers.cloudflare.com/stream/viewing-videos/securing-your-stream/), [Cloudflare pricing](https://developers.cloudflare.com/stream/pricing/), [Bunny security](https://bunny.net/docs/stream/security), [Bunny pricing](https://bunny.net/pricing/stream/).

Unlisted public links fail FR-VIDEO-007. Raw private object delivery would require separate encoding/player/bandwidth work, so it is not the recommended MVP route. No native Flutter SDK compatibility is asserted; the recommendation targets Flutter Web only.

## Cost scenarios

Planning assumptions, not measured demand: 10 courses x 120 video minutes = 1,200 stored production minutes; 1080p ceiling; no live streaming, static downloadable renditions, AI workflows or DRM. Delivered minutes count actual provider usage, including repeated viewing and prefetch; student watch-time is only a forecast proxy.

Formula for this range: gross Mux monthly video usage = stored minutes x 0.003 + max(0, delivered minutes - 100,000) x 0.001. Use gross spend for budgeting; the published PAYG credit can reduce the invoice, but should not be required for viability. Basic assets have a minimum one-month storage charge; deletion of temporary uploads need not eliminate that charge.

| Scenario | Learners x watch minutes/month | Delivered minutes | Mux gross/month | Cloudflare/month |
| --- | --- | --- | --- | --- |
| Pilot | 100 x 120 | 12,000 | $3.60 | $22 |
| MVP | 500 x 180 | 90,000 | $3.60 | $100 |
| Growth | 2,000 x 240 | 480,000 | $383.60 | $490 |

Cloudflare storage rounds 1,200 minutes to two prepaid blocks ($10). Examples exclude taxes, originals/backups, backend, player hosting and payment fees. Separate staging fixtures (60 minutes stored, 2,000 delivered) add $0.18 gross Mux usage under the shared free-delivery assumption. Allowances must be confirmed at account/billing scope and shared with other apps; credits are not a separate allowance per environment. CSA-012 reserves $25/month for initial video usage and triggers reassessment as viewing grows.

## Proposed integration and security contract

This describes the contract to finalize with frontend/backend owners; it does not establish an implemented API.

1. POST authenticated lesson ID to a trusted playback endpoint. Verify the Auth token and current user, published lesson/media association, course identity, active valid entitlement or separately authorized preview, restrictions and applicable expiry. Accept no client role, course entitlement or arbitrary playback ID as authority.
2. Resolve the provider playback ID server-side. Issue video-scoped signed JWTs only. Paid assets must have no public playback IDs. Independently protect any thumbnail/storyboard credentials; expose no master downloads or static MP4 rendition by default.
3. Proposed token TTL: 300 seconds, refresh at 240 seconds with a fresh authorization check. Clamp TTL to any earlier entitlement expiry. Mux warns expired signed URLs interrupt playback already in progress; renewal/resume must therefore be proven before adopting this short TTL. Do not extend TTL silently to hide interruptions. [Expiration behavior](https://www.mux.com/docs/guides/secure-video-playback).
4. Deny every new/refresh token after revocation, refund invalidation or an applicable restriction. A previously issued bearer token can be replayed until expiration; already delivered/buffered bytes remain available. Five minutes bounds credential validity, not an absolute promise that viewing stops within five minutes. Immediate per-user CDN revocation is not claimed.
5. Return only provider, playback ID, required signed token types and expires_at; use Cache-Control: no-store. Errors: 401 unauthenticated, 403 unauthorized, 404 absent/unavailable lesson, 429 throttled, 503 provider or signing failure. Do not expose internal provider errors or credentials. Every retry rechecks access; no financial side effect.
6. Keep signing keys/API credentials in backend secrets with environment separation and rotation. Apply per-user/global request throttles and upload limits, log authorization decision IDs rather than JWTs/full signed URLs, and redact query strings from monitoring. Domain restrictions supplement entitlement checks; they do not bind a bearer token to the student.
7. Record learning progress through a separate authenticated ownership-checked API; client progress is not evidence for payment, entitlement or refunds. Validate position against lesson duration, throttle writes and preserve progress through renewal/network recovery.

## Player, privacy and operational gates

Use a small feature-owned adapter around the web component with event cleanup on navigation, clear loading/error/expiry UI and accessible focus. Pin/audit the JS distribution and license, define exact CSP connect/media/script origins and validate CORS. Do not introduce a package or global CSP change without shared-file ownership.

Disable optional Mux Data tracking and cookies initially (`disable-tracking`, `disable-cookies`); independently inspect network traffic because transport necessarily exposes request data to the delivery provider. Do not put student name, email, payment details or user IDs in provider metadata. [Player privacy controls](https://www.mux.com/docs/guides/player-api-reference/html).

Owner/security review must approve processor terms, subprocessors, international transfers, retained telemetry, deletion/export process and privacy notice under CSA-015. No local data residency or legal compliance guarantee is made by selecting a CDN. Retain authorized source masters outside the provider under the approved backup/access policy so migration does not depend on public downloads.

Signed delivery controls access but does not prevent screen recording or determined authorized copying. DRM is excluded from the proposed MVP. The current Mux add-on is $100/month plus $0.003/license; if owner/content contracts require DRM, evaluate browser support, licensing and a new budget before adopting it. [DRM price](https://www.mux.com/docs/pricing/overview).

## Acceptance and approval checklist

Documentation preparation is complete when comparison, sources, scenarios, proposed contract, residual risks and owner choices are reviewed. Runtime gates below remain unexecuted.

- [ ] Project Owner accepts Mux Basic signed delivery, 1080p ceiling, no DRM and residual replay/capture risk; approver/date recorded.
- [ ] CSA-012 cost envelope and CSA-015 provider processing/privacy controls accepted.
- [ ] Staging PoC proves Chrome, Edge, Firefox and Safari playback, including mobile Safari/Chrome, at 390/768/1440 and narrow 320px widths, light/dark themes.
- [ ] Play/pause, seek, volume, fullscreen, loading/error, captions, speed and progress/resume checked; keyboard/screen-reader focus works across Flutter and embedded player.
- [ ] Direct unsigned manifest/thumbnail/download requests fail; unpaid, logged-out, wrong-course, expired, revoked and restricted users cannot obtain credentials.
- [ ] Tampered/expired tokens and environment crossover fail; valid enrolled student succeeds. Existing token replay window and buffering after revocation are measured and accepted.
- [ ] At least a 30-minute lesson survives multiple 5-minute renewals, seek across expiry, background tab, network loss and renewal denial with correct progress. If renewal fails, owner decides a documented longer exposure window or alternative architecture/provider.
- [ ] Synthetic Sri Lanka-facing test records startup/rebuffer performance and actual provider billed minutes; performance targets are coordinated with CSA-017, not fabricated here.
- [ ] Source-master recovery and provider deletion/key rotation rehearsed; privacy/network, CSP and credential-redaction checks pass.

Approval record: Project Owner = pending; security/privacy reviewer = pending; budget approval = pending; PoC evidence = none. Only reviewed integration may update ADR-010, PLAN.md and ARCHITECTURE.md provider fields.

## Handoff

Task/owner: CSA-011 / CODEX preparation. Status: IN_REVIEW.
Files changed: docs/decisions/CSA-011-VIDEO-PROVIDER.md only.
Shared contracts changed: none; proposed contract requires coordinated acceptance.
Checks: git diff --check and document self-review; no Flutter/backend/provider runtime tests for this documentation-only change. Commit/PR: recorded by coordinator after submission.
Remaining: owner decisions, independent review, budget/privacy reconciliation and separate PoC task. Next owner: Project Owner for decision, designated backend/frontend owners for verified implementation. No purchase, deployment, merge or DONE claim.
