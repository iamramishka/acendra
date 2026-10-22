# CSA-270 / COM-008 browser verification follow-up

Owner: CODEX. Status: IN_REVIEW. Date: 2026-10-22.
Authority: project owner requested COM-008 continuation in this chat.
Implementation issue: #203. Implementation PR: #204.
Verified input: e42ff5ee724ad4b264c6deee24c26377df22f19e.
Branch: test/csa-270-browser-verification.
Worktree: C:/Users/ramis/.codex/worktrees/com008-verification/acendra.

The existing implementation and its original worktree remain untouched.
This isolated follow-up owns only this record and new screenshots under
docs/reviews/CSA-270. Existing production code is inspected and tested as-is.
No duplicate implementation claim, shared-file lock or backend change.
Dependencies: existing catalog preview and approved category/course contracts.
Approval authority: project owner/designated reviewer; repository CI gates retained.

Acceptance: confirm category and description rendering; lazy SliverGrid;
responsive light/dark layouts; category/search/sort/detail navigation; compare
the running offline preview with the reference artifact. Synthetic fixture data
must remain clearly identified and must not create orders or entitlements.

## Fresh results

- Locked dependency restore passed with no tracked dependency changes.
- `flutter test --no-pub --concurrency=1 test/features/marketplace/catalog_browser_test.dart test/features/marketplace/catalog_sliver_test.dart`: exit 0, all 19 passed. Covers 320/390/768/1440 widths, light/dark, 100%/200% text, metadata, filtering, search recovery, sorting, detail navigation, offline checkout refusal, lazy scrolling through 100 courses and container-based columns. These are widget-runner results, not automated Chrome results.
- `flutter build web --release --no-pub --no-web-resources-cdn --no-wasm-dry-run --target tool/catalog_preview.dart --output build/catalog-qa`: exit 0, 238.7 seconds. Existing CupertinoIcons font-family warning remains. This build is the labeled offline QA entry point, not a production deployment.
- Actual browser preview at loopback port 8734, 390x1000: category dot/label, title, description, formatted price and chevron are visible beneath the cover. Design filtering yields two courses. Low-to-high sorting starts with Project Planning Basics at LKR 4,500.00; high-to-low starts with Flutter Development Essentials at LKR 12,500.00. Unmatched search yields 0 Courses and the distinct no-match message.
- Reference artifact opened successfully and its Explore card inspected directly. Both show cover, category, title, description, price and chevron. Exact visual parity is not claimed: preview uses honest missing-cover fallback, existing typography and extra card spacing; prototype uses illustrative artwork and more compact cards. Existing Newest sort is retained because no popularity contract exists.
- Browser access was then disabled in Work settings. Further interactive checks (search recovery, course navigation, dark/tablet/desktop screenshots) could not continue. Their widget assertions passed, but interactive verification remains incomplete. No setting was changed to bypass this restriction.

## Screenshots

- [390px light catalog](../reviews/CSA-270/390-light.jpg)
- [Observed prototype card](../reviews/CSA-270/prototype-card.jpg)

## Handoff

The requested production changes already exist in PR #204 at the verified input.
This follow-up adds evidence only. Required approving review and CI remain open;
GitHub currently reports the PR BLOCKED and REVIEW_REQUIRED. The original task
records an Actions billing/spending restriction. No merge, deployment, hosted
data changes or completed automated Chrome run is claimed.

Next action: finish interactive acceptance when browser access is restored,
obtain passing current-head CI and required review, then integrate PR #204.

Final follow-up: full flutter analyze --no-pub remained stalled without diagnostics and was explicitly stopped; no fresh full-analysis pass is claimed. The original PR analysis pass is historical evidence. No production/test source changed during this verification follow-up.
