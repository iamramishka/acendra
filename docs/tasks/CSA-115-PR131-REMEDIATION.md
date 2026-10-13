# PR131 receipt resubmission remediation

Owner CODEX, assigned by project owner in chat on 2026-10-13.
Issue https://github.com/iamramishka/acendra/issues/139; PR131 remains the handoff.
Branch codex/fix/csa-115-pr131-review.
Worktree C:/Users/ramis/Downloads/Acendra/pr131-review.
Status IN_REVIEW; approval authority project owner/maintainer.
Scope: checkout receipt form and browser picker, canonical bank_transfer screen,
compatibility export, regression tests. Temporary dependency ownership limited to
pubspec.yaml/lock declaring already locked web 1.1.1 as a direct dependency.
No router change: existing bank-transfer route renders the canonical screen.
Original CLAUDE commits retained; bounded collaboration explicitly authorized.

The mock success/upload path and native synthetic file were removed. Submission
is visibly unavailable and cannot trigger success or navigation. The approved
upload-bank-receipt backend remains disabled until inspection/release approval.
Real browser input reads bounded selected file bytes; cancel cleans up and returns
null, errors are sanitized, empty/unsupported/oversized files rejected. Picker
is injectable so widget tests exercise tap behavior rather than private state.
Selected bytes are discarded while upload is unavailable; no backend persistence
or payment/access grant is claimed. The existing routed screen uses this form;
checkout screen is a compatibility export. No receipt attachments requested by email.
The optional note field was removed until a real submission contract carries it.

RED: two regressions reproduced enabled unavailable submission and mock success.
Verification final results will be recorded before handoff. Full analyzer initially
found inherited dev missing learning/My Courses imports; PR134 merged during work,
so integration is refreshed rather than taking ownership of its routing changes.
Initial parallel verification exhausted Windows commit memory; retries serialized.
No deployment, backend enabling, production data changes or merge authorized.

Verified on the combined tree with dev after PR134/PR132 integration:
- RED: two tests failed against original mock upload implementation.
- GREEN: 26 focused form/bank-transfer tests passed.
- `flutter test --no-pub --concurrency=1`: all 359 tests passed.
- `flutter analyze --no-pub`: no issues.
- `dart format --output=none --set-exit-if-changed lib test`: 175 files, zero changes.
- `git diff --check`: passed.
- No database changes; upload persistence/payment/security release remains unavailable.

Browser adapter tests are retained at test/browser/receipt_file_picker.browser.dart
(run explicitly with flutter test --platform chrome). Local Chrome launched but
stalled at suite loading without a result; the run was stopped. Browser tests and
manual native file-dialog interaction are therefore NOT claimed as passed.
The release build result is recorded separately below when verified.
- `flutter build web --release --no-pub`: passed; Wasm dry run succeeded, build/web generated (400.6s).

Original PR is updated by fast-forward after verification, preserving CLAUDE's
implementation history. No merge into dev or deployment. Implementation edit
ownership is released at handoff; final status IN_REVIEW pending CI/maintainer.
