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
historical verification failure. Supabase run38367822654 on4c50727 subsequently
passed all stages, including real Auth/MFA/HTTP/RPC/Storage bank/online integration,
pending/forged denial, replay idempotency and symmetric progress. Migration035
fixes deferred invariant functions running after the RPC definer context ends;
the original repeated orders42501 failure is resolved without direct financial
privilege grants. Paid-grant transaction completion also passed the journey.

The initial migration used an existing034 timestamp and failed replay23505;
it was corrected to the unique035 timestamp before the successful run. The native
RED/GREEN reproducer timed out at initdb on this host and cleaned its scratch
directory; no native result is claimed. Independent review found no blocking
privilege escalation in the two static qualified definer checks.

During final PR CI, dev advanced to79aaff4 with checkout UI. Its ten inherited
Dart formatting failures stopped Flutter's merged-head check. Root integrated
that completed commit rather than overwrite it; formatting-only repair and final
combined verification remain pending. Learning/My Courses and real provider/cloud
dependencies remain separately unverified.

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

Checkout UI was added by the newly integrated dev commit79aaff4; a complete
checkout-to-My-Courses/learning browser journey remains unverified.
Provider-enabled receipt/bank/payment/media production entry points are gated.
The test fixture inspector is not an approved operational parser/scanner, and
synthetic bank/provider evidence is not actual independent credit verification.
No deployed staging URL, hosting provider or managed log controls were supplied.
Cloud/service restore, operating backup encryption/retention and realistic
provider reconciliation remain unverified despite selected RPO/RTO objectives.
These facts cannot be completed by marking synthetic tests as live acceptance.
Tasks with these requirements remain IN_REVIEW/BLOCKED until actual dependencies
and evidence exist; no endpoint is enabled and no production data is accessed.

## Owner-authorized PR135 review correction — 2026-10-13

Refreshed against dev bee1e22 without conflicts. Four analyzer errors came from
premature registration of two screens absent from dev. Removed those missing
imports and kept the two authenticated routes visible as explicit unavailable
states using AppErrorState. No invented learning implementation, direct content
requests or entitlement grants are added. PR134's separately owned implementation
is excluded pending its schema/contract review. This fixes build readiness only;
My Courses/learning acceptance remains incomplete. Added four direct-route
regressions for unavailable authenticated routes and unauthenticated login guards.
The earlier instruction to wait for PR134 is superseded by this bounded route
availability correction under the owner's explicit fix-and-merge request.
Required hosted checks on the corrected combined head must pass before merge.

## CSA-178/179/180 current review — 2026-10-14

Owner: CODEX; project owner requested review and documentation update.
Reviewed dev `10c8b54d15c7e9b51e64a1db4aef4cf09c71e3c2` after PR144 merged.
This dated addendum supersedes earlier placeholder descriptions for the current
UI; the historical commands, failures and CI evidence above remain historical.
All three tasks remain IN_REVIEW with full journey acceptance blocked.

| Task | Current implementation and acceptance gap | Required acceptance evidence |
| --- | --- | --- |
| CSA-178 online purchase | Checkout creates an order, but `_onPayNow` only displays "Online payment coming soon". `initialize-checkout/index.ts` retains the default-disabled handler. The backend journey injects synthetic provider responses. | Approved provider sandbox payment through verified settlement, paid order, active enrollment, updated My Courses and paid lesson access in a browser. |
| CSA-179 bank approval | ReceiptUploadNotifier throws an unavailable error. The routed admin finance screen uses labelled synthetic records; approve/reject cannot record decisions, and receipt viewing is unavailable. Bank-review deployment remains disabled. | Approved receipt inspection/storage and independent bank-credit verification; student upload/pending state, pre-approval access denial, authorized review, approval-to-access, rejection and resubmission browser coverage. |
| CSA-180 purchase-to-learning | My Courses and learning screens are now routed. `getLessonContent` selects metadata only, without text/image bodies; video/PDF use coming-soon placeholders. Backend entitlement/progress assertions do not exercise content delivery or the Flutter journey. | Authorized content delivery after settlement, denial before settlement and after revocation, student isolation, and progress persistence across logout/login through the UI. |

Source references at the reviewed revision:
- `lib/features/checkout/presentation/screens/checkout_screen.dart:94`
- `supabase/functions/initialize-checkout/index.ts:2`
- `lib/features/bank_transfer/presentation/providers/bank_transfer_provider.dart:14`
- `lib/features/admin/presentation/screens/finance_review_screen.dart`
- `supabase/functions/admin-review-bank-transfer/index.ts:2`
- `lib/features/learning/data/repositories/supabase_learning_repository.dart:33`
- `lib/features/learning/presentation/screens/learning_workspace_screen.dart:283`

Executed locally on 2026-10-14 with Node v24.15.0:

```powershell
node --test supabase/functions/create-checkout-order/*.test.mjs supabase/functions/_shared/payments/*.test.mjs supabase/functions/initialize-checkout/*.test.mjs supabase/functions/payment-provider-webhook/*.test.mjs supabase/functions/upload-bank-receipt/*.test.mjs supabase/functions/admin-review-bank-transfer/*.test.mjs supabase/functions/admin-entitlements/*.test.mjs supabase/functions/authorize-video/*.test.mjs supabase/functions/_shared/pdf/*.test.mjs supabase/functions/pdf-content/*.test.mjs tool/csa178_186_journey_smoke.test.mjs
```

Result: 353 tests passed; 0 failed, cancelled, skipped or todo. These are
component tests with synthetic collaborators plus two journey-harness safeguard
tests. This command does not execute `runJourneySmoke` against a live stack.
No local Flutter/browser, disposable Supabase, provider sandbox or operational
bank journey was run during this review.

Static inspection of `tool/csa178_186_journey_smoke.mjs` confirms checks for
pending/forged access denial, duplicate settlement and symmetric student progress.
Its test-local HTTP handlers use disposable Auth/MFA/RPC/Storage when executed,
but provider responses, bank credit and exact-PNG inspection are synthetic.
The earlier successful hosted execution remains separate dated evidence; no
fresh integrated-stack pass is claimed here. Completion requires the missing
implementation dependencies and current end-to-end evidence described above.
