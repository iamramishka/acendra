-- Behavioral public RPC denial tests. All fixtures and calls roll back.
begin;
select '1..3';
create temporary table csa176_calls(name text primary key, command text not null);
insert into csa176_calls values
 ('roles','select public.csa073_change_role($1,$2,$3,$4,''finance_admin'',''grant'',''Synthetic denial'',$4)'),
 ('create','select public.csa089_create_course($1,$2,$3,$4,''{"title":"Synthetic","slug":"csa176-denied"}''::jsonb)'),
 ('publish','select public.csa165_publish_course($1,$2,$3,$4,now(),''publish'',''csa176'')'),
 ('grant','select public.csa116_grant_admin($1,$2,$3,''csa176'',$4,$4,''Synthetic denial'',null)'),
 ('revoke','select public.csa118_revoke_access($1,$2,$3,''csa176'',$4,null,null,''account'',''Synthetic denial'')'),
 ('release','select public.csa118_release_restriction($1,$2,$3,''csa176'',$4,''Synthetic denial'')'),
 ('enrollments','select public.csa168_list_enrollments($1,$2,$3,$4,null,20)'),
 ('dashboard','select public.csa158_dashboard_stats($1,$2,$3,''last_30_days'')'),
 ('finance','select public.csa172_financial_report($1,$2,$3,''2026-10-01''::date,''2026-10-12''::date,''LKR'')'),
 ('bank','select public.csa112_review_bank_transfer($1,$2,$3,''csa176'',$4,''reject'',null,''Synthetic denial'',null)'),
 ('media-prepare','select public.csa164_prepare_media_upload($1,$2,$3,$4,$4,null,''public_thumbnail'',''image/png'',8,''csa176-policy'')'),
 ('media-get','select public.csa164_get_media_upload($1,$2,$3,$4)'),
 ('media-finalize','select public.csa164_finalize_media_upload($1,$2,$3,$4,repeat(''a'',64),8,''image/png'',''csa176-policy'')');
grant select on csa176_calls to anon,authenticated,service_role;
create function pg_temp.csa176_state() returns jsonb language plpgsql as $$
declare t record; data jsonb; result jsonb:='{}';
begin
 for t in select n.nspname,c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','app_private') and c.relkind='r' loop
  execute format('select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),''[]''::jsonb) from %I.%I t',t.nspname,t.relname) into data;
  result:=result||jsonb_build_object(t.nspname||'.'||t.relname,data);
 end loop;
 return result;
end; $$;
insert into auth.users(id,raw_user_meta_data) values
 ('17600000-0000-0000-0000-000000000001','{"role":"super_admin"}'),
 ('17600000-0000-0000-0000-000000000002','{}'),
 ('17600000-0000-0000-0000-000000000005','{}');
insert into public.profiles(id,display_name) select id,'Synthetic CSA176' from auth.users where id::text like '17600000-%' on conflict do nothing;
insert into auth.sessions(id,user_id,aal) values ('17600000-0000-0000-0000-000000000003','17600000-0000-0000-0000-000000000001','aal2');
insert into auth.sessions(id,user_id,aal) values ('17600000-0000-0000-0000-000000000006','17600000-0000-0000-0000-000000000005','aal2');
insert into public.user_roles(user_id,role_id) select '17600000-0000-0000-0000-000000000005',id from public.roles where code='super_admin';
create temporary table csa176_asset as
select (public.csa164_prepare_media_upload('17600000-0000-0000-0000-000000000005','17600000-0000-0000-0000-000000000006','aal2','17600000-0000-0000-0000-000000000007',
 (public.csa089_create_course('17600000-0000-0000-0000-000000000005','17600000-0000-0000-0000-000000000006','aal2','17600000-0000-0000-0000-000000000008','{"title":"Synthetic reservation","slug":"csa176-authorized-fixture"}') ->>'course_id')::uuid,
 null,'public_thumbnail','image/png',8,'csa176-policy')->>'asset_id')::uuid as id;
