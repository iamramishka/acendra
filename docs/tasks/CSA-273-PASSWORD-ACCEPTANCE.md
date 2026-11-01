# CSA-273 password-flow test follow-up

Date: 2026-11-01 (Asia/Colombo). Owner: CODEX. Status: IN_REVIEW.
Authority: owner requested fixing and testing recovery email, reset link,
expired link and signed-in password change. Existing issue: #208.
Branch: `fix/csa-273-password-flow-tests`.
Worktree: `C:/Users/ramis/.codex/worktrees/password-flow-tests/acendra`.
Base: current `origin/dev`; prior #210 is merged. Existing CODEX ownership
continues; original worktrees and Claude password branch remain untouched.
Open issues/PRs and worktrees checked: no open password implementation PR.

Scope: authentication reset screen, focused password-flow and repository tests,
this evidence record. No shared router/theme, dependencies, hosted settings or
other feature edits. Dependencies: merged recovery/session-safety implementation,
existing Supabase client and approved six-character policy. Approval authority:
project owner. No deployment or real-account password mutation.

Acceptance: recovery request uses the reset route and PKCE; valid recovery link
establishes a recovery session; expired/rejected links cannot update a password
and offer a new-link path; signed-in change preserves the session; recovery
completion signs out. Verify at the real SDK/HTTP boundary with synthetic data,
plus existing form/Settings regressions, analyzer, formatting and release build.
Local HTTP responses do not certify hosted email delivery or production Auth.

## Implementation and verification

Added a recovery-only `Request a new reset link` action using the existing
forgot-password route. It is disabled while an update is pending. Signed-in
change mode retains its existing Settings destination and session behavior.
The expiry test first failed because the new action was absent, then passed
after the eight-line screen change.

Added five tests with the real Supabase client and a loopback HTTP server:
reset-route redirect and PKCE request; valid recovery-code exchange/update/
sign-out; expired-code rejection without a session or password HTTP request;
signed-in update preserving the session; and rejected email-request failure.
Only Auth's HTTP service and PKCE storage are test doubles. Existing widget
tests exercise recovery sign-out, Settings entry/return, stale session results,
neutral email confirmation, validation and responsive light/dark layouts.

Initial combined authentication/Settings run reached 98 passing tests before
the Settings test process exhausted Windows memory. Concurrent analyzer also
failed to start a DartWorker thread. Neither invocation is recorded as a pass.
Subsequent validation is serialized. All five SDK tests and the extended
expiry-navigation regression passed during the initial combined invocation.

Full source/test formatting: 421 files clean, exit 0. Dependency restore passed;
no lockfile changes. Diff whitespace check passed. Final checks follow below.

- `flutter build web --release --no-pub`: passed, exit 0 (289.6s), including
  Wasm dry run. Existing missing Cupertino font warning remains.
- Serialized `flutter analyze --no-pub`: no issues, exit 0 (44.9s).
- Serialized `flutter test --no-pub --concurrency=1
  test/features/authentication test/features/settings --reporter expanded`:
  **105 passed**, exit 0 (1m42s), including all five HTTP tests and the extended
  expired-session navigation check. Existing 320/390/768/1440 light/dark form
  cases pass with the added action. No full-repository or browser-suite pass
  is inferred from this affected-module run.
- An initial HTTP test assumed a browser URI origin on the VM's `file:` base.
  Its assertion now compares scheme/host and reset fragment, retaining the
  redirect check on both schemes; the corrected five-test HTTP suite passed.

References checked: SRS FR-AUTH-006/007 and FR-PROFILE-003, SECURITY.md password
recovery/privacy rules, existing route/provider contracts and installed SDK
implementation. Supabase's [resend guidance](https://supabase.com/docs/reference/dart/auth-resend)
identifies `resetPasswordForEmail` as the way to request another recovery email.

Hosted inbox delivery, configured redirect allowlists, browser callback handling
and real account changes remain live acceptance checks. No live account,
service configuration, database, deployment or password was changed.

Source changes are ready for review. Required hosted checks, maintainer review
and live Auth acceptance remain separate gates; the task is not marked DONE.
