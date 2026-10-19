begin;
create temporary sequence csa267_assertion;
create function pg_temp.assert_ok(c boolean,d text) returns text language plpgsql as $$begin if c is distinct from true then raise exception 'Assertion failed: %',d;end if;return 'ok '||nextval('pg_temp.csa267_assertion')||' - '||d;end;$$;
create function pg_temp.expect_error(q text,s text,d text) returns text language plpgsql as $$declare actual text;begin begin execute q;exception when others then actual:=sqlstate;end;return pg_temp.assert_ok(actual=s,d);end;$$;
insert into auth.users(id) values('26700000-0000-0000-0000-000000000001'),('26700000-0000-0000-0000-000000000002');
insert into public.profiles(id,display_name) select id,'Synthetic' from auth.users where id::text like '267%' on conflict do nothing;
insert into auth.sessions(id,user_id,aal,not_after) values('26700000-0000-0000-0000-000000000011','26700000-0000-0000-0000-000000000001','aal1',now()+interval '1 day'),('26700000-0000-0000-0000-000000000012','26700000-0000-0000-0000-000000000002','aal1',now()+interval '1 day');
insert into public.user_roles(user_id,role_id) select '26700000-0000-0000-0000-000000000001',id from public.roles where code='content_manager';
insert into public.courses(id,slug,title,price_minor) values('26700000-0000-0000-0000-000000000003','synthetic-csa267','Synthetic',0);
insert into public.course_staff(course_id,user_id,staff_role) values('26700000-0000-0000-0000-000000000003','26700000-0000-0000-0000-000000000001','owner');
insert into public.course_sections(id,course_id,title,position) values('26700000-0000-0000-0000-000000000004','26700000-0000-0000-0000-000000000003','Synthetic',0);
insert into public.lessons(id,section_id,title,lesson_type,position) values('26700000-0000-0000-0000-000000000005','26700000-0000-0000-0000-000000000004','Synthetic','pdf',0);

-- Existing audit producers need not have an upload reservation. Such evidence
-- must neither fail the unrelated transaction nor attach uninspected artwork.
insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,uploaded_by)
 values('26700000-0000-0000-0000-000000000099','public_thumbnail','supabase','course-media',
 '26700000-0000-0000-0000-000000000003/thumbnails/26700000-0000-0000-0000-000000000099.png',
 'image/png',8,'26700000-0000-0000-0000-000000000001');
insert into app_private.csa164_media_validation_audit(asset_id,actor_id,checksum_sha256,policy_reference)
 values('26700000-0000-0000-0000-000000000099','26700000-0000-0000-0000-000000000001',repeat('a',64),'synthetic-policy');
select pg_temp.assert_ok(not exists(select 1 from app_private.course_artwork),'unreserved audit cannot select artwork');

