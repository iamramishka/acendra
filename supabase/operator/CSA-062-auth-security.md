# CSA-062 authentication security

This repository configures the disposable/local Supabase baseline. It does
not configure a hosted project or constitute production release approval.

Email signup now requires confirmation. Clients must display a pending
verification state and obtain a session only after confirmation. Email
changes retain confirmation of both old and new addresses. Older sessions
(provider threshold: 24 hours) must reauthenticate before password changes.
This setting is not a guarantee that every password change prompts again.

Access JWTs last 900 seconds. Refresh token rotation remains enabled with
the provider's 10-second reuse interval for benign concurrent browser calls.
Logout revokes the provider session/refresh token; ordinary PostgREST access
with a previously issued JWT can remain possible until expiry. Sensitive
administrator mutation independently checks the current session in CSA-073.

Minimum password length remains 12; anonymous sign-in/manual linking stay
disabled. Existing explicit provider rate limits remain enabled (30 sign-in/
signup and token verification requests per five minutes per IP, 150 refresh
requests; SMTP email limit two/hour where enabled). Confirmation/recovery
email requests now have a one-minute per-user cooldown and tokens expire
after 600 seconds. These are a tested baseline, not measured production
capacity or a substitute for infrastructure abuse controls.

TOTP enrollment/verification and Edge platform JWT validation remain enabled.
Privileged operations require actual aal2 and current database grants.
Redirects are explicit local URLs without wildcards.

## Verification

Run node --test tool/*.test.mjs and the Edge handler suites, then the
Supabase foundations workflow. Its independent loopback development/test
stacks replay migrations and run actual Auth/PostgREST/Edge APIs.

auth_security_smoke.mjs checks signup without session, unconfirmed login
denial, provider-generated confirmation token consumption, weak password
and anonymous rejection, generic wrong/missing account credentials, old
session password reauthentication, recovery expiry/replay, per-user mail
cooldown, JWT lifetime, refresh rotation and local logout.

Only the test account's confirmation/recovery hash is read from the
task-owned local database to drive the provider verification API. This
tests token consumption, not inbox delivery. Foundation and role API
fixtures explicitly operator-confirm their own synthetic users so they
can test their separate RLS/MFA contracts with confirmation enabled.
No tokens, password, mail payload or private responses are logged.

## Hosted release gates

An authorized operator must separately apply and verify matching Auth
settings in development/staging/production. supabase/config.toml does not
silently apply them to hosted projects. Record exact approved HTTPS site,
redirect URLs and admin origins; never carry loopback defaults into a release.
Configure approved SMTP credentials through secrets, sender identity and
deliverability, verify confirmation/recovery/email-change links in supported
Flutter browsers, and assess mail/IP limits with expected student load.

Evaluate provider-supported leaked-password checks, CAPTCHA and session
timeouts against the approved budget and compatibility requirements;
secrets, paid upgrades and arbitrary business timeout policies are not added
by this task. Privileged TOTP/MFA, session revocation, incident recovery and
production role controls must be independently reviewed before launch.

References: [CLI config](https://supabase.com/docs/guides/local-development/cli/config),
[password security](https://supabase.com/docs/guides/auth/password-security),
[sessions](https://supabase.com/docs/guides/auth/sessions),
[rate limits](https://supabase.com/docs/guides/auth/rate-limits).
