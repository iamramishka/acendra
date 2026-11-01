-- Current complete application catalog, not a static list of tested feature files.
begin;
create temporary sequence csa182_assertions;
create function pg_temp.assert_ok(c boolean,d text) returns text language plpgsql as $$begin if c is distinct from true then raise exception 'Assertion failed: %',d;end if;return 'ok '||nextval('pg_temp.csa182_assertions')||' - '||d;end;$$;
select pg_temp.assert_ok(c.relrowsecurity,'RLS enabled '||n.nspname||'.'||c.relname)
from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','app_private') and c.relkind in ('r','p');
select pg_temp.assert_ok(not has_table_privilege(r,c.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
  and not has_any_column_privilege(r,c.oid,'SELECT,INSERT,UPDATE,REFERENCES'),'no private direct grants '||r||' '||c.relname)
from pg_class c join pg_namespace n on n.oid=c.relnamespace cross join unnest(array['anon','authenticated']) roles(r)
where n.nspname='app_private' and c.relkind in ('r','p');
-- Backend actor-supplying CSA RPCs must never be client executable. The only
-- client RPC exceptions derive authenticated identity internally.
select pg_temp.assert_ok(not has_function_privilege(r,p.oid,'EXECUTE'),'client RPC deny '||r||' '||p.oid::regprocedure)
from pg_proc p join pg_namespace n on n.oid=p.pronamespace cross join unnest(array['anon','authenticated']) roles(r)
where n.nspname in ('public','app_private') and p.proname like 'csa%'
and not (r='authenticated' and n.nspname='public' and p.proname in ('csa060_account_eligible','csa117_verify_entitlement','csa133_save_progress','csa133_read_progress'));
-- Profiles expose only the approved presentation/preference columns; no browser financial/role/
-- content row can be directly mutated, including column-only privilege grants.
select pg_temp.assert_ok(not has_table_privilege(r,c.oid,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
 and not has_any_column_privilege(r,c.oid,'INSERT,UPDATE,REFERENCES'),'no public direct mutation '||r||' '||c.relname)
from pg_class c join pg_namespace n on n.oid=c.relnamespace cross join unnest(array['anon','authenticated']) roles(r)
where n.nspname='public' and c.relkind in ('r','p') and not (r='authenticated' and c.relname='profiles');
select pg_temp.assert_ok(not has_column_privilege('authenticated',a.attrelid,a.attnum,'UPDATE'),'protected profile column '||a.attname)
from pg_attribute a where a.attrelid='public.profiles'::regclass and a.attnum>0 and not a.attisdropped and a.attname not in ('display_name','locale','avatar_path','email_notifications_enabled');
select pg_temp.assert_ok(has_column_privilege('authenticated','public.profiles',column_name,'UPDATE'),'approved profile update '||column_name)
from unnest(array['display_name','locale','avatar_path','email_notifications_enabled']) column_name;
select pg_temp.assert_ok(exists(select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_avatar_path_own_folder' and convalidated),'avatar own-folder constraint enforced');
select pg_temp.assert_ok(exists(select 1 from storage.buckets where id='avatars' and not public and file_size_limit between 1 and 5242880),'avatar bucket remains private and bounded');
select pg_temp.assert_ok(p.proconfig @> array['search_path=""'],'definer empty search path '||p.oid::regprocedure)
from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','app_private') and p.proname like 'csa%' and p.prosecdef;
select '1..'||last_value from csa182_assertions;
rollback;
