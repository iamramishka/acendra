-- CSA-207–212 metadata preflight. Run only through an authorized SQL console.
-- No credentials, object names, users, financial rows or callback bodies.
-- Inspect the connected project in the console first; SQL cannot prove it.
begin transaction read only;
set local statement_timeout = '10s';
set local lock_timeout = '2s';

-- Compare every version with the reviewed release filenames, not only totals.
select version from supabase_migrations.schema_migrations order by version;

-- Ordinary and partitioned application tables; excludes views/system schemas.
select n.nspname as schema_name, c.relname as table_name,
       c.relrowsecurity as rls_enabled, c.relforcerowsecurity as rls_forced
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public', 'app_private') and c.relkind in ('r', 'p')
order by n.nspname, c.relname;

select id as bucket_id, public, file_size_limit, allowed_mime_types
from storage.buckets
where id in ('bank-receipts', 'course-pdfs', 'course-media') order by id;

-- Policy metadata only. Presence/count does not prove a safe predicate.
-- Review predicates privately in the approved target console if needed.
select schemaname, tablename, policyname, permissive, roles, cmd
from pg_policies
where schemaname in ('public', 'app_private')
   or (schemaname = 'storage' and tablename in ('objects', 'buckets'))
order by schemaname, tablename, policyname;

-- These trusted finance boundaries must deny anon/authenticated EXECUTE.
-- Missing functions are visible as missing rows, not an implied PASS.
select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as identity_arguments,
       has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
       has_function_privilege('service_role', p.oid, 'EXECUTE') as service_execute
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('csa112_review_bank_transfer', 'csa179_read_bank_transfer')
order by p.proname, identity_arguments;

rollback;
