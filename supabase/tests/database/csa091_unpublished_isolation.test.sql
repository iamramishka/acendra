-- CSA-091: independent synthetic transaction, never dependent on seed.sql.
begin;
create temporary sequence csa091_assertion;
grant usage,select on sequence csa091_assertion to anon,authenticated;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok ' || nextval('pg_temp.csa091_assertion') || ' - ' || description;
end; $$;
create function pg_temp.denied(command text,description text) returns text language plpgsql as $$
declare actual text;
begin
 begin execute command; exception when others then actual:=sqlstate; end;
 return pg_temp.assert_ok(actual='42501',description);
end; $$;
insert into public.categories(id,name,slug,is_active) values
 ('09100000-0000-0000-0000-000000000001','Synthetic active','csa091-active',true),
 ('09100000-0000-0000-0000-000000000002','Synthetic inactive','csa091-inactive',false);
insert into public.courses(id,slug,title,price_minor,status,published_at) values
 ('09100000-0000-0000-0000-000000000011','csa091-published','Synthetic published',0,'published',now()),
 ('09100000-0000-0000-0000-000000000012','csa091-draft','Synthetic draft',0,'draft',null),
 ('09100000-0000-0000-0000-000000000013','csa091-archived','Synthetic archived',0,'archived',now());
insert into public.course_sections(id,course_id,title,position,is_published) values
 ('09100000-0000-0000-0000-000000000021','09100000-0000-0000-0000-000000000011','Published',0,true),
 ('09100000-0000-0000-0000-000000000022','09100000-0000-0000-0000-000000000011','Hidden',1,false),
 ('09100000-0000-0000-0000-000000000023','09100000-0000-0000-0000-000000000012','Draft parent',0,true),
 ('09100000-0000-0000-0000-000000000024','09100000-0000-0000-0000-000000000013','Archived parent',0,true);
insert into public.lessons(id,section_id,title,lesson_type,position,is_preview,is_published) values
 ('09100000-0000-0000-0000-000000000031','09100000-0000-0000-0000-000000000021','Published paid metadata','pdf',0,false,true),
 ('09100000-0000-0000-0000-000000000032','09100000-0000-0000-0000-000000000021','Hidden preview','text',1,true,false),
 ('09100000-0000-0000-0000-000000000033','09100000-0000-0000-0000-000000000022','Hidden section','video',0,true,true),
 ('09100000-0000-0000-0000-000000000034','09100000-0000-0000-0000-000000000023','Draft course','text',0,true,true),
 ('09100000-0000-0000-0000-000000000035','09100000-0000-0000-0000-000000000024','Archived course','image',0,true,true);