create temporary table thumbnail as select public.csa164_prepare_media_upload('26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1','26700000-0000-0000-0000-000000000097','26700000-0000-0000-0000-000000000003',null,'public_thumbnail','image/png',8,'csa267-media-v1') as data;
select pg_temp.assert_ok(public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003') is null,'pending cannot deliver');
select pg_temp.assert_ok(not exists(select 1 from app_private.course_artwork),'pending never attaches');
select pg_temp.assert_ok((public.csa164_finalize_media_upload('26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1',(select (data->>'asset_id')::uuid from thumbnail),repeat('c',64),8,'image/png','csa267-media-v1')->>'status')='validated','trusted finalization');
select pg_temp.assert_ok((select asset_id=(select (data->>'asset_id')::uuid from thumbnail) from app_private.course_artwork),'validation atomically selects artwork');
select pg_temp.assert_ok(public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003') is null,'draft artwork not public');
select pg_temp.assert_ok(public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003','26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1')->>'asset_id'=(select data->>'asset_id' from thumbnail),'current assigned manager can preview draft');
select pg_temp.expect_error($q$select public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003','26700000-0000-0000-0000-000000000002','26700000-0000-0000-0000-000000000012','aal1')$q$,'42501','student cannot preview draft');
update public.course_staff set revoked_at=clock_timestamp() where user_id='26700000-0000-0000-0000-000000000001';
select pg_temp.expect_error($q$select public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003','26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1')$q$,'42501','revoked manager cannot preview');
update public.course_staff set revoked_at=null where user_id='26700000-0000-0000-0000-000000000001';
update public.courses set status='published',published_at=clock_timestamp() where id='26700000-0000-0000-0000-000000000003';
select pg_temp.assert_ok(public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003')->>'asset_id'=(select data->>'asset_id' from thumbnail),'only published validated artwork resolves publicly');
update app_private.media_assets set validation_status='rejected' where id=(select (data->>'asset_id')::uuid from thumbnail);
select pg_temp.assert_ok(public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003') is null,'rejected asset ceases delivery');
update app_private.media_assets set validation_status='validated' where id=(select (data->>'asset_id')::uuid from thumbnail);
update public.courses set status='draft',published_at=null where id='26700000-0000-0000-0000-000000000003';
select pg_temp.assert_ok(public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003') is null,'unpublishing ceases public delivery');
select pg_temp.assert_ok(not has_function_privilege(r,'public.csa267_resolve_artwork(uuid,uuid,uuid,text)','EXECUTE'),'resolver service only '||r) from unnest(array['anon','authenticated']) roles(r);
select pg_temp.assert_ok(not has_table_privilege(r,'app_private.course_artwork','SELECT'),'private association '||r) from unnest(array['anon','authenticated','service_role']) roles(r);
select pg_temp.assert_ok(not exists(select 1 from app_private.lesson_assets where media_asset_id=(select (data->>'asset_id')::uuid from thumbnail)),'thumbnail cannot become paid lesson content');

create temporary table replacement as select public.csa164_prepare_media_upload('26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1','26700000-0000-0000-0000-000000000096','26700000-0000-0000-0000-000000000003',null,'public_thumbnail','image/png',8,'csa267-media-v1') as data;
create function pg_temp.fail_artwork() returns trigger language plpgsql as $$begin raise exception 'Injected attachment failure';end;$$;
create trigger csa267_test_failure before insert or update on app_private.course_artwork for each row execute function pg_temp.fail_artwork();
select pg_temp.expect_error(format($q$select public.csa164_finalize_media_upload('26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1',%L,%L,8,'image/png','csa267-media-v1')$q$,(select data->>'asset_id' from replacement),repeat('d',64)),'P0001','attachment failure rolls back validation');
select pg_temp.assert_ok((select validation_status='pending' from app_private.media_assets where id=(select (data->>'asset_id')::uuid from replacement)) and not exists(select 1 from app_private.csa164_media_validation_audit where asset_id=(select (data->>'asset_id')::uuid from replacement)),'attachment and audit are atomic');
drop trigger csa267_test_failure on app_private.course_artwork;
select pg_temp.assert_ok((public.csa164_finalize_media_upload('26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1',(select (data->>'asset_id')::uuid from replacement),repeat('d',64),8,'image/png','csa267-media-v1')->>'status')='validated','trusted finalization');
select pg_temp.assert_ok((public.csa164_finalize_media_upload('26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1',(select (data->>'asset_id')::uuid from thumbnail),repeat('c',64),8,'image/png','csa267-media-v1')->>'status')='validated','trusted finalization');
select pg_temp.assert_ok((select asset_id=(select (data->>'asset_id')::uuid from replacement) from app_private.course_artwork),'old finalization replay cannot restore superseded artwork');

update storage.buckets set public=true where id='course-media';
select pg_temp.expect_error($q$select public.csa267_resolve_artwork('26700000-0000-0000-0000-000000000003','26700000-0000-0000-0000-000000000001','26700000-0000-0000-0000-000000000011','aal1')$q$,'42501','public bucket drift denied');
select '1..'||last_value from pg_temp.csa267_assertion;
rollback;
