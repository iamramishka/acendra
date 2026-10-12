begin;
do $$
declare actor uuid:=gen_random_uuid(); manager uuid:=gen_random_uuid(); buyer uuid:=gen_random_uuid();
 ads uuid:=gen_random_uuid(); ms uuid:=gen_random_uuid(); course uuid:=gen_random_uuid(); section uuid:=gen_random_uuid(); lesson uuid:=gen_random_uuid(); asset uuid:=gen_random_uuid();
 stamp timestamptz; result jsonb; before_count bigint; grant_id uuid; invalid_asset uuid; variant text;
begin
 insert into auth.users(id) values(actor),(manager),(buyer);
 insert into public.profiles(id,display_name) values(actor,'Publisher'),(manager,'Manager'),(buyer,'Buyer') on conflict(id) do nothing;
 insert into auth.sessions(id,user_id,aal,not_after) values(ads,actor,'aal2',now()+interval '1 day'),(ms,manager,'aal1',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select actor,id from public.roles where code='super_admin';
 insert into public.user_roles(user_id,role_id) select manager,id from public.roles where code='content_manager';
 insert into public.courses(id,slug,title,description,short_description,price_minor) values(course,'publication-'||course,'Synthetic','Description','Summary',10000) returning updated_at into stamp;
 begin perform public.csa165_publish_course(manager,ms,'aal1',course,stamp,'publish','manager');raise exception 'manager published';exception when insufficient_privilege then null;end;
 begin perform public.csa165_publish_course(actor,ads,'aal1',course,stamp,'publish','weak');raise exception 'MFA bypass';exception when insufficient_privilege then null;end;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','empty');raise exception 'empty curriculum';exception when check_violation then null;end;
 insert into public.course_sections(id,course_id,title,position,is_published) values(section,course,'Section',0,true);
 insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values(lesson,section,'PDF','pdf',0,true);
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','missing');raise exception 'missing assets';exception when check_violation then null;end;
 insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,checksum_sha256,validation_status,validated_at)
 values(asset,'course_pdf','supabase','course-pdfs','originals/'||asset||'/v1.pdf','application/pdf',1000,repeat('a',64),'validated',clock_timestamp());
 insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values(lesson,asset,'primary',0);
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp-interval '1 second','publish','stale');raise exception 'stale overwrite';exception when serialization_failure then null;end;
 result:=public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','publish');
 if result->>'status'<>'published' or (select count(*) from app_private.csa165_publication_audit where course_id=course)<>1 then raise exception 'publication audit';end if;
 if (public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','publish')->>'replayed')::boolean is not true then raise exception 'replay';end if;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'unpublish','publish');raise exception 'changed replay';exception when serialization_failure then null;end;
 perform public.csa116_grant_admin(actor,ads,'aal2','publication-grant',buyer,course,'Complimentary test',null);
 if not app_private.csa117_has_access(buyer,course) then raise exception 'initial grant';end if;
 select updated_at into stamp from public.courses where id=course;
 result:=public.csa165_publish_course(actor,ads,'aal2',course,stamp,'unpublish','unpublish');
 if result->>'status'<>'draft' or not app_private.csa117_has_access(buyer,course) then raise exception 'unpublish revoked access';end if;
 select updated_at into stamp from public.courses where id=course;
 foreach variant in array array['path','provider','size','duplicate'] loop
  invalid_asset:=gen_random_uuid();
  insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,checksum_sha256,validation_status,validated_at)
  values(invalid_asset,'course_pdf',case when variant='provider' then 'other' else 'supabase' end,'course-pdfs',case when variant='path' then 'wrong.pdf' else 'originals/'||invalid_asset||'/v1.pdf' end,'application/pdf',case when variant='size' then 52428801 else 1000 end,repeat('b',64),'validated',clock_timestamp());
  if variant='duplicate' then insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values(lesson,invalid_asset,'extra',1);
  else update app_private.lesson_assets set media_asset_id=invalid_asset where lesson_id=lesson;end if;
  begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','bad-'||variant);raise exception 'unsafe PDF % published',variant;exception when check_violation then null;end;
  if variant='duplicate' then delete from app_private.lesson_assets where media_asset_id=invalid_asset;else update app_private.lesson_assets set media_asset_id=asset where lesson_id=lesson;end if;
 end loop;
 invalid_asset:=gen_random_uuid();
 insert into app_private.media_assets(id,asset_type,storage_provider,external_asset_id,mime_type,size_bytes,checksum_sha256,validation_status,validated_at)
 values(invalid_asset,'course_video','mux','SyntheticAsset','video/mp4',1000,repeat('c',64),'validated',clock_timestamp());
 update public.lessons set lesson_type='video' where id=lesson;
 update app_private.lesson_assets set media_asset_id=invalid_asset,usage='video' where lesson_id=lesson;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','no-mux-binding');raise exception 'unverified Mux published';exception when check_violation then null;end;
 update public.lessons set lesson_type='pdf' where id=lesson;
 update app_private.lesson_assets set media_asset_id=asset,usage='primary' where lesson_id=lesson;
 update app_private.media_assets set validation_status='rejected' where id=asset;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','rejected');raise exception 'rejected media';exception when check_violation then null;end;
 update app_private.media_assets set validation_status='validated' where id=asset;
 update public.lessons set lesson_type='text' where id=lesson;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','text');raise exception 'unimplemented text readiness';exception when check_violation then null;end;
 update public.lessons set lesson_type='pdf' where id=lesson;
 select count(*) into before_count from app_private.csa165_publication_audit;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','rollback');raise exception 'Injected rollback';exception when raise_exception then null;end;
 if (select status from public.courses where id=course)<>'draft' or (select count(*) from app_private.csa165_publication_audit)<>before_count then raise exception 'partial publication';end if;
 begin delete from app_private.csa165_publication_audit where course_id=course;raise exception 'audit deleted';exception when insufficient_privilege then null;end;
 update public.user_roles set revoked_at=now() where user_id=actor;
 begin perform public.csa165_publish_course(actor,ads,'aal2',course,stamp,'publish','publish');raise exception 'revoked replay';exception when insufficient_privilege then null;end;
 if has_function_privilege('authenticated','public.csa165_publish_course(uuid,uuid,text,uuid,timestamptz,text,text)','EXECUTE') or has_table_privilege('service_role','app_private.csa165_publication_audit','DELETE') then raise exception 'privilege leakage';end if;
end;$$;
select 'CSA165 publication/permissions/readiness/replay/audit/entitlement scenarios passed';
rollback;
