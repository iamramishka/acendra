# Local Supabase development

Use an isolated task worktree, Node.js 20 or newer, and Flutter from the repository
baseline. Full Supabase stack commands require a Docker Linux engine in a suitable
test environment; Docker on the project owner's laptop is not required. Native
PostgreSQL supports the database-only verification described below. The CLI is pinned to 2.120.0
in package.json/package-lock.json; Node tooling does not change Flutter dependencies.
Docker Desktop is the supported Windows runtime. No hosted project, account,
payment provider or paid resource is needed for this workflow.

## Install and prepare

```powershell
npm ci
npm run tool:test
npm run db:prepare
npm run db:start
npm run db:status
```

The scripts derive project IDs from the absolute worktree path plus `dev`/`test`.
They create separate configuration snapshots in ignored
`build/supabase-local/dev` and `build/supabase-local/test`. Each project has its own
Docker resources/data volumes and loopback-binding network; the test stack never
shares development data. Ports are derived from the worktree identity: the dev
block has ten ports, and the test block occupies the next ten, including a separate
Edge Runtime inspector port. IDs remain stable across runs in the same worktree.

Only tracked-style SQL migration/test inputs, config and seed are copied into
snapshots. Hosted `.temp` links, credentials and stage checks are excluded, and
removed SQL inputs are removed from snapshots. Keep schema changes in
`supabase/migrations`, not generated build directories. Supabase credentials/URLs
from inherited `SUPABASE_*` variables are cleared for these local commands.
Remote Docker endpoints and hosted CLI commands are not supported by the wrapper.
Local status output is reduced to the API URL/project name; keys are not printed.

Port hashing reduces conflicts but does not guarantee uniqueness across worktrees.
If Docker reports a conflict, stop this task's stack and select an unused block of
20 ports (1024–65534). Set the first port explicitly in your shell, for example:

```powershell
$env:ACENDRA_LOCAL_PORT_BASE = '58000'
npm run db:prepare
npm run db:start
```

The first port must be at most 65515. `.env.example` documents this option, but
the wrapper does not automatically read .env files. On POSIX shells use
`export ACENDRA_LOCAL_PORT_BASE=58000`. Keep this setting consistent for all commands;
stop the current stack before changing it. Port collisions fail startup rather
than reusing another worktree's database. The app's local web port remains 8080;
coordinate another exact frontend URL/config change if running concurrent apps.

## Browser configuration

```powershell
npm run client:env
flutter run -d chrome --web-port 8080 --dart-define-from-file=config/development.local.json
```

`client:env` reads status from this worktree's dev stack, validates that the API
URL matches its loopback endpoint, and writes only APP_ENV, SUPABASE_URL and the
publishable/legacy anon key into the ignored JSON file. Server secrets are never
exported. `config/client.example.json` is a public placeholder, not a usable key.
Use ignored `config/staging.local.json` or `config/production.local.json` for later
approved hosted environments, with APP_ENV set explicitly and an HTTPS project
URL. Hosted provisioning is not part of this task.

`EnvConfig.read()` validates these values before future Supabase initialization:
development is loopback-only; hosted environments require non-loopback HTTPS;
URLs cannot contain embedded credentials/query/fragment; secret keys and legacy
JWTs claiming anything other than `anon` are rejected without echoing values.
SUPABASE_ANON_KEY remains a compatibility fallback. Public key shape checks are
an accidental-secret guard, not JWT authentication or authorization.

The current UI bootstrap still does not initialize a backend. A subsequent
authentication task must call `EnvConfig.read()` and initialize Supabase from the
validated result. .env files are not Flutter assets, and Flutter does not load
them automatically. Never put service-role/secret, database, payment, video or
email credentials in dart-defines, web assets or this client JSON. RLS is required
even with public keys. Server secrets belong only in approved backend secret stores.
Local Auth signing-key JSON is also ignored and must not be committed.

## Migrations and database tests

Create a migration in the task worktree, following exclusive migration ownership:

```powershell
npm exec --no -- supabase migration new csa060_profile_rls
```

Write ordered SQL under `supabase/migrations`. The baseline uses PostgreSQL 17;
future hosted environment setup must verify matching major versions. All
application grants must be explicit: `api.auto_expose_new_tables = false`.
Only `public` is exposed, and private/auth/storage internals stay outside the
Data API schema list. Existing CSA-059 deny-by-default rules remain intact.

```powershell
npm run db:reset
npm run db:test
npm run db:lint
```

