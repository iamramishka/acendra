-- CSA-173: catalog privileges plus current authority and course scope matrix.
begin;
create temporary sequence csa173_assertion;
grant usage,select on sequence csa173_assertion to anon,authenticated,service_role;
create function pg_temp.check_ok(ok boolean,label text) returns text language plpgsql as $$
begin if ok is distinct from true then raise exception 'Assertion failed: %',label;end if;
return 'ok '||nextval('pg_temp.csa173_assertion')||' - '||label;end;$$;
create function pg_temp.denied(command text,label text) returns text language plpgsql as $$
declare code text;begin begin execute command;exception when others then code:=sqlstate;end;
return pg_temp.check_ok(code='42501',label);end;$$;
-- Check actual deployed signatures, including every overload, not source strings.
do $$ declare f record; role_name text; n integer:=0;
begin
 for f in select p.oid,p.proname from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
 where ns.nspname='public' and p.proname=any(array['csa073_change_role','csa089_create_course','csa112_review_bank_transfer','csa116_grant_admin','csa118_revoke_access','csa118_release_restriction','csa158_dashboard_stats','csa172_financial_report','csa164_get_media_upload','csa164_prepare_media_upload','csa164_finalize_media_upload','csa165_publish_course','csa168_list_enrollments','csapaylist_admin_payment_list','csapaylist_admin_payment_detail']) loop
 n:=n+1;
 foreach role_name in array array['anon','authenticated'] loop
 if has_function_privilege(role_name,f.oid,'EXECUTE') then raise exception '% can invoke %',role_name,f.proname;end if;end loop;
 if not has_function_privilege('service_role',f.oid,'EXECUTE') then raise exception 'Missing trusted gateway: %',f.proname;end if;
 end loop;
 if n<>15 then raise exception 'Expected 15 admin RPC signatures, found %',n;end if;
end;$$;
select pg_temp.check_ok(true,'15 admin RPC signatures deny browser/guest and permit trusted gateway');
select pg_temp.check_ok(not has_function_privilege('service_role','public.csa061_change_role(uuid,text,uuid,text,text,text,uuid)','execute'),'legacy role core cannot bypass session gateway');
create temporary table csa173_actors(label text primary key,actor uuid,session uuid,aal text);
insert into csa173_actors values('super',gen_random_uuid(),gen_random_uuid(),'aal2'),('finance',gen_random_uuid(),gen_random_uuid(),'aal2'),('content',gen_random_uuid(),gen_random_uuid(),'aal1'),('student',gen_random_uuid(),gen_random_uuid(),'aal1');
insert into auth.users(id,raw_user_meta_data) select actor,'{"role":"super_admin"}'::jsonb from csa173_actors;
-- Populate the real composite type so Supabase's AAL enum and the native model both use the column's actual type.
insert into auth.sessions(id,user_id,aal,not_after)
 select s.id,s.user_id,s.aal,s.not_after from csa173_actors a
 cross join lateral jsonb_populate_record(null::auth.sessions,jsonb_build_object('id',a.session,'user_id',a.actor,'aal',a.aal,'not_after',clock_timestamp()+interval '1 day')) s;
