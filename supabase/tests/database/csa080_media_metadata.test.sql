-- Synthetic transactional TAP; full CSA077/078 schema dependency replay required.
begin;
create temporary sequence csa080_assertion;
grant usage,select on sequence csa080_assertion to anon,authenticated,service_role;
create function pg_temp.assert_ok(condition boolean,description text)
returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok '||nextval('pg_temp.csa080_assertion')||' - '||description;
end;
$$;
create function pg_temp.expect_error(command text,expected_state text,description text)
returns text language plpgsql as $$
declare actual_state text;
begin
 begin execute command; exception when others then actual_state:=sqlstate; end;
 return pg_temp.assert_ok(actual_state=expected_state,description);
end;
$$;
insert into auth.users(id) values('08000000-0000-0000-0000-000000000001');
insert into public.profiles(id,display_name) values('08000000-0000-0000-0000-000000000001','Synthetic uploader')
 on conflict(id) do update set display_name=excluded.display_name;
insert into public.courses(id,slug,title,price_minor) values
 ('08000000-0000-0000-0000-000000000002','csa080-synthetic','Synthetic media course',0);
insert into public.course_sections(id,course_id,title,position) values
 ('08000000-0000-0000-0000-000000000003','08000000-0000-0000-0000-000000000002','Synthetic section',0);
insert into public.lessons(id,section_id,title,lesson_type,position) values
 ('08000000-0000-0000-0000-000000000004','08000000-0000-0000-0000-000000000003','Synthetic lesson','pdf',0),
 ('08000000-0000-0000-0000-000000000005','08000000-0000-0000-0000-000000000003','Other lesson','video',1);
insert into app_private.media_assets(id,asset_type,storage_provider,uploaded_by) values
 ('08000000-0000-0000-0000-000000000006','course_pdf','supabase','08000000-0000-0000-0000-000000000001');
select pg_temp.assert_ok((select validation_status='pending' and validated_at is null and content_version=1 and created_at is not null
 from app_private.media_assets where id='08000000-0000-0000-0000-000000000006'),'new assets cannot appear validated');
select pg_temp.expect_error(format('update app_private.media_assets set %I=%s where id=%L',col,val,'08000000-0000-0000-0000-000000000006'),'23514',description)
 from (values
 ('asset_type',quote_literal('audio'),'unsupported asset type'),
 ('storage_provider',quote_literal(chr(9)||' '),'blank provider'),
 ('size_bytes','-1','negative size'),
 ('checksum_sha256',quote_literal('abc'),'invalid digest'),
 ('checksum_sha256',quote_literal(repeat('A',64)),'noncanonical digest'),
 ('content_version','0','invalid version'),
 ('validation_status',quote_literal('ready'),'unsupported readiness state'),
 ('validation_status',quote_literal('validated'),'uninspected asset cannot become validated'),
 ('bucket_name',quote_literal('private-files'),'incomplete storage reference'),
 ('deleted_at','now()-interval ''1 day''','deletion before creation')
 ) as cases(col,val,description);
select pg_temp.expect_error($q$update app_private.media_assets set uploaded_by='08000000-0000-0000-0000-000000000099' where id='08000000-0000-0000-0000-000000000006'$q$,'23503','unknown uploader rejected');
-- Each mandatory readiness input is tested independently.
update app_private.media_assets set bucket_name='private-files',object_path='synthetic/original-v1.pdf',
 mime_type='application/pdf',size_bytes=0,checksum_sha256=repeat('a',64)
 where id='08000000-0000-0000-0000-000000000006';
select pg_temp.expect_error($q$update app_private.media_assets set validation_status='validated' where id='08000000-0000-0000-0000-000000000006'$q$,'23514','validation marker required');
select pg_temp.expect_error(format('update app_private.media_assets set validation_status=%L,validated_at=now(),%s where id=%L','validated',missing,'08000000-0000-0000-0000-000000000006'),'23514','validated asset requires '||description)
 from (values ('mime_type=null','MIME'),('size_bytes=null','size'),('checksum_sha256=null','digest'),
 ('bucket_name=null,object_path=null','storage reference')) as cases(missing,description);
update app_private.media_assets set bucket_name='private-files',object_path='synthetic/original-v1.pdf',
 mime_type='application/pdf',size_bytes=0,checksum_sha256=repeat('a',64),
 validated_at=now(),validation_status='validated'
 where id='08000000-0000-0000-0000-000000000006';
select pg_temp.assert_ok((select validation_status='validated' and size_bytes=0 from app_private.media_assets
 where id='08000000-0000-0000-0000-000000000006'),'complete validated metadata accepted');
