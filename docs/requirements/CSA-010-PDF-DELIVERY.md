# CSA-010: Protected PDF delivery decision

Date: 2026-10-11
Status: APPROVED strategy - owner accepted and authorized merge on 2026-10-11
Requirements: FR-PDF-001..015, FR-PDF-SEC-001..010; AT-009/010;
ARCHITECTURE sections 34..37/40/41/53; API content descriptor/PDF contracts.

## Approved decision

Use authenticated backend proxy delivery (`proxied_stream`) of a server-generated
personalized PDF derivative stored in private storage. Check current session,
account eligibility and a valid course grant on every descriptor, full-byte or
range request. Do not return a raw-original path or Storage signed download URL
to students. Keep the original and all derivatives private; student Storage
policies must not provide a bypass around the proxy. Staff authoring preview is
a separately scoped, audited operation, not an implicit purchased entitlement.

This selects architecture Option B, accepted by the owner on 2026-10-11. It is not an already
deployed proxy, a viewer package approval, or a claim of capture prevention.

## Why this strategy

| Alternative | Tradeoff | Disposition |
| --- | --- | --- |
| Signed URL to private personalized PDF | Simple direct/range delivery; bearer URL remains usable until expiry, even after current account/entitlement changes | Not default when next-request revocation is required |
| Authenticated proxy of personalized PDF | Current authorization on each request; costs backend bandwidth and needs verified range/renderer compatibility | Selected MVP strategy |
| Provider-rendered pages/tiles | Adds dependency/cost and may harm selectable text, accessibility and rendering quality | Defer unless measured constraints require it |

Primary sources checked on 2026-10-11:

- [Supabase bucket access](https://supabase.com/docs/guides/storage/buckets/fundamentals)
  documents private downloads through authenticated access or time-limited URLs.
- [Supabase serving assets](https://supabase.com/docs/guides/storage/serving/downloads)
  states signed URLs use a separate key and remain valid until expiry despite
  Auth signing-key changes. Revocation must not rely on logout/key rotation.
- [Edge Function limits](https://supabase.com/docs/guides/functions/limits) must
  be checked against representative PDF workloads before choosing the runtime.
- [pdfrx](https://pub.dev/packages/pdfrx) remains a candidate. Dependency version,
  licensing, authenticated web fetching, range behavior and accessibility require
  implementation evaluation; no manifest changes are made here.

## Request and data boundary

1. Client requests a descriptor by lesson ID through its authenticated session.
2. Backend resolves lesson -> course -> private asset version itself and checks
   current actor, entitlement and resource availability. Ignore client paths,
   course substitutions, derivative IDs and supplied watermark identity.
3. Resolve or enqueue a validated per-user/per-asset derivative. Until ready,
   return a typed preparing state; never fall back to delivering the original.
4. Descriptor returns lesson identity, `mode=proxied_stream`, an opaque internal
   resource identifier and preparation/expiry behavior. Tokens never appear in
   query strings or logs. The fetch path requires Authorization on every request;
   an opaque ID is an identifier, not a bearer permission.
5. Proxy rechecks authorization, resolves the private derivative, and returns
   bytes with `application/pdf`, private/no-store cache policy and nosniff.
   Do not redirect to a signed storage URL. Separate preflight handling must not
   disclose content; permit only configured frontend origins and necessary headers.
6. Validate supported single ranges and return correct 206/Content-Range/length,
   or 416 for invalid ranges. Resolve ranges only after authorization. Reject
   abusive/multi-range requests unless explicitly implemented. Authenticate HEAD
   and conditional requests as well; validators cannot bypass access checks.

All ranges in a session must refer to one immutable derivative version and byte
length. Asset replacement creates a new version; it must not mutate in-flight
range content. Expired sessions refresh through normal authentication and request
authorization again. Never put service-role credentials in Flutter.

The exact typed descriptor, preparing-state error/status and request method must
be aligned with API_CONTRACTS.MD before dependent frontend/backend implementation.
Do not silently reinterpret its illustrative signed_url example as a real API.

## Watermark and document safety

Approved watermark: visible "Licensed to <display name> - <opaque license ID>"
on every page, bound to trusted actor/asset version. Avoid email, phone, NIC or
bank information. Explain the watermark and purpose before first reading.
The license identifier must not expose authentication credentials and may be
resolved only by authorized staff. Watermark format/retention need privacy review.

Apply the watermark server-side into the derivative bytes, preserving text,
images, page size and selectable content. A UI overlay may supplement it but is
not permanent document marking. Check low-contrast, dense, scanned, rotated and
multi-size pages; keep watermark visible without hiding lesson content.
Unsafe/unparseable/encrypted/oversized documents fail closed with a safe error.
Never strip accessibility structure or rasterize everything by default.

Derivative cache identity includes actor/license, immutable asset digest/version
and watermark policy version. Cross-user reuse is prohibited. Private cache
existence never proves authorization. Queue work is bounded and authenticated;
recheck actor eligibility before serving output. Generation retry is idempotent.

## Revocation, cache and runtime limits

Lifetime course access still requires a valid current grant and eligible account.
Refund/revocation denies the next proxy request when recomputed access has no
eligible surviving grant or an applicable restriction blocks it. A valid independent
source still authorizes reading after another source is refunded. Already received
bytes, renderer memory and an authorized in-flight response cannot be recalled.
No claim is made that a browser cannot save, screenshot or extract the document.
Proxy authorization does not make a full-file response retroactively revocable.

Exclude private PDFs/derivatives from service-worker offline caches, shared CDN
caches, localStorage and IndexedDB. Clear owned reader buffers on logout and
dispose resources. Memory controls are a usability measure, not DRM. Store only
user-owned progress, not document bytes. Logs contain actor/resource/action/result
and request correlation, never access tokens, private paths or full document bytes.

Use Supabase Edge Functions for lightweight authorization only if measured
resource/streaming limits fit. PDF transformation belongs in a bounded trusted
worker approved within the existing backend, not assumed to fit an Edge request.
Select its library/runtime/hosting after compatibility, cost and workload tests;
do not add microservices or new dependencies without the required coordination.
If no viable runtime is proven, the strategy remains selected but
dependent delivery implementation is blocked rather than silently relaxed.

## Acceptance gates

| Gate | Required evidence |
| --- | --- |
| Authorization | Anonymous/cross-user/wrong-course/expired/revoked/suspended direct descriptor, GET, HEAD and range requests return no protected bytes |
| Original bypass | Original/derivative public URLs and student direct Storage download/sign attempts denied |
| Watermark | User A/B derivatives carry only their own identity; actual returned bytes include the mark on every tested page |
| Revocation | New request denied when no eligible grant survives or a restriction blocks access; refund source A with valid source B still authorizes PDF access; delivered/in-flight byte limitation documented |
| Range/renewal | Correct 200/206/416, immutable versions, session expiry/refresh, network retry and preparing states work in selected viewer |
| Quality | Page/zoom/fit/scroll/expanded view/progress work at 390/768/1440 plus intermediate widths and both themes |
| Accessibility | Keyboard/focus/control names, selectable content and accessible alternative process assessed; no blanket screenshot/key blocking |
| Privacy/cache | No token/path leaks, shared cache or persistent offline bytes; cross-user cache poisoning denied |
| Reliability | Representative maximum files, page counts, concurrency, memory/time/egress and queue load measured; failures never deliver original |

Document size/page count, runtime, generation latency targets, retention and
accessible accommodation procedure remain explicit acceptance inputs. Tests above
are specifications, not execution evidence. Owner approval selects the strategy;
implementation validation must still prove it meets these gates.
