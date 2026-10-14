# PR133 finance route integration

Owner: CODEX; project owner requested "check that and fix issue" on 2026-10-14.
Issue: #143. Status: DONE (bounded route remediation). Approval authority: project owner.
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
390/768/1440 widths in light and dark themes. The original fix request authorized
a non-force fast-forward to PR133; the owner subsequently explicitly authorized
review and merge if no actionable findings remained. Backend activation was not
authorized.

Verification:
- RED: corrected-theme route test found no admin FinanceReviewScreen before the import change.
- RED: unavailable rejection test reproduced the discarded reason.
- RED: route-width tests reproduced 49-pixel date overflow at 390 in both themes.
- GREEN: 19 route/admin tests passed after the final changes.
- Earlier wider focused run passed all 3 legacy rejection regressions and other router checks; only the subsequently fixed mobile overflow tests failed in that run.
- Full `flutter analyze --no-pub`: no issues.
- `dart format --output=none --set-exit-if-changed lib test`: 174 files, 0 changes.
- `git diff --check`: passed.
- Current-head [PR CI](https://github.com/iamramishka/acendra/actions/runs/38450292656) passed full formatting, analysis, Flutter tests with coverage, release web build and tooling checks at `f53afcf45f98a5f0405ecb417cd4022524e0ec63`. No local full-suite/build success is claimed for this change.

## Merge and post-merge verification — 2026-10-14

[PR #133](https://github.com/iamramishka/acendra/pull/133) merged into `dev` at
`31630ddd00378f7695e9eae17417bfeaccebaede`. The owner requested review and merge
if no findings remained. CODEX self-review found no new actionable findings;
this is not independent human code review. Merge used an exact head-commit
guard at `f53afcf` without an administrator bypass. Original CLAUDE and CODEX
history was retained.

[Post-merge CI](https://github.com/iamramishka/acendra/actions/runs/38509792565)
completed successfully on the exact merge commit: formatting, full analysis,
Flutter tests with coverage, release web build and tooling regression checks.
The finance route now imports the admin screen. Bounded issue143 remediation
is complete and temporary finance-import ownership is released; issue142's
separate bank-transfer scope was not changed by this remediation.

CSA-111's operational acceptance remains IN_REVIEW. The UI uses clearly
labelled synthetic receipts; approval/rejection cannot record financial
decisions or grant access, and receipt viewing remains unavailable. Trusted
backend activation, real data and operational finance-role authorization are
separate gates. No production deployment or backend activation was performed.

Documentation reconciliation owner: CODEX. Branch `docs/csa-111-merge-evidence`,
isolated worktree `C:/Users/ramis/Downloads/Acendra/pr133-docs`; scope limited to
this record and TASKS.md's CSA-111 entry. Requested by the project owner on
2026-10-14; verified against GitHub merge metadata and final CI result.