select pg_temp.expect_error(format('update app_private.media_assets set %I=%s where id=%L',col,val,'08000000-0000-0000-0000-000000000006'),'23514','validated identity immutable: '||col)
 from (values
 ('asset_type',quote_literal('other')),('storage_provider',quote_literal('other')),
 ('bucket_name',quote_literal('other-bucket')),('object_path',quote_literal('replacement.pdf')),
 ('external_asset_id',quote_literal('external-new')),('mime_type',quote_literal('image/png')),
 ('size_bytes','1'),('checksum_sha256',quote_literal(repeat('b',64))),('content_version','2'),
 ('validated_at','null'),('created_at','now()-interval ''1 day'''),('uploaded_by','null')
 ) as cases(col,val);
update app_private.media_assets set validation_status='rejected' where id='08000000-0000-0000-0000-000000000006';
select pg_temp.expect_error($q$update app_private.media_assets set validation_status='pending',validated_at=null,checksum_sha256=repeat('b',64)
 where id='08000000-0000-0000-0000-000000000006'$q$,'23514','status reset cannot erase validation and rewrite identity');
update app_private.media_assets set deleted_at=now() where id='08000000-0000-0000-0000-000000000006';
select pg_temp.expect_error($q$update app_private.media_assets set validation_status='validated'
 where id='08000000-0000-0000-0000-000000000006'$q$,'23514','deleted asset cannot be marked validated');
insert into app_private.media_assets(id,asset_type,storage_provider,external_asset_id,mime_type,size_bytes,checksum_sha256,content_version,validated_at,validation_status)
 values('08000000-0000-0000-0000-000000000007','course_video','synthetic-video','synthetic-version-2','video/mp4',100,repeat('c',64),2,now(),'validated');
select pg_temp.assert_ok((select content_version=2 from app_private.media_assets where id='08000000-0000-0000-0000-000000000007'),'replacement creates independently validated asset version');
insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values
 ('08000000-0000-0000-0000-000000000004','08000000-0000-0000-0000-000000000007','main',0),
 ('08000000-0000-0000-0000-000000000005','08000000-0000-0000-0000-000000000007','main',0);
select pg_temp.assert_ok((select count(*)=2 from app_private.lesson_assets where media_asset_id='08000000-0000-0000-0000-000000000007'),'same position valid in distinct lessons');
select pg_temp.expect_error($q$insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values
 ('08000000-0000-0000-0000-000000000004','08000000-0000-0000-0000-000000000006','support',0)$q$,'23505','duplicate position rejected');
select pg_temp.expect_error($q$insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values
 ('08000000-0000-0000-0000-000000000004','08000000-0000-0000-0000-000000000007','main',1)$q$,'23505','duplicate usage association rejected');
select pg_temp.expect_error(format('update app_private.lesson_assets set %I=%s where lesson_id=%L',col,val,'08000000-0000-0000-0000-000000000004'),expected,description)
 from (values
 ('position','-1','23514','negative association position'),
 ('usage',quote_literal(chr(9)||chr(10)),'23514','whitespace-only usage'),
 ('lesson_id',quote_literal('08000000-0000-0000-0000-000000000099'),'23503','unknown lesson'),
 ('media_asset_id',quote_literal('08000000-0000-0000-0000-000000000099'),'23503','unknown asset'),
 ('lesson_id','null','23502','lesson required'),('media_asset_id','null','23502','asset required')
 ) as cases(col,val,expected,description);
select pg_temp.expect_error($q$delete from public.lessons where id='08000000-0000-0000-0000-000000000004'$q$,'23503','lesson cannot cascade media association');
select pg_temp.expect_error($q$delete from app_private.media_assets where id='08000000-0000-0000-0000-000000000007'$q$,'23503','asset cannot cascade association');
select pg_temp.expect_error($q$delete from public.profiles where id='08000000-0000-0000-0000-000000000001'$q$,'23503','uploader cannot cascade media evidence');
select pg_temp.assert_ok(to_regclass('public.media_assets') is null and to_regclass('public.lesson_assets') is null,'private metadata has no public table alias');
select pg_temp.assert_ok((select count(*)=2 from pg_class where oid in ('app_private.media_assets'::regclass,'app_private.lesson_assets'::regclass) and relrowsecurity),'private tables use RLS');
select pg_temp.assert_ok(not has_function_privilege(r,'app_private.csa080_preserve_validated_identity()','EXECUTE'),r||' cannot invoke identity helper')
 from unnest(array['anon','authenticated','service_role']) r;
select '1..'||last_value from pg_temp.csa080_assertion;
rollback;