`db:reset` resets **only this worktree's development stack**, replaying migrations
then seed. It destroys its synthetic local data. `db:test` and `db:lint` start and
reset the separate disposable **test stack**, then run `supabase test db --local`
or `supabase db lint --local --level warning --fail-on warning`. These commands
cannot accept a hosted URL or linked target. Tests roll back their fixtures.
Leave both stacks stopped when finished:

```powershell
npm run db:stop
npm run db:test:stop
```

`000_foundation.test.sql` uses pgTAP to verify actual Supabase Auth/Storage and
the application migration/FK foundation. CSA-059 contributes 34 lasting schema
checks. Additional policy tests belong under `supabase/tests/database` as CSA-060/061
are implemented. The old deny-all snapshot in `supabase/stage_checks` is deliberately
outside recursive test discovery and applies only before access policies exist;
run it with psql ON_ERROR_STOP=1 against a disposable local database when needed.

The default seed is intentionally empty: migrations seed role definitions, while
tests create synthetic identities transactionally. No admin bootstrap, paid
enrollment, receipt or financial records are preloaded. Local email stays in
Mailpit. Local configuration is not a production authentication policy; CSA-062
must separately implement and verify production security.

## Troubleshooting and verification status

If the wrapper reports no local Docker Linux engine, open Docker Desktop and
complete its WSL/virtualization setup. `docker info` must succeed in Linux-container
mode before database commands work. Use a local Docker socket/context; remote
daemons are intentionally rejected. No OS distributions are installed by these scripts.

CLI failure details are saved to ignored `build/supabase-local/<profile>/last-command.log`.
Treat logs as private: status/start output can contain local server credentials.
Do not paste or commit those logs. Scripts preserve nonzero failures.

On 2026-10-11, CLI installation, preparation, tooling/environment tests and Flutter
tests were verified. Supabase start/reset/test/lint remained unverified because
Docker's Linux engine was unavailable. The owner chose "Finish the PR; verify
Docker later". Do not infer a database/security pass from Flutter/tooling checks.
See [task evidence](tasks/CSA-032-035.md) for exact results and remaining checks.

Sources: [Supabase local development](https://supabase.com/docs/guides/local-development),
[CLI configuration](https://supabase.com/docs/guides/local-development/cli/config),
[database testing](https://supabase.com/docs/reference/cli/supabase-test-db),
and [API key guidance](https://supabase.com/docs/guides/api/api-keys).

## Native PostgreSQL verification without Docker

The owner explicitly removed laptop Docker verification as a requirement on
2026-10-11. Do not require repairing Docker/WSL or running containers on that
laptop. Tooling tests (`npm run tool:test`) and Dart configuration tests can run
without Docker. For database-only checks, use a new task-owned PostgreSQL 17
cluster bound to 127.0.0.1 on an unused port, with synthetic fixtures only. Do not
use an existing personal, shared or production database.

Native verification executed on 2026-10-11 used installed PostgreSQL 17.7,
port 55435 and ignored `.superpowers/csa032035-native-pg`. Two fresh databases,
`csa032035_dev` and `csa032035_test`, each received the migration and empty seed.
The synthetic fixture supplies roles anon/authenticated/service_role (the latter
BYPASSRLS), schema auth, and `auth.users(id uuid primary key)`. Permissive default
table grants deliberately check that migration revocations still deny access.
This is a SQL fixture, not the real Supabase Auth schema or service.

Run the existing database-only suites with native psql and ON_ERROR_STOP=1:

```powershell
# Set $pgBin to the installed PostgreSQL 17 bin directory. Use only a fresh
# synthetic database prepared as described above; repeat for the second database.
& "$pgBin/psql.exe" -h 127.0.0.1 -p 55435 -U postgres -d csa032035_test -v ON_ERROR_STOP=1 -f supabase/tests/database/csa059_profile_role_schema.test.sql
& "$pgBin/psql.exe" -h 127.0.0.1 -p 55435 -U postgres -d csa032035_test -v ON_ERROR_STOP=1 -f supabase/stage_checks/csa059_access_baseline.sql
```

All 34 schema and 75 stage access assertions passed in each database. Fixture
rollback left zero Auth users/profiles/grants and four role definitions in each.
A synthetic Auth record inserted in dev was absent from test, confirming native
database separation. The temporary cluster was stopped after verification.
The access snapshot applies only before CSA-060/061 introduce allowed policies.

The 8 foundation pgTAP assertions require actual Supabase schemas/services and
were not run against a fabricated Storage schema. Native results do not establish
Auth signup/recovery, Storage, PostgREST/API access, CLI stack port/volume isolation,
Supabase lint or real status export. These integration checks belong in a separate
suitable test environment (coordinate with CSA-036/242 CI); they are not a laptop
Docker prerequisite or a reason to block independent development work.