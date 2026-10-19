# PR #197 draft-preview review repair

Date: 2026-10-19 (Asia/Colombo). Owner CODEX; status IN_REVIEW.
Authority: project owner requested parallel reviews, fixes and merge into dev.
Branch/worktree: existing `fix/csa-267-recover-integration`, `csa267-recovery`.
Temporary scope: admin artwork repository/provider/cards, artwork binary response
negotiation and regression tests; no publication, payment or role policy changes.

Finding: admin draft cards used bare Image.network with no session, while the
resolver correctly denies anonymous draft requests. The upload's local preview
worked only until navigation. Also, the pinned Functions client decodes image/*
as UTF-8 rather than binary. Adding Image.network headers does not supply a
reliable Flutter Web authenticated transport.

Fix: fetch drafts through the Functions SDK with explicit current Bearer and
Accept: application/octet-stream. The server negotiates binary only after
verified authentication; public requests retain image MIME and existing private
resolver authorization. Draft cards render returned memory bytes, remove them
on logout/reload, and discard in-flight account changes. Upload completion
invalidates the draft provider. No token enters a URL or public model.

RED: binary-negotiation regression failed before the server change.
GREEN: 13 artwork handler tests and 14 Flutter repository/widget/upload tests
passed, including authenticated fetch, changed-account denial, malformed response,
logout removal, target changes and responsive light/dark upload controls.
Analyzer initially reported one const lint in the new test; corrected it.
Fresh analysis/format and proportionate integration checks precede publication.

Final focused checks: 36 Flutter tests passed, including the existing admin
course/lesson publishing journey; 41 media Node checks passed; analyzer clean
(12.0 seconds); all 308 Dart files format cleanly and diff checks pass. Release
web compilation is the last pending local check. No SQL changed in this follow-up.
Earlier 835-test/native-SQL/build evidence describes the pre-preview head and
is not claimed as a rerun for this change. Live scanner/Storage acceptance and
required CI/approval still remain. Parallel agents stopped on account usage limits;
their preliminary review is not a completed independent approval.
