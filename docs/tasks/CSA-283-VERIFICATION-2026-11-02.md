# CSA-283 / COM-018 verification follow-up — 2026-11-02

Owner: CODEX. Status: IN_REVIEW. Existing task: issue #234; original PR #235
is merged. The owner requested fresh protected-video verification, comparison
with the original artifact and acendra.vercel.app, resolution of the preview
failure, and authorized dummy video. This is the local assignment for the
explicit follow-up, not a new GitHub claim.

Branch: fix/csa-283-video-verification.
Worktree: C:/Users/ramis/.codex/worktrees/csa283-video-verification/acendra.
Base: origin/dev 6d0e8c9. The original shared checkout remains untouched.

Allowed scope: video-player feature and corresponding tests, existing synthetic
COM-018 fixtures/tooling, and this task-specific evidence record. Inspect Vercel
deployment/integration state read-only. No backend readiness activation, Mux
purchase/upload, enrollment/role mutation, global theme/router, manifests,
database changes or production deployment. PR255 owns vendor checkout integrity;
its source is excluded. PR252 owns completion/overview repair; excluded here.

Dependencies: merged PR235, approved ADR-010, existing signed lease contract and
test-only HLS fixtures. Open issues/PRs/worktrees checked before implementation.
No overlapping active web-player owner found. Final approval authority: project
owner/designated independent reviewer. Required evidence: focused RED/GREEN for
confirmed defects, actual synthetic HLS playback/captions/speed, retry and denial
after revocation, responsive layout checks, analyzer and scoped diff review.
Hosted signing/long playback/privacy acceptance must remain separately stated.

Plan: compare the artifact; diagnose the recorded provider failure; exercise the
current player and lease lifecycle; repair confirmed in-scope defects; verify and
record exact evidence and remaining provider dependencies.

The owner's artifact-alignment request also assigns bounded presentation changes
to learning_workspace_screen.dart and video_lesson_panel.dart, plus a new
com018_video_layout_test.dart. Scope: player-before-metadata ordering, video title,
rounded player and a labeled progress card. Existing text/PDF/image layout,
completion logic, overview files (PR252), routing and backend remain excluded.

## Findings and implementation

1. Confirmed renewal defect: the web player passed the original saved timestamp
   into each replacement surface. Retain the last reported playback position for
   Retry and same-account token changes. A different account/lesson resets the
   transient position; each replacement still obtains fresh authorization. The
   existing early expiry stop/manual Retry policy is retained; this change does
   not implement or certify uninterrupted automatic four-minute renewal.
2. Confirmed artifact layout gap: metadata appeared above the player. For video
   only, move it below the rounded 16:10 player, show the actual lesson title and
   a labeled Course Progress card, then Overview/Resources. The same scrollable
   panel keeps large-text content reachable and the completion footer fixed.
   Text/image/PDF presentation and completion-save behavior are unchanged.

## Fresh comparison

Opened the original artifact at
https://claude.ai/artifact/NDAfFDE3QHzxMNTRXqf4RJ, used its demo Sign In and Resume
Learning, and inspected the actual video screen. It shows a rounded player,
seek, speed and CC, lesson number/title/type/status, Course Progress,
Overview/Resources and sticky Previous/Mark Complete & Continue. This is fresh
interactive observation, superseding the original task's unavailable-artifact
limitation. No prototype payment/access logic was copied. Existing same-module
PDF association remains the owner's approved interpretation of Resources;
lesson descriptions/learning objectives are not fabricated from demo text.

Opened https://acendra.vercel.app in the task browser. It renders Sign In and
requires an authenticated enrolled test session for a protected lesson. Public
index registration and video_player_runtime.js both exist (HTTP 200, JavaScript
MIME type, Mux runtime present). Current alias deployment
dpl_CvtC13bMqWoFq5Mf27bwf8dLGgW9 is READY, source CLI. This proves the renderer is
served, not successful hosted signed playback or deployment of this repair.

## Recorded Vercel preview failure

