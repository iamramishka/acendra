# CSA-141 controlled PDF delivery

`index.ts` remains hard disabled until CSA-139 private storage, trusted watermark worker/orchestration, authorization migration and runtime/release review are integrated. No deployed service or operational readiness is claimed.

The handler takes an injected CSA-140 authorizer and private Storage adapter. GET/HEAD query accepts lesson_id and optional resource_id; descriptors expose no bucket/path. All byte requests, HEAD, conditional and invalid-range requests authorize before revealing resource metadata. Only ready personalized derivatives can stream. The endpoint never signs URLs, redirects or falls back to originals.

Single ranges support inclusive bounds, open ends and suffixes. Malformed, multiple and unsatisfiable ranges return 416 after authorization. Responses are private/no-store and nosniff. Origin access is explicitly configured using comma-separated PDF_ALLOWED_ORIGINS. Preflights require an allowed Origin, GET/HEAD method and only authorization/range request headers. HEAD does not download the object. Conditional request headers do not produce 304 or bypass authorization.

Storage opens authenticated objects with server-only credentials, refuses redirects, rejects configured URL credentials, constrains the course-pdfs derivative path, applies a 15-second abort deadline, and requests identity encoding. The handler validates status, MIME, encoding, exact length and range metadata before returning a body. A demand-driven stream errors on truncated or surplus data and forwards cancellation. Errors expose stable public codes only.

Verification: `node --test supabase/functions/pdf-content/*.test.mjs` (38 tests). Includes real ReadableStream contents, backpressure, cancellation, short/surplus failures, range and HEAD behavior, access denial, CORS and private storage request shape. Live Storage/Deno deployment verification remains gated.