grant select on csa176_asset to service_role;
select set_config('request.jwt.claims','{"sub":"17600000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"super_admin"}}',true);
-- Actual invocation under browser roles, not just a catalog privilege assertion.
do $$
declare r record; principal text; state text; before_state jsonb:=pg_temp.csa176_state();
begin
 foreach principal in array array['anon','authenticated'] loop
  execute format('set local role %I',principal);
  for r in select * from pg_temp.csa176_calls loop
   state:=null;
   begin execute r.command using '17600000-0000-0000-0000-000000000001'::uuid,'17600000-0000-0000-0000-000000000003'::uuid,'aal2'::text,'17600000-0000-0000-0000-000000000002'::uuid;
   exception when others then state:=sqlstate;end;
   if state is distinct from '42501' then raise exception 'Public % invocation % expected 42501, got %',principal,r.name,state;end if;
  end loop;
  reset role;
 end loop;
 if before_state is distinct from pg_temp.csa176_state() then raise exception 'Public denied RPC changed protected state';end if;
end; $$;
select 'ok 1 - anonymous and authenticated direct RPC calls denied for all 13 boundaries';
-- Browser role metadata does not grant any current trusted staff authority.
 -- Use actual session changes and a real grant/revocation, keeping old aal2 claims.
do $$
declare r record; state text; scenario text; before_state jsonb; target uuid;
begin
 foreach scenario in array array['forged-metadata','MFA-downgrade','expired-session','deleted-session','revoked-role'] loop
  if scenario='MFA-downgrade' then update auth.sessions set aal='aal1' where id='17600000-0000-0000-0000-000000000003';end if;
  if scenario='expired-session' then update auth.sessions set aal='aal2',not_after=clock_timestamp()-interval '1 second' where id='17600000-0000-0000-0000-000000000003';end if;
  if scenario='deleted-session' then delete from auth.sessions where id='17600000-0000-0000-0000-000000000003';end if;
  if scenario='revoked-role' then
   insert into auth.sessions(id,user_id,aal) values ('17600000-0000-0000-0000-000000000003','17600000-0000-0000-0000-000000000001','aal2');
   insert into public.user_roles(user_id,role_id) select '17600000-0000-0000-0000-000000000001',id from public.roles where code='super_admin';
   update public.user_roles set revoked_at=clock_timestamp() where user_id='17600000-0000-0000-0000-000000000001';
  end if;
  before_state:=pg_temp.csa176_state();
  set local role service_role;
  for r in select * from pg_temp.csa176_calls loop
   state:=null;
   target:=case when r.name in ('media-get','media-finalize') then (select id from pg_temp.csa176_asset) else '17600000-0000-0000-0000-000000000002'::uuid end;
   begin execute r.command using '17600000-0000-0000-0000-000000000001'::uuid,'17600000-0000-0000-0000-000000000003'::uuid,'aal2'::text,target;
   exception when others then state:=sqlstate;end;
   if state is distinct from '42501' then raise exception '% invocation % expected 42501, got %',scenario,r.name,state;end if;
  end loop;
  reset role;
  if before_state is distinct from pg_temp.csa176_state() then raise exception '% denial changed protected state',scenario;end if;
 end loop;
end; $$;
select 'ok 2 - forged metadata, MFA downgrade, expired/deleted session and revoked role deny all 13 sensitive RPCs';
do $$
begin
 if exists(select 1 from public.user_roles where user_id='17600000-0000-0000-0000-000000000002')
 or exists(select 1 from public.courses where slug='csa176-denied')
 or exists(select 1 from public.csa061_role_audit where actor_id='17600000-0000-0000-0000-000000000001')
 or exists(select 1 from app_private.csa164_media_uploads where actor_id='17600000-0000-0000-0000-000000000001')
 or exists(select 1 from public.enrollments where user_id='17600000-0000-0000-0000-000000000002') then raise exception 'Denied calls created privileged state';end if;
end; $$;
select 'ok 3 - denied calls create no role grant, publication, role audit, media upload or enrollment';
rollback;