Read-only authenticated CLI/API inspection of PR235's exact failed deployment
dpl_2Kuw8agsEzEexmJjDzD1jwzVXtyC, source Git commit
7fe1eb5934a05fda899b395dbde32bdf11821efd:

- readyState ERROR; errorCode BUILD_FAILED; errorMessage "Resource provisioning
  failed"; integrations.status "error".
- No build events/logs returned, and the full deployment API reports no builds.
  Failure precedes application compilation. This is not evidence of a Dart,
  Mux import or video-player source build failure.
- Installed marketplace configurations include Supabase, Prisma and Neon.
  The public integration-resource read endpoint rejects the account token with
  HTTP 403: "Only integrations can query resources". The available evidence does
  not identify which resource/action failed; do not guess or disconnect one.
- The dashboard in the task browser requires Vercel sign-in. Native-browser
  fallback was unavailable. No integration, secret, plan, alias, deployment or
  readiness setting was changed, and the failed check was not masked.

Preview resolution remains blocked on an authorized Vercel dashboard/operator
identifying the failed provisioning resource/action, repairing that integration
within the existing plan, then retrying the preview. Retain the exact deployment
ID and error above for provider support. A successful CLI-hosted alias does not
clear this separate Git-preview failure. Do not add a speculative Flutter build
configuration to address a failure that occurs before the build starts.

## Fresh verification

- Layout RED: the new 390px regression failed before the presentation change:
  player bottom 327.75 was not above metadata top 16.0. GREEN: 98 focused native
  checks passed, including all 16 new combinations of 320/390/768/1440 widths,
  light/dark themes and normal/doubled text. Tests require player-before-metadata,
  accurate progress labels, reachable Resources and an unobstructed enabled
  completion footer.
- Renewal RED: isolated browser regression fails on the origin/dev web player
  (exit 1); the same regression passes with the repair. Six web lifecycle tests
  pass, covering expiry/Retry, position retention, token refresh, account
  isolation, sign-out, late authorization and denied renewal after a 403.
- Actual synthetic HLS in the task browser: caption and no-caption media both
  play and seek, 1.5x rate is applied, captioned media exposes a real English
  WebVTT cue and captions can be disabled. Both media controls measure 48x48.
  Renderer tracking/cookie-disable attributes are present. These checks use the
  existing 12-second original dummy fixture, not paid/provider uploads.
- Full formatting: 421 files checked, zero changes. Analyzer: no issues.
- Unfiltered runtime/authorization run: 21 pass, one known Windows vendor-hash
  failure (actual a1441402..., expected 8c20096c...). PR255/CSA-288 owns that
  separate checkout defect. Re-running the remaining 21 tests with that named
  integrity case explicitly excluded passes. No hashes/vendor bytes are edited.
- Windows Flutter browser checks use temporary root test forwarders and a
  junction to installed CanvasKit, working around the documented SDK path bugs.
  Temporary Dart forwarders are removed after execution; no SDK source changes.
  Preliminary broad checks were interrupted before layout source changes and
  during resource contention; they are not claimed as completed checks.

Remaining final checks and PR handoff are recorded below. Hosted Mux signing,
30-minute playback, four-minute seamless renewal, real entitlement revocation,
privacy/network acceptance and the failed Vercel preview remain unverified.
The authorize-video entry is still deliberately gated (503 by default). Dummy
media authorization does not waive that approved activation gate. Already
delivered/buffered media cannot be recalled by revoking a new authorization.

Additional final browser evidence: all four workspace cases pass after the
layout change (same-module protected PDF route/access recheck, mobile footer,
save-before-advance and failed-save retention). The six authorization cases also
passed in the multi-selector run; the Windows harness then stalled advancing to
another selector and that owned run was stopped. Re-running the workspace suite
alone completed successfully. The two actual HLS cases were independently run
in the task browser using the production renderer. No combined multi-selector
success is claimed. Local diagnostic server and temporary forwarders are not
part of the application or a deployed preview.
