# CSA-014 - Design system review

Date: 2026-10-11 (Asia/Colombo). Owner: CODEX design agent.
Status: IN_REVIEW; proposed document refinements await owner/design review.
Branch: `codex/docs/csa-014-phase0-review`. Integration base: `origin/dev`
at `e1cf11f`. UI inspection source: local committed revision `9355311`.
The documentation-only task commit was rebased onto the approved remote
baseline; local UI commits were not exported by that rebase.
Worktree: `C:/Users/ramis/.codex/worktrees/csa-014-phase0/acendra`.
PR: coordinator to supply after publication; no merge or approval claimed.

## Scope and authority

The project owner requested all six Phase 0 tasks in parallel. The coordinator
recorded CODEX preparation of CSA-014, including the suggested CLAUDE ownership
exception, in `docs/reviews/CSA-011-017-PARALLEL-BOARD.md` on the CSA-013 branch.
Only `DESIGN_SYSTEM.md` and this review are writable. The design system lock
is released for review when this commit is handed to the coordinator. Shared
Dart files, requirements, backlog, dependencies and the primary mutable UI
checkout were not modified.

Read: AGENTS.md, DESIGN_SYSTEM.md, relevant SRS responsive/accessibility,
payment/bank/PDF and UX requirements, Phase 0/2/6 plan sections, CSA-014 and
related foundation/QA task entries, the local coordination board, existing
theme/provider files, shared buttons/forms/dialogs/feedback/layout/admin and
learning shells, and representative existing theme/button tests. The
recommended `app_radius.dart` path does not exist: radii live in
`app_spacing.dart`. No separate scoped AGENTS.md was found in this worktree.

After fetching/rebasing, also reviewed approved SRS 1.1 and the merged
CSA-001/002 acceptance, CSA-003 role, CSA-005 bank, CSA-006 entitlement/refund
and CSA-010 PDF policy baseline. The requirements README's approval evidence
is authoritative for those accepted decisions. The accepted policy fixes
PayHere/LKR, one course/order, 5 MiB JPEG/PNG/PDF receipts, independent finance
review without self-approval, lifetime purchased access, seven-day reviewed
refund requests and authenticated server-watermarked PDF delivery. These are
now referenced by the design proposal, with their remaining gates preserved.

## Findings from committed source

These findings describe source inspection at the base revision, not verified
browser behavior or current uncommitted work in another checkout.

| Finding | Evidence | Impact and follow-up |
| --- | --- | --- |
| F-01: Palette and breakpoint foundations align | `lib/app/theme/app_colors.dart` matches all section 7/8 token values; `app_breakpoints.dart` uses 600/1024, max width 1280 and sidebar 248. | Preserve brand values. Half-open intervals and content constraints now remove ambiguity; runtime overflow still needs verification. |
| F-02: Typography differs from the document | `app_typography.dart`: bodyLarge 16/1.60, bodyMedium 14/1.57, bodySmall 12/1.50, labelLarge weight 500 with no explicit height. Section 10 table specifies Body Large 18/1.55, Body 16/1.50, Body Small 14/1.50, Label 600/1.40. | Proposed explicit Flutter style mapping retains the documented scale. Design owner must accept the scale or approve a documented alternative before a theme change; no code adjustment in this task. |
| F-03: Token coverage/locations differ | `app_spacing.dart` lacks named 12/20/40 spacing tokens; `AppRadius.chip` is 100 rather than section 12's pill 999. Card/button/dialog values match. | Assign a foundation reconciliation task; do not infer that numeric differences necessarily change the rendered pill shape. Recommended folders are guidance rather than an instruction to move files here. |
| F-04: Low-contrast boundary pairs | Token calculations below show light focusRing/white and both border/surface pairs below 3:1. `app_theme.dart` maps outline to border, while focused inputs use primary. | Decorative borders may remain subtle. A component that relies on these as its only visible boundary needs an independently tested contrasting boundary. Raw token failure does not prove every rendered component fails. |
| F-05: Password action lacks explicit naming | `AppPasswordField` uses a visibility `IconButton` without tooltip or supplied semantic label; `LearningShell` back icon likewise supplies no explicit label. `AppTextField.label` is optional. | Feature owners must provide visible field labels and action names, and verify resulting Flutter Web semantics. A component API alone cannot enforce every call site's label usage. |
| F-06: Busy and reduced-motion behavior is incomplete in source | `AppButton` replaces its text with a spinner during loading, without an explicit retained semantic label; `AppSkeleton` repeats its controller without consulting reduced-motion preferences. | Preserve a meaningful busy action name; add static loading presentation under reduced motion, then check announcements in the browser. |
| F-07: Medium admin layout uses a full sidebar | `AdminShell` collapses only below 600; at 600-1023 it retains the 248-wide sidebar. The proposed document recommends rail/collapse when space permits. | Evaluate actual content width at 600/768 and enlarged text. This is a layout risk, not a reproduced overflow; assign a shell task if acceptance fails. |
| F-08: Theme preference is in-memory | `ThemeModeNotifier` starts with system mode and does not persist selection. `ThemeToggleButton` determines dark state from the selected enum rather than effective system brightness. | Implement approved persistence separately; test toggling while system mode resolves dark, reload and system changes. Persistence remains SRS SHOULD, not a newly invented SRS MUST. |
| F-09: Learning/commerce/reader coverage is not established | Shared `LearningShell` exists but no feature implementation files were returned by `rg --files lib/features` at this base. Existing theme/button tests cover selected values and basic actions, not full AA/reader/checkout journeys. | Matrix rows are future implementation acceptance. Do not claim these workflows or browser accessibility have been validated. |

