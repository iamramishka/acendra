# Sandbox-only entrypoint ownership

2026-10-15 CODEX backend_acceptance delegate, issue129 continuation. User
authorized staging readiness and actual sandbox journey; production remains
excluded. Base628f00a. Isolated phase8-sandbox-entrypoints/acendra branch
feat/csa-178-staging-sandbox. Scope three checkout/provider index entrypoints,
new shared sandbox wiring/tests and task-specific evidence. Root exclusively
reviews/integrates/deploys; worker will not deploy or read/print secrets.
Gate: explicit APP_ENV staging, provider sandbox, exact approved Supabase target,
exact frontend acendra.vercel.app. Trusted existing adapter checksum then OAuth
settlement and trusted atomic financial RPC remain unchanged. Hosted checks only.
Status IN_REVIEW; no actual settlement evidence claimed.

Root-confirmed staging Supabase https://worrsweluwjmppwsygre.supabase.co;
frontend https://acendra.vercel.app. Exact equality required; wrong environment,
project, origin list or incomplete sandbox credential configuration stays closed.
Server secret names PAYHERE_SANDBOX_MERCHANT_ID, PAYHERE_SANDBOX_MERCHANT_SECRET,
PAYHERE_SANDBOX_APP_ID, PAYHERE_SANDBOX_APP_SECRET; no generic-name fallback.
Root may copy authorized Gitignored merchant values into sandbox server secrets
after review/CI; worker did not inspect/read/print those values.
APP_ENV=staging, PAYHERE_ENVIRONMENT=sandbox and
ACENDRA_CHECKOUT_ALLOWED_ORIGINS=https://acendra.vercel.app required.
SUPABASE_URL is the exact reviewed target. Existing trusted handler service keys
are required separately; no privileged credential enters Flutter.
Return URL is the existing /dashboard/courses route; cancel is /marketplace.
Neither browser return nor client status can finalize a payment. Existing provider
checksum/OAuth binding and csa104 atomic idempotent finalize RPC remain unchanged.
Notify targets the reviewed Supabase payment-provider-webhook function. Existing
config disables gateway JWT verification for provider callback only; adapter
authenticity/settlement verification remains mandatory.

New hosted-discovered payment tests verify boundary/missing-secret denial for all
three deployed wrappers, forged callback denial, verified Auth prerequisite and
synthetic checksum→OAuth retrieval→atomic-finalize sequencing. Synthetic values
only; no actual callback/payment evidence claimed. No local tests executed.
Root must obtain exact-head CI/review before deployment and real sandbox journey.
