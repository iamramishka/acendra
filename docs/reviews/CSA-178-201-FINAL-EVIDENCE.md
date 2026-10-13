# Phase 8 integrated acceptance evidence

Owner CODEX root. User requested all remaining work in one parallel integration.
Claim [issue #129](https://github.com/iamramishka/acendra/issues/129). Base c89796f.
Separate workers and writable scopes are recorded in CSA-178-201-FINAL-BOARD.md.

## Completed registry reconciliation

CSA-189 and CSA-197 have merged PRs #121/#122, successful exact-head CI and
Issues #116/#118 closed as COMPLETED. Current scanner/benchmark safeguards pass.
Fresh current locked audit: 126 Pub, 3 PyPI and 15 npm entries; no returned
advisories on 2026-10-13T06:42:28.796Z. Bounded dated review and local benchmark
acceptance are DONE; this does not certify every runtime or production workload.

CSA-182 now has catalog-derived checks for every current public/app_private table,
private table/column ACLs, trusted actor-supplying RPC execution, public direct
mutation grants, protected profile columns and definer search paths. Real Supabase
run38358573508 passed the SQL test stage and lint. That run later failed its new
journey smoke, so no overall success is claimed for it. CSA-183 existing csa155,
csa116 and per-feature isolation suites passed in that same real SQL stage;
existing real API profile/role/private-file checks also passed. These establish
the current repository database audit/isolation scope, separately from full
purchase/browser/provider acceptance.

## Actual private Storage recovery

In run38358573508 the new actual disposable Storage API archive/loss/restore check
passed: capture three synthetic private objects to a disk archive, validate the
complete archive and independently bound tombstones, delete exact objects, restore
two byte streams with SHA-256 and database metadata equality, preserve one deleted
object and deny anonymous/student direct/public/signed access. Elapsed1833–1948ms
on two initial runs is a small synthetic API exercise, not production RTO.
Independent review added explicit denial statuses and guaranteed archive cleanup
when remote cleanup fails. Five corruption/identity/deletion/denial safeguards pass.
Final combined CI is required for the corrected version.

## Integrated journeys and browser checks

The test-local HTTP server mounts current handlers against actual disposable
Auth/MFA/PostgREST/Storage. Payment provider responses, bank credit and exact PNG
inspection are explicitly synthetic. Pending/forged access, replay and symmetric
progress assertions must pass before claiming this test integration verified.
Initial real run failed in the bank/receipt stage; diagnostic checkpoints were
refined without exposing credentials or private response bodies. This is an
unresolved verification failure until corrected and rerun.

Six actual marketplace/profile widget cases use image, SVG and script payloads;
Chrome DOM checks run while malicious titles/profile text remain visible. Initial
hosted Chrome cases passed, but root's wrapper incorrectly required a legacy
text summary. The wrapper now requires structured success and all six executed
cases. Local Dart runners stalled; no local pass is claimed. Hosted Flutter
run38360032868 on16e86c0 succeeded: 205 Flutter tests and 729 tooling passes with
zero failures, including the Chrome runner confirming all six malicious-text
cases executed successfully. This closes current widget/browser payload coverage,
not deployed headers, managed logs or a configured production release bundle.

## Remaining requirements

Checkout/My Courses/learning routes are still placeholders in the approved base.
Provider-enabled receipt/bank/payment/media production entry points are gated.
The test fixture inspector is not an approved operational parser/scanner, and
synthetic bank/provider evidence is not actual independent credit verification.
No deployed staging URL, hosting provider or managed log controls were supplied.
Cloud/service restore, operating backup encryption/retention and realistic
provider reconciliation remain unverified despite selected RPO/RTO objectives.
These facts cannot be completed by marking synthetic tests as live acceptance.
Tasks with these requirements remain IN_REVIEW/BLOCKED until actual dependencies
and evidence exist; no endpoint is enabled and no production data is accessed.
