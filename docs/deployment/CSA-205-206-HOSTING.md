# CSA-205/206: hosting, domain and HTTPS preparation

Date: 2026-10-14 (Asia/Colombo). Owner: CODEX hosting agent.
Status: IN_REVIEW for documentation; CSA-205 and CSA-206 remain pending.
Assignment: [CSA-205–210 preparation board](../tasks/CSA-205-210-PREPARATION.md).
The user requested dummy details now and live configuration later. This document
provides a preparation sequence; it records no deployment or operational acceptance.

## Target worksheet

| Field | Documentation-only value | Evidence needed before use |
| --- | --- | --- |
| Hosting provider | UNSELECTED | Owner-approved provider and plan |
| Hosting account | DUMMY_HOST_ACCOUNT | Authorized account, payer and administrator access |
| Hosting project | DUMMY_HOST_PROJECT | Environment-isolated project and deployment permissions |
| Canonical origin | https://courses.example.invalid | Domain ownership and controlled DNS zone |
| Staging origin | https://staging.courses.example.invalid | Separate deployment and origin allowlists |
| Backend URL | https://supabase.example.invalid | Verified production Supabase URL |
| Backend project reference | DUMMY_PRODUCTION_PROJECT_REF | Verified target identity |
| Release revision | DUMMY_RELEASE_COMMIT | Reviewed immutable commit and successful required CI |
| Release operator | DUMMY_RELEASE_OPERATOR | Designated maintainer and concrete release authorization |

All values are intentionally unusable. Do not resolve these URLs, build a release,
configure DNS, or run deployment commands using this worksheet. Choosing a provider,
buying a domain or starting paid service remains a later approved decision.
[CSA-012](../decisions/CSA-012-ENVIRONMENTS-BUDGET.md) reserves USD 5/month for
production static hosting and USD 2/month amortized for domain renewal; these
planning amounts are neither provider selection nor purchase authority.

## CSA-205 preparation sequence

1. Freeze the reviewed release revision and identify the operator, provider account,
   project, plan and permitted deployment surface. Record actual hosting quotes and
   recurring/one-time costs against the approved budget. Keep staging separate.
2. Confirm the host supports Flutter static output, deep-link fallback, HTTPS,
   configurable response headers, deployment rollback and restricted administrator
   access. Record provider-specific setup after provider selection; no universal
   DNS record or deployment command is assumed here.
3. Obtain verified public backend configuration. The current client reads precisely
   `APP_ENV`, `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`; legacy
   `SUPABASE_ANON_KEY` is a compatibility fallback. The project reference above is
   an operator identity check, not a Flutter environment key. See
   [EnvConfig](../../lib/core/config/env_config.dart) and
   [local configuration guidance](../LOCAL_DEVELOPMENT.md).
4. Build the approved revision with public production defines, scan the resulting
   browser assets for privileged material, and record the artifact hash and build
   evidence. Upload only the verified `build/web` artifact through the approved
   deployment process. Configure fallback for client routes while preserving real
   static asset errors; verify direct navigation, refresh and browser history.
5. Record deployment identifier, release revision, artifact digest, operator,
   timestamp, rollback destination and deployment access controls. Exercise rollback
   in the approved environment before relying on it for production recovery.

The public configuration schema below is illustrative and intentionally invalid:

```json
{
  "APP_ENV": "production",
  "SUPABASE_URL": "https://supabase.example.invalid",
  "SUPABASE_PUBLISHABLE_KEY": "DUMMY_PUBLIC_KEY_REPLACE_BEFORE_BUILD"
}
```

`EnvConfig` requires a non-loopback HTTPS backend in production and accepts only a
publishable key or legacy anon key shape. The dummy key fails that check by design.
Never put service-role, payment, SMTP or video signing credentials in this JSON,
Dart defines or browser assets. After replacement with verified public values,
the existing build pattern is `flutter build web --release
--dart-define-from-file=config/production.local.json`; keep that local file ignored.
This command has not been executed for this preparation. Current
[Flutter CI](../../.github/workflows/flutter-ci.yml) builds without backend
credentials and contains no deployment job; its successful build would not prove
production configuration.

## CSA-206 preparation sequence

CSA-206 depends on the selected CSA-205 hosting target. After concrete approval:

1. Verify registrar/DNS ownership, existing records and allowed change scope.
   Record provider-generated DNS requirements, canonical host and certificate
   validation method. Preserve unrelated records; choose aliases only when approved.
2. Configure the verified hostname and certificate through the selected host.
   Verify trusted certificate chain, hostname match, expiration and renewal ownership.
   Confirm HTTP-to-HTTPS and any approved hostname redirects end at the canonical
   application; test both redirect responses and the final successful response.
