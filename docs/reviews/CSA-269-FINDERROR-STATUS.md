# finderror status reconciliation — 2026-10-20

Owner CODEX; coordination CSA269 / GitHub #200. This records source inspection
against published dev `d46ae1c` and live GitHub issue/PR evidence. It does not
certify a deployed environment or alter the retained historical bug report.

## All original findings

| Findings | Current source | Remaining acceptance |
| --- | --- | --- |
| 001 | Student Home replaces the empty route; personal enrollment/progress section exists. | Featured courses/categories remain explicitly labeled offline sample content. Live Home discovery and hosted acceptance remain separate work. |
| 002 | Authenticated marketplace uses the shared student shell/session. | Hosted navigation/session acceptance. |
| 003 | Authorized directory counts and verified gross-receipts adapter replace fabricated statistics. | Enable reviewed reporting and reconcile actual settlement minor units. Refund/net remain unavailable by owner decision, not fabricated zeroes. |
| 004 | Real authorized list adapter merged through PR #194; it is no longer unconditionally unavailable in Flutter. | Deploy matching functions/migrations, configure independent server flags/origins and verify finance/MFA reads. |
| 005 | Application listing and detail requests exclude the known sandbox fixture. | Stored course archival is unexecuted in the cleanup record; verify actual environment state before applying the reviewed runbook. |
| 006, 025 | Current-role Admin navigation is available in the account menu. These are duplicate original observations. | Real eligible/ineligible-role acceptance. |
| 007 | Catalog cards render actual course titles. | Hosted visual regression acceptance. |
| 008 | Enrollment/order state selects checkout or learning; failures disable the CTA and expose retry. | Hosted purchase/learning acceptance remains distinct from client navigation. |
| 009, 010, 019 | Dedicated detail route, explicit catalog back control and header navigation exist. | Hosted browser history/direct-link acceptance. |
| 011, 012 | Admin lists and dashboard use the same authorized directory repositories with cursor paging. | Verify role-scoped visibility/counts with real signed-in accounts. |
| 013, 014 | Dashboard and Payments share an unfiltered atomic status-count snapshot; Processing is included. | Hosted list/count consistency after reporting activation, including refresh and account switch. |
| 015 | Fabricated default payment titles removed; real order identity/title snapshots are used. | Verify actual order references. Historical purchase snapshots need not equal subsequently renamed catalog titles. |
| 016 | View-all navigation callback exists and reporting availability is explicit. | Hosted queue/list navigation with activated reporting. |
| 017 | Cancel navigation exists. | Persistent course authoring is separate CSA268 / issue #199; Cancel alone never established save/delete/publication completion. |
| 018 | Finance role and AAL2 remain enforced; ineligible shortcut hidden. | Authorized finance/MFA operational acceptance; do not bypass authorization. |
| 020, 021 | Accessible generated fallback plus actual inspected artwork upload/delivery merged through PR #197. | Issue #193 stays open for both migrations, real scanner/Storage/configuration and artwork rendering/replacement acceptance. |
| 022 | Admin directory reads actual authorized courses rather than a seeded list. | Verify assignment-aware hosted visibility and sandbox archival. |
| 023 | Seeded application defaults removed. | Hosted placeholder-account inventory/retention remains open; the cleanup package does not authorize account deletion. |
| 024 | Avatar menu provides Profile, Sign out and authorized Admin actions. | Hosted account/session and sign-out acceptance. |

## Superseded verification and remaining gates

- [Issue #171](https://github.com/iamramishka/acendra/issues/171) is closed;
  [PR #165](https://github.com/iamramishka/acendra/pull/165) merged after its
  analyzer, formatter, 727-test Flutter suite and required hosted checks passed.
  The old stopped analyzer and 13 failures are historical, not current blockers.
- [PR #194](https://github.com/iamramishka/acendra/pull/194) merged reporting;
  [CSA266 release checklist](../tasks/CSA-266-PAYMENT-REPORTING.md) retains
  `ACENDRA_ADMIN_PAYMENT_LIST_ENABLED`, independent settlement reporting and exact
  origins. No hosted flag is asserted enabled by this document.
- [PR #197](https://github.com/iamramishka/acendra/pull/197) merged source into dev
  `d46ae1c`. Its reviewed head passed analysis, 990 Flutter tests, 21 Chrome tests,
  tooling (871 passed, seven conditional skips), release build and Supabase CI.
  This is recorded hosted CI evidence, not a new local run by CSA269.
- [Issue #193](https://github.com/iamramishka/acendra/issues/193) retains live
  media acceptance; [deployment contract](../deployment/CSA-267-MEDIA-INSPECTOR.md).
- [Cleanup runbook](../runbooks/CSA-SANDBOX-SEED-CLEANUP.md) records no hosted
  execution; archival and placeholder-account retention require actual evidence.
- [Issue #160](https://github.com/iamramishka/acendra/issues/160) retains isolated
  production capabilities, finance/notification acceptance, backups/recovery,
  monitoring and release approval. A source merge or preview is not production
  acceptance. No production settings or records were changed in this task.

CSA269 integrates the three committed primary-checkout changes after its merge
base with dev. The primary checkout is preserved. Its exact fresh verification
and any remaining integration failures are recorded in
[the task evidence](../tasks/CSA-269-OWNER-INTEGRATION.md), rather than inferred
from the prior PR197 result.
