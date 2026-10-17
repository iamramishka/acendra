# Issue #160 startup integration on merged dev

Date: 2026-10-17 (Asia/Colombo). Owner: CODEX. Status: IN_REVIEW, local only.
Authority: project owner requested fixing the open repository issues.
Coordination: [issue #160](https://github.com/iamramishka/acendra/issues/160).
Branch: `codex/fix/csa-160-issue-reconciliation`.
Worktree: `C:/Users/ramis/Downloads/Acendra/pr165-review-20261017`.
Base: merged dev `020787ae50e2948aeb4cd8c3743dc7bd16b002ed`.

## Scope and result

The prior bounded fix `e86cc47304d045760483bbeb22014c42c221adfe` was committed
but never published. Current dev still initialized Supabase only from the legacy
anon define and bypassed `PublicBackendConfig` validation. A publishable-key-only
configuration therefore silently skipped initialization.

Integrate that reviewed prerequisite onto current dev, retaining the current
workflow's base64 SSH-key handling, validation and smoke behavior. Only its public
Flutter build defines change: explicit production environment and publishable key.
Bootstrap consumes `readForStartup()` and validates environment, URL and public
key shape. Only completely unconfigured development builds may omit the backend;
partial, invalid, privileged-key and unconfigured hosted values fail first.

Allowed file scope: bootstrap, environment config, configuration regression tests,
the production workflow's public build defines, hosting prerequisite text and
this handoff. Existing ownership was released; no other open PR overlapped.
No financial contract, RLS policy, private credential or deployment is changed.
The separately verified staging origin configuration is recorded below. No
production designation is inferred from the workflow name.

## Verification

- New configuration regressions failed before integration: missing startup
  resolver methods, Flutter test exit 1.
- Default development configuration: 9 tests passed, exit 0.
- Staging publishable-key binding: 9 tests passed, exit 0, synthetic values.
- Production legacy-key fallback: 9 tests passed, exit 0, synthetic values.
- `node --test tool/local_supabase.test.mjs`: 9 passed, exit 0; generated public
  configuration still matches the startup binding contract.
- Repository-wide Dart formatting: 271 files, zero changes, exit 0.
- Default `flutter analyze --no-pub`: no issues, exit 0.
- `flutter build web --release --no-pub`: exit 0, including a successful Wasm
  compatibility dry run. Existing Cupertino icon-font asset warning remains.
  This credential-free development artifact is not a configured production build.

## Current environment and staging directory repair

The owner directed inspection of the existing environment and a free method.
Credential values were consumed only in memory for authorized provider requests;
no secret values were printed, copied into artifacts or committed.

- Supabase project `worrsweluwjmppwsygre`: Acendra, ACTIVE_HEALTHY,
  ap-northeast-1. Auth site/redirects still use `https://acendra.vercel.app`.
- Vercel project `acendra`: Hobby; only `acendra.vercel.app` is verified, with
  `dev` as the provider production branch. This does not designate the data as
  production or establish commercial launch readiness.
- The documented VM hostname `https://3-25-99-105.sslip.io` timed out in this
  read-only check; its availability or suitability is not established.
- Supabase reports zero listed backups, PITR disabled and no custom SMTP host.
  No backup/restore destination variables were found in the task's `.env`.
- Observed payment setting names are sandbox settings. No approved live merchant
  binding or live acceptance evidence was discovered.
- Management metadata confirms the directory function is ACTIVE (version 1),
  the summary migration is present, and authenticated clients lack direct RPC
  EXECUTE. No user or financial rows were queried.

The deployed directory had no `ACENDRA_ADMIN_ALLOWED_ORIGINS` setting, and
requests from the configured staging origin failed with HTTP 403. Set only that
existing exact staging origin, `https://acendra.vercel.app`, on the verified
staging project. The management write returned HTTP 201. Post-change probes:

- Known staging origin without credentials: HTTP 401, reaching the auth gate.
- Preflight: HTTP 204; exact allowed origin, bounded headers and `no-store`.
- Untrusted origin: HTTP 403, still denied.

These probes verify the origin repair, not a signed-in real-role acceptance run.
No live reporting, payment, role, storage or production feature was activated.

## Publication and production holds

The issue requires a fresh check of at least 60 included Actions minutes and
available storage before CI-triggering publication. The CLI token returned HTTP
404 with missing `user` scope. The environment-file token subsequently permitted
the read-only billing query: October 2026 reports 3,210 Linux minutes, Pro plan,
and reported net amount zero. The standard Pro allowance is 3,000 minutes under
[GitHub's current billing reference](https://docs.github.com/en/billing/concepts/product-billing/github-actions).
The net amount is not evidence of unused included minutes or free future runs.

Repository cache metadata reported 25 entries totaling 11,739,768,348 bytes;
the documented separate included cache allowance is 10 GiB. No caches/artifacts
were deleted or allowance settings changed. The required capacity reserve is not
established. Use local checks; no CI-triggering push, PR or hosted workflow.

All eleven production tasks remain held under the
[readiness matrix](../tasks/CSA-PHASE9-FREE-READINESS.md). Approved production
target/domain, live merchant, notification/finance acceptance, monitoring and
independent backups/restore evidence cannot be established by this source fix.
The discovered configuration above identifies current services but supplies no
missing production approval, live merchant or independent restore evidence.

## Related issue reconciliation

Issues #164, #166 and #171 were updated and closed for their completed code scope
after confirming PR #165 merged and
[merged-dev Flutter CI passed](https://github.com/iamramishka/acendra/actions/runs/39045830869).
Their descriptions retain actual artwork, directory deployment and live-reporting
limitations. No production acceptance is claimed by those closures.
