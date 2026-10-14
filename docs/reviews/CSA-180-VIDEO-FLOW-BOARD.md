# Authorized video frontend continuation

2026-10-15. CODEX backend_acceptance delegate, issue129 continuation.
Branch feat/csa-180-authorized-video, managed isolated phase8-video-flow/acendra;
base origin/dev 7127d44. Scope video_player feature/tests and this record.
Root integrates learning entry point; no learning/backend/dependency edits.
Contract CSA-136-VIDEO: authenticated lesson_id-only request, exact signed Mux
URL, expiry bound300s. Outcome safe pending/unavailable states and identity-bound
controller disposal, no token disclosure. No automatic renewal promise: real
Mux renewal PoC remains required before endpoint activation. Index stays disabled.
Required hosted format/analyze/tests/build; no local tests. Status IN_REVIEW.

Root API: import presentation/widgets/authorized_video_widget.dart and render
`AuthorizedVideoWidget(lessonId: selectedLesson.id, title: selectedLesson.title)`.
No caller URL/provider/roles accepted. Its repository invokes authorize-video with
lesson_id only, accepts exact HTTPS stream.mux.com alphanumeric m3u8 with one JWT
token query, matching lesson and unexpired expiry at most300seconds. SDK errors
are mapped to safe sign-in/denial/unavailable text with no public fallback.
The player owns its controller per lesson/session; opaque generation keys expose
no bearer token. Session/lesson switch disposes prior lease/controller; late result
is discarded. Timer stops and disposes playback one second before expiry; explicit
Request video access retries authorization without promising seamless renewal.
Player errors never render provider errorDescription or signed URL.

New repository tests cover contract, unsafe URLs, expiry and sanitized 401/403/503.
Widget tests cover gated503 retry and pending authorization after account switch
or logout. No tests/analyzer/build ran locally; formatter and diff-check passed.
Real Mux asset privacy/signing setup and uninterrupted short-cap renewal PoC remain
release requirements; no deployed handler is enabled by this frontend change.
