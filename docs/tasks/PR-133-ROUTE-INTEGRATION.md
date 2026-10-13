# PR133 finance route integration

Owner: CODEX; project owner requested "check that and fix issue" on 2026-10-14.
Issue: #143. Status: IN_REVIEW. Approval authority: project owner.
Branch: fix/csa-111-route-integration.
Worktree: C:/Users/ramis/Downloads/Acendra/pr133-route-integration.
Base: PR133 76c50a9 merged with dev 7689e5f, preserving both histories.

The finance route imported the legacy bank-transfer screen, so merging PR133's
admin screen alone would not change the visible review UI. Integrate the reviewed
screen through the existing `/admin/finance-review` route. Keep the synthetic
preview labelled and all financial decisions unavailable until trusted backend
activation is separately approved.

Temporary router ownership is restricted to the finance screen import/route.
Issue142's documented bank-transfer student route scope is separate; its worktree
and current router diff were checked. No other agent worktree or branch is edited.
No navigation URL, backend, database, dependency, or production configuration is
changed. Earlier PR140 failure-preservation behavior remains in its existing
screen and tests; this task does not remove that implementation.

Integration also preserves rejection input in the new admin dialog: its typed
callback reports whether a decision was recorded, and the dialog closes only
on success. Unavailable review keeps the reason and shows an inline error.
The width regression exposed submission-date overflow at 390 pixels; amount
and date text now wrap within the available card width.

Acceptance: the actual route renders the admin screen, unauthenticated users go
to login, and preview approval cannot change statuses or claim success. Check
390/768/1440 widths in light and dark themes. Record the regression, focused and
full checks before handing off. Update PR133 by non-force fast-forward only; no
merge or backend activation is authorized by this request.

Verification:
- RED: corrected-theme route test found no admin FinanceReviewScreen before the import change.
- RED: unavailable rejection test reproduced the discarded reason.
- RED: route-width tests reproduced 49-pixel date overflow at 390 in both themes.
- GREEN: 19 route/admin tests passed after the final changes.
- Earlier wider focused run passed all 3 legacy rejection regressions and other router checks; only the subsequently fixed mobile overflow tests failed in that run.
- Full `flutter analyze --no-pub`: no issues.
- `dart format --output=none --set-exit-if-changed lib test`: 174 files, 0 changes.
- `git diff --check`: passed.
- Full Flutter suite, release build and tooling verification are delegated to PR CI; no local full-suite/build success is claimed for this change.

Handoff: update existing PR133 by fast-forward, then wait for CI and maintainer review. No merge or financial activation performed. Finance-import ownership ends at this handoff; bank-transfer route ownership remains with issue142.