select set_config('request.jwt.claims','{"role":"anon","sub":"09100000-0000-0000-0000-000000000099","aal":"aal2","app_metadata":{"role":"super_admin"},"user_metadata":{"is_admin":true}}',true);
set local role anon;
select pg_temp.assert_ok((select count(*) from public.categories where id::text like '09100000-%')=1,'anon sees only active category');
select pg_temp.assert_ok((select count(*) from public.courses where id::text like '09100000-%')=1,'anon sees only published course');
select pg_temp.assert_ok((select count(*) from public.courses where id in ('09100000-0000-0000-0000-000000000012','09100000-0000-0000-0000-000000000013'))=0,'anon direct draft and archived IDs are hidden');
select pg_temp.assert_ok((select count(*) from public.course_sections where id::text like '09100000-%')=1,'anon sees published section only under published parent');
select pg_temp.assert_ok((select count(*) from public.lessons where id::text like '09100000-%')=1,'anon sees lesson metadata only with fully published ancestry');
select pg_temp.assert_ok((select count(*) from public.lessons where id='09100000-0000-0000-0000-000000000032')=0,'anon preview flag cannot expose unpublished lesson');
select pg_temp.denied('select created_by from public.courses','anon cannot read private creator identity');
select pg_temp.denied('insert into public.categories default values','anon cannot insert categories');
select pg_temp.denied('update public.categories set name=''forged''','anon cannot update categories');
select pg_temp.denied('delete from public.categories','anon cannot delete categories');
select pg_temp.denied('insert into public.courses default values','anon cannot insert courses');
select pg_temp.denied('update public.courses set title=''forged''','anon cannot update courses');
select pg_temp.denied('delete from public.courses','anon cannot delete courses');
select pg_temp.denied('insert into public.course_sections default values','anon cannot insert course_sections');
select pg_temp.denied('update public.course_sections set title=''forged''','anon cannot update course_sections');
select pg_temp.denied('delete from public.course_sections','anon cannot delete course_sections');
select pg_temp.denied('insert into public.lessons default values','anon cannot insert lessons');
select pg_temp.denied('update public.lessons set title=''forged''','anon cannot update lessons');
select pg_temp.denied('delete from public.lessons','anon cannot delete lessons');
reset role;
select set_config('request.jwt.claims','{"role":"authenticated","sub":"09100000-0000-0000-0000-000000000099","aal":"aal2","app_metadata":{"role":"super_admin"},"user_metadata":{"is_admin":true}}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*) from public.categories where id::text like '09100000-%')=1,'authenticated sees only active category');
select pg_temp.assert_ok((select count(*) from public.courses where id::text like '09100000-%')=1,'authenticated sees only published course');
select pg_temp.assert_ok((select count(*) from public.courses where id in ('09100000-0000-0000-0000-000000000012','09100000-0000-0000-0000-000000000013'))=0,'authenticated direct draft and archived IDs are hidden');
select pg_temp.assert_ok((select count(*) from public.course_sections where id::text like '09100000-%')=1,'authenticated sees published section only under published parent');
select pg_temp.assert_ok((select count(*) from public.lessons where id::text like '09100000-%')=1,'authenticated sees lesson metadata only with fully published ancestry');
select pg_temp.assert_ok((select count(*) from public.lessons where id='09100000-0000-0000-0000-000000000032')=0,'authenticated preview flag cannot expose unpublished lesson');
select pg_temp.denied('select created_by from public.courses','authenticated cannot read private creator identity');
select pg_temp.denied('insert into public.categories default values','authenticated cannot insert categories');
select pg_temp.denied('update public.categories set name=''forged''','authenticated cannot update categories');
select pg_temp.denied('delete from public.categories','authenticated cannot delete categories');
select pg_temp.denied('insert into public.courses default values','authenticated cannot insert courses');
select pg_temp.denied('update public.courses set title=''forged''','authenticated cannot update courses');
select pg_temp.denied('delete from public.courses','authenticated cannot delete courses');
select pg_temp.denied('insert into public.course_sections default values','authenticated cannot insert course_sections');
select pg_temp.denied('update public.course_sections set title=''forged''','authenticated cannot update course_sections');
select pg_temp.denied('delete from public.course_sections','authenticated cannot delete course_sections');
select pg_temp.denied('insert into public.lessons default values','authenticated cannot insert lessons');
select pg_temp.denied('update public.lessons set title=''forged''','authenticated cannot update lessons');
select pg_temp.denied('delete from public.lessons','authenticated cannot delete lessons');
reset role;
select pg_temp.assert_ok(not exists(select 1 from information_schema.columns where table_schema='public' and table_name='lessons' and column_name in ('body','content','content_html','storage_path','signed_url','playback_token')),'public lesson metadata has no protected payload fields');
select pg_temp.assert_ok((select count(*) from public.courses where id::text like '09100000-%')=3,'denied requests preserve unpublished rows');
select pg_temp.assert_ok((select count(*) from public.course_sections where id::text like '09100000-%')=4,'denied requests preserve curriculum');
select pg_temp.assert_ok((select count(*) from public.lessons where id::text like '09100000-%')=5,'denied requests preserve all lesson metadata');
-- Browser authority remains public-only even for a real current administrator.
insert into auth.users(id,raw_user_meta_data) values ('09100000-0000-0000-0000-000000000099','{}');
insert into public.profiles(id,display_name) values ('09100000-0000-0000-0000-000000000099','Synthetic CSA091 admin') on conflict(id) do nothing;
insert into public.user_roles(user_id,role_id) select '09100000-0000-0000-0000-000000000099',id from public.roles where code='super_admin';
select set_config('request.jwt.claims','{"role":"authenticated","sub":"09100000-0000-0000-0000-000000000099","aal":"aal2","app_metadata":{"role":"super_admin"}}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*) from public.courses where id::text like '09100000-%')=1,'real administrator browser cannot read unpublished catalog');
select pg_temp.assert_ok((select count(*) from public.lessons where id::text like '09100000-%')=1,'real administrator browser cannot read unpublished curriculum');
reset role;
update public.user_roles set revoked_at=now() where user_id='09100000-0000-0000-0000-000000000099';
set local role authenticated;
select pg_temp.assert_ok((select count(*) from public.courses where id::text like '09100000-%')=1,'revoked administrator old claims do not expose unpublished catalog');
select pg_temp.assert_ok((select count(*) from public.lessons where id::text like '09100000-%')=1,'revoked administrator old claims do not expose unpublished curriculum');
reset role;
select '1..' || last_value from pg_temp.csa091_assertion;
rollback;


