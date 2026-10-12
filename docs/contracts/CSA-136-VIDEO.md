# CSA-136 video authorization contract

POST authorize-video accepts exactly `{ "lesson_id": "uuid" }` with a Supabase Bearer token and JSON content type. It verifies that exact token at Auth, matches subject/session/AAL, rejects anonymous users, then calls the service-only csa136_authorize_video RPC. No caller user/course/provider/playback/expiry fields are accepted.

The RPC checks live account/session, published video lesson/section/course, current source-backed entitlement, validated undeleted Mux media association and a private signed playback binding matching the media asset ID. Bindings have no application grants or ingestion API. Trusted provisioning must first query Mux with server credentials, verify asset ownership, playback membership, signed policy and absence of every public playback ID, and retain a SHA256 digest of that provider response. An assertion from a client is insufficient. This work does not implement that provisioning workflow.

Success returns data containing lesson_id, expires_at (Unix seconds), playback_url. URL is https://stream.mux.com/{signed-playback-id}.m3u8?token={JWT}. RS256 JWT claims are sub=playback ID, aud=v, kid=signing key ID, exp=expiry. Secrets use MUX_SIGNING_KEY_ID and PKCS8 MUX_SIGNING_PRIVATE_KEY_PEM on server only. No PII is included.

Expiry is the minimum of 300 seconds, verified Auth token expiration, live session not_after and the latest expiration of an eligible entitlement source (unlimited sources retain the other bounds). Responses are no-store. Revocation denies new authorizations; an already issued bearer URL may remain usable until expiration. Signed delivery cannot prevent capture or sharing.

Deployed index.ts is hard disabled and returns 503 VIDEO_UNAVAILABLE regardless of environment flags. The injected enabled=true seam is for tests only. Release requires provisioned signing keys, private Mux assets without public IDs, real privacy/expiry/revocation evidence and player renewal PoC. Mux documents expiry longer than video duration for uninterrupted playback: the tighter project cap needs tested renewal before enablement.

Source: [Mux secure video playback](https://www.mux.com/docs/guides/secure-video-playback), [Mux signing keys](https://www.mux.com/docs/api-reference/video/url-signing-keys).
`nWeb origins use ACENDRA_VIDEO_ALLOWED_ORIGINS (comma separated exact origins, default http://127.0.0.1:8080). Enabled test seam provides POST-only bounded preflight; foreign origins are denied before Auth.
