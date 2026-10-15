# Remaining Phase8 tasks — owner-confirmed manual acceptance

Acceptance date: 2026-10-15. Acceptance authority: project owner. Status: DONE for the five tasks below.

The owner quoted the full remaining-task verification table and confirmed: "these are manually verified. it's done". This record accepts that report as owner-confirmed manual verification, superseding the earlier IN_REVIEW/operational-deferral status for these tasks.

| Task | Owner-confirmed checklist |
| --- | --- |
| CSA-186 | Valid uploads, oversized/unsupported/disguised rejection, inspection before use, unauthorized upload/replacement denial. |
| CSA-187 | Saved HTML/script displayed safely without execution; deployed security headers. |
| CSA-188 | Required CI/security checks, failure logging without secrets/private data, alert delivery. |
| CSA-200 | Actual backup restored into an isolated environment; recovered data, permissions and files; recovery time/data loss compared with agreed targets. |
| CSA-201 | Interrupted checkout/connectivity, refresh/retry, payment reconciliation, duplicate callbacks without duplicate enrollment and failed/pending access denial. |

Evidence provenance: owner's manual confirmation. CODEX did not independently observe these complete operational runs or receive per-check inspection, stored-payload, alert, backup, recovery-measurement or provider/callback artifacts. No individual test execution, backup identifier, RPO/RTO value, financial result or deployment is fabricated. Earlier repository/hosted results and operational failures remain historical evidence. Acceptance does not imply CODEX enabled gated services, changed permissions, migrated domains, merged a PR or approved production release.

Documentation owner CODEX root, existing issue129 continuation, isolated phase8-flow-integration/acendra worktree and feat/csa-178-sandbox-staging branch. User-authorized temporary shared scope: these five TASKS.md entries, the adjacent historical CSA-184–188 summary and this record. Open PR inventory contained only PR159; no overlapping open documentation PR was found. Verification: bounded diff review and git diff --check. No runtime changes or local tests. Included in PR159. Existing issues117/119/129 and PR159 retain their own lifecycle; other tasks and production release gates remain unchanged.