3. Coordinate exact Auth redirect URLs, API CORS origins, media authorization origins
   and payment callback URLs with their task owners. Keep staging and production
   distinct; do not substitute unrestricted wildcard origins.
4. Configure and test enforced CSP, HSTS, `X-Content-Type-Options: nosniff`, restrictive
   referrer policy, camera/microphone permissions and frame restrictions against
   [SECURITY.md](../../SECURITY.md). Decide HSTS duration/subdomain coverage from
   verified domain scope before enabling it; do not infer authority over all subdomains.
5. Run `node tool/csa187_headers.mjs <verified-final-https-url>` from the approved
   revision and retain status/findings without cookies or secret values. The existing
   [header evaluator](../../tool/csa187_headers.mjs) errors on redirects, so evaluate
   the final URL explicitly and inspect redirect behavior separately.

A CSP template cannot be considered operational here: [web/index.html](../../web/index.html)
loads Google Fonts and Flutter bootstrap, and the approved backend/media integrations
need concrete allowed endpoints. Configure the narrow policy against the actual
release and inspect browser violations. A header-tool pass alone does not establish
Flutter functionality or stored/reflected XSS resistance.

## Verification and retained completion gates

Collect actual evidence for the following after authorized live configuration:

- Effective HTTPS/security headers at the canonical origin and representative assets;
  certificate validity/renewal and HTTP/canonical redirects.
- Browser startup with the intended production backend, no mixed content or blocked
  required resources; loading, error and session states.
- Direct links, refresh, browser back/forward, authentication redirects and logout;
  responsive operation at 390, 768 and 1440 logical pixels plus narrow/intermediate
  widths; keyboard and accessibility checks.
- Authorized checkout and protected content journeys after the separate backend,
  payment and entitlement gates are satisfied; failed authorization remains denied.
- Reviewed release/CI, public artifact secret scan, least-privilege host access,
  monitoring and backup/recovery readiness, tested rollback and production smoke tests.

Hosting/domain worksheets can be prepared in parallel with secrets and database
planning. Domain activation follows provider selection; production behavior checks
follow the reviewed backend and runtime enablement dependencies. No task becomes
DONE solely from preparing this document.

## Preparation evidence and handoff

### Dummy refresh readiness, 2026-10-14

The owner reconfirmed dummy preparation. The current assignment and exclusive
documentation scope are recorded in the refresh section of the
[preparation board](../tasks/CSA-205-210-PREPARATION.md). Operational tasks remain
pending; this refresh does not select a host or authorize live configuration.

Repository inspection found only the tracked local
[client example](../../config/client.example.json), with a loopback backend and
replacement key. No tracked Vercel, Netlify, Firebase or Wrangler hosting
configuration was found. Flutter CI verifies and builds without backend
credentials; it has no deployment job. No concrete hosting account/project,
controlled domain/DNS zone, certificate, production backend target or release
operator is evidenced by these files. Ignored local files and external provider
accounts were not inspected; this is repository readiness evidence only.

One runtime prerequisite remains: [bootstrap](../../lib/app/bootstrap.dart)
currently initializes Supabase only when `SUPABASE_URL` and `SUPABASE_ANON_KEY`
are present, and does not call `EnvConfig.read()`. Consequently, the illustrative
publishable-key-only JSON above does not initialize the backend today, and the
configuration validator's HTTPS/key checks are not enforced by this entry point.
A separately owned, reviewed runtime change must connect the validated public
configuration before claiming production startup. Do not bypass this prerequisite
by treating the example build command as verified deployment guidance.

Next handoff: the owner/designated infrastructure maintainer supplies the selected
provider, account/project, controlled canonical and staging origins, verified
public backend target and release operator. Coordinate the bootstrap prerequisite
with its runtime owner; then implement provider-specific fallback, headers and
deployment/rollback configuration against the approved target. Domain/TLS and
browser verification follow that configuration. No further provider-independent
hosting implementation is claimed by this documentation refresh.

Refresh verification: reviewed the referenced source, checked local Markdown link
targets and ran `git diff --check`. No build, network/header request, DNS/TLS
operation, deployment or production test was performed.

Inspected: TASKS.md Phase 9, PLAN.md Phase 9, SECURITY.md Flutter Web requirements,
CSA-012 environment/budget decision, EnvConfig, public client example, local
configuration guidance, web index, Flutter CI and the existing header evaluator.
Preparation verification is reference review and `git diff --check` only.
No Flutter build, browser/header test, DNS request, certificate issuance, deployment,
provider purchase, credential injection or production smoke test was performed.
Root integrates this single scoped document; project owner/designated maintainer
accepts preparation and authorizes later concrete configuration.