## Contrast calculation evidence

Computed in the isolated worktree using PowerShell from opaque sRGB hex pairs,
linearized channels and relative luminance; ratio = (higher luminance + 0.05)
/ (lower luminance + 0.05). Values are rounded for display, not threshold tests.

| Foreground / background | Ratio | Interpretation |
| --- | --- | --- |
| Light focusRing #F59E0B / surface #FFFFFF | 2.15:1 | Insufficient if used alone for a boundary requiring 3:1. |
| Light border #E0E6F0 / surface #FFFFFF | 1.25:1 | Decorative separation only unless supplemented. |
| Dark border #334158 / surface #151D30 | 1.63:1 | Decorative separation only unless supplemented. |
| Light primary #5146E5 / onPrimary #FFFFFF | 6.25:1 | This opaque normal-text pair exceeds 4.5:1. |
| Dark primary #A7A8FF / onPrimary #11152C | 8.30:1 | This opaque normal-text pair exceeds 4.5:1. |

This is a limited calculation, not an exhaustive palette/state audit. Opacity,
hover overlays, focus surroundings and disabled/loading states need rendered
checks. Standard reference verified on 2026-10-11:
[W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/).

## Proposal delivered

DESIGN_SYSTEM.md version 1.1 remains Proposed - Pending Approval. It preserves
the working Acedra brand and all existing palette/spacing/radius/typography
table values. It adds intended Flutter text-style mapping, unambiguous width
intervals, available-content behavior, visual button size versus hit-region
guidance, contrast pairing constraints, and the DS-AC-01 through 09 matrix.

The matrix covers light/dark, eight widths including breakpoint boundaries,
text/browser scaling, keyboard/focus, semantics, forms, busy/error/empty states,
reduced motion, financial uncertainty/concurrency, reading/media controls and
theme preference. SHOULD items remain deferred under the accepted MVP scope;
the matrix checks them if implemented and does not silently promote them.
It maps to SRS NFR-RESP/NFR-ACC/NFR-UX, FR-PAY/FR-BANK and
FR-PDF requirements. All runtime evidence remains pending. CSA-017 should use
these IDs as design checks within its acceptance strategy.

## Owner decisions and dependencies

| Decision | Accountable decision owner | Recommendation / dependency |
| --- | --- | --- |
| Accept intended text-style mapping versus current implementation | Project/design owner | Retain section 10 scale; foundation owner reconciles Dart styles after approval. |
| Accept DS-AC matrix and formal accessibility target | Project owner with accessibility reviewer | Adopt matrix; resolve DS-OPEN-009, then assess complete journeys before claiming AA. |
| Final identity, approved typography assets/licenses and imagery | Project/design owner | DS-OPEN-001/003/010/011 remain unresolved; GoogleFonts use alone does not prove production asset/license readiness. |
| Student/admin navigation and MVP component inventory | Project/design owner | Resolve DS-OPEN-004/005/012; choose collapse/rail behavior using content fit evidence. |
| Watermark appearance, controls and accessible content alternatives | Project owner, security owner and learning/content owner | Resolve DS-OPEN-006/007 with CSA-015 and PDF/provider evaluation; disclose watermarking and avoid false capture guarantees. |
| Supported language scope | Project owner | DS-OPEN-008 remains open; no multilingual feature was added. |

Remaining DS-OPEN-002 palette approval is retained despite source alignment.
No business policy or production design approval is inferred from this review.

## Verification and handoff

Executed: source/document inspection and five deterministic contrast pair
calculations. `git diff --check` and staged whitespace checks passed on the
initial proposal; self-review confirmed the changed scope and preserved tokens.
After rebase, the final diff and approved-policy references were reviewed and
whitespace checks rerun before committing; coordinator receives the commit.
Flutter analysis, widget/golden/integration tests, release build, screen reader,
keyboard and screenshots were not run: this task changes documentation only
and does not validate the UI. Existing tests were inspected, not reported as
passing. No database, payment provider or private student data was accessed.

Next owner: coordinator publishes review artifacts/PR and reconciles CSA-017
references. Project/design owner reviews proposals; future implementation
owners claim shared theme/widget scopes before addressing F-02 through F-08.
Task stays IN_REVIEW until review/approval and integration requirements are met.
