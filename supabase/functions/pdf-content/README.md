# CSA-141 controlled PDF delivery

`index.ts` remains disabled by default until CSA-139 private storage, trusted watermark worker/orchestration, authorization migration and runtime/release review are integrated. No deployed service or operational readiness is claimed.

The handler takes an injected CSA-140 authorizer and private Storage adapter. GET/HEAD query accepts lesson_id and optional resource_id; descriptors expose no bucket/path. All byte requests, HEAD, conditional and invalid-range requests authorize before revealing resource metadata. Only ready personalized derivatives can stream. The endpoint never signs URLs, redirects or falls back to originals.

Single ranges support inclusive bounds, open ends and suffixes. Malformed, multiple and unsatisfiable ranges return 416 after authorization. Responses are private/no-store and nosniff. Origin access is explicitly configured using comma-separated PDF_ALLOWED_ORIGINS. Preflights require an allowed Origin, GET/HEAD method and only authorization/range request headers. HEAD does not download the object. Conditional request headers do not produce 304 or bypass authorization.

Storage opens authenticated objects with server-only credentials, refuses redirects, rejects configured URL credentials, constrains the course-pdfs derivative path, applies a 15-second abort deadline, and requests identity encoding. The handler validates status, MIME, encoding, exact length and range metadata before returning a body. A demand-driven stream errors on truncated or surplus data and forwards cancellation. Errors expose stable public codes only.

Verification: `node --test supabase/functions/pdf-content/*.test.mjs` (38 tests). Includes real ReadableStream contents, backpressure, cancellation, short/surplus failures, range and HEAD behavior, access denial, CORS and private storage request shape. Live Storage/Deno deployment verification remains gated.
# CSA-271 activation and descriptor follow-up

Delivery remains **disabled by default**. The entry point requires the exact
server setting `PDF_DELIVERY_ENABLED=true`; unset/false/malformed values return
503. This change makes the approved release opt-in configurable; it does not
activate any hosted function or worker. Never set it merely to make a preview
work. Keep it false until the approved private bucket, bounded non-root Linux
worker/queue, licensed locale font, isolation, retention purge and representative
reader/accessibility checks in CSA-010 / CSA-140/141/148 have been accepted.
Worker activation still separately requires `PDF_WORKER_ENABLED=true`.
Turning delivery off again denies subsequent requests; previously delivered
bytes cannot be recalled from an authorized browser.

Authenticated descriptors now include `watermark_applied`: true only for a ready
server-generated derivative, false while preparing. Clients may show the
personal watermark disclosure only after this evidence **and successful byte
delivery**. Older descriptors remain readable without making the disclosure.
Every resource GET/HEAD/range still rechecks authorization; the flag does not
grant access and is not a capture-prevention guarantee. Only private derivative
paths reach Storage. No original or signed-URL fallback is introduced.

The new immutable v2 policy (`14000000-0000-4000-8000-000000000002`) adds the
owner's "Acendra Product" branding to the approved display-name/opaque-license
mark. Migration `20261021000100_csa271_pdf_policy_v2.sql` reserves fresh v2
derivatives and refuses v1 resource reuse; it never rewrites existing objects.
The worker takes its policy from the trusted derivative path, supports v1/v2,
and refuses unknown policies. Before applying the migration in an approved
environment, stop old workers and install this policy-aware worker. Restart
only after the normal runtime/release gates; do not mix an old worker with v2
reservations. No hosted migration was applied by this change.

For v2, the worker preserves inspected internal GoTo chapter outlines and named
destinations. External/scripted/chained actions remain rejected. Existing
immutable derivatives are not rewritten by this patch. The v2 resolver prepares
new branded derivatives instead of silently relabelling v1 objects. Old objects
remain subject to the approved retention purge.
