# First super-admin bootstrap (operator only)

Use only after authorized identity verification and explicit environment release
approval. Never use a browser, service-role key, signup metadata or public endpoint.
No real account was bootstrapped as part of implementation.

1. Create and verify the intended account through Supabase Auth. Confirm its UUID,
   eligibility and profile. Complete MFA setup before administrative requests.
2. With the controlled database owner session for the approved environment, execute
   the following using the verified UUID, a documented approval reason and a fresh
   request UUID. Use parameters in automation; never interpolate untrusted input.

```sql
begin;
select public.csa061_bootstrap_super_admin(
  :verified_account_uuid::uuid,
  :approval_reason::text,
  :request_uuid::uuid
);
commit;
```

3. Record the returned grant ID and independently inspect the corresponding
   csa061_role_audit bootstrap event. Do not log tokens or keys.
4. Configure ACENDRA_ADMIN_ALLOWED_ORIGINS with explicit approved HTTPS origins
   before deploying the Edge function. Keep privileged credentials backend only.

The function permits a single bootstrap, preserves an immutable actor-null event,
and rejects repeated initialization with a new request. Exact request replay returns
the original grant ID and does not restore revoked authority. Subsequent changes
require a different current super-admin using an MFA-verified session through the
guarded endpoint. A recovery after loss of all eligible administrators requires a
separately authorized audited operator procedure; do not rerun or weaken bootstrap.