insert into public.user_roles(user_id,role_id) select a.actor,r.id from csa173_actors a join public.roles r on r.code=case a.label when 'super' then 'super_admin' when 'finance' then 'finance_admin' when 'content' then 'content_manager' else 'student' end;
create temporary table csa173_courses as select gen_random_uuid() id, 'assigned' label union all select gen_random_uuid(),'foreign';
insert into public.courses(id,slug,title,price_minor,status) select id,'csa173-'||id,'Synthetic',100,'draft' from csa173_courses;
insert into public.course_staff(course_id,user_id,staff_role,assigned_by) select c.id,a.actor,'editor',s.actor from csa173_courses c,csa173_actors a,csa173_actors s where c.label='assigned' and a.label='content' and s.label='super';
create function pg_temp.dashboard(who text) returns jsonb language sql as $$select public.csa158_dashboard_stats(actor,session,aal,'last_30_days') from pg_temp.csa173_actors where label=who$$;
create function pg_temp.report(who text) returns jsonb language sql as $$select public.csa172_financial_report(actor,session,aal,'2026-01-01','2026-01-01','LKR') from pg_temp.csa173_actors where label=who$$;
select pg_temp.check_ok(pg_temp.dashboard('content')->>'total_courses'='1' and not pg_temp.dashboard('content') ?| array['confirmed_receipts','registered_students','active_enrollments','pending_bank_reviews'],'content dashboard returns assigned course counts only');
select pg_temp.check_ok(pg_temp.dashboard('finance') ? 'confirmed_receipts' and not pg_temp.dashboard('finance') ?| array['total_courses','registered_students','active_enrollments'],'finance dashboard omits course/student metrics');
select pg_temp.check_ok(pg_temp.dashboard('super') ?& array['total_courses','registered_students','active_enrollments','confirmed_receipts','pending_bank_reviews'],'super dashboard explicit metrics');
select pg_temp.denied($q$select pg_temp.dashboard('student')$q$,'student metadata cannot gain admin metrics');
select pg_temp.denied($q$select pg_temp.report('content')$q$,'content cannot read financial report');
select pg_temp.denied($q$select pg_temp.report('student')$q$,'student cannot read financial report');
select pg_temp.check_ok(pg_temp.report('finance')->>'currency_code'='LKR','finance can read bounded financial report');
create function pg_temp.media(who text,course_label text) returns void language sql as $$select app_private.csa164_authorize(a.actor,a.session,a.aal,c.id,null) from pg_temp.csa173_actors a,pg_temp.csa173_courses c where a.label=who and c.label=course_label$$;
select pg_temp.media('content','assigned');
select pg_temp.check_ok(true,'content can authorize assigned upload at aal1');
select pg_temp.denied($q$select pg_temp.media('content','foreign')$q$,'content cannot authorize foreign course');
select pg_temp.denied($q$select pg_temp.media('finance','assigned')$q$,'finance cannot authorize uploads');
select pg_temp.denied($q$select pg_temp.media('student','assigned')$q$,'student cannot authorize uploads');
select pg_temp.media('super','foreign');
select pg_temp.check_ok(true,'super authorizes unassigned course with aal2');
update public.course_staff set revoked_at=clock_timestamp() where user_id=(select actor from csa173_actors where label='content');
select pg_temp.denied($q$select pg_temp.media('content','assigned')$q$,'revoked course assignment immediately blocks upload');
select pg_temp.check_ok(pg_temp.dashboard('content')->>'total_courses'='0','revoked course assignment immediately removes counts');
-- Each state is tested using current database state with unchanged claims.
update auth.sessions set aal='aal1' where user_id=(select actor from csa173_actors where label='super');
select pg_temp.denied($q$select pg_temp.dashboard('super')$q$,'MFA downgrade defeats prior aal2 claim');
update auth.sessions set aal='aal2',not_after=clock_timestamp()-interval '1 second' where user_id=(select actor from csa173_actors where label='super');
select pg_temp.denied($q$select pg_temp.dashboard('super')$q$,'expired current session denied');
update auth.sessions set not_after=clock_timestamp()+interval '1 day' where user_id=(select actor from csa173_actors where label='super');
update auth.users set banned_until=clock_timestamp()+interval '1 day' where id=(select actor from csa173_actors where label='super');
select pg_temp.denied($q$select pg_temp.dashboard('super')$q$,'banned super admin denied');
update auth.users set banned_until=null,deleted_at=clock_timestamp() where id=(select actor from csa173_actors where label='super');
select pg_temp.denied($q$select pg_temp.dashboard('super')$q$,'deleted super admin denied');
update auth.users set deleted_at=null,is_anonymous=true where id=(select actor from csa173_actors where label='super');
select pg_temp.denied($q$select pg_temp.dashboard('super')$q$,'anonymous super admin denied');
update auth.users set is_anonymous=false where id=(select actor from csa173_actors where label='super');
update public.user_roles set revoked_at=clock_timestamp() where user_id=(select actor from csa173_actors where label='super');
select pg_temp.denied($q$select pg_temp.dashboard('super')$q$,'revoked role defeats old token');
select '1..'||last_value from pg_temp.csa173_assertion;
rollback;
