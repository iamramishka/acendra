begin;
select '1..1';
do $$
declare buyer uuid:=gen_random_uuid(); other_user uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid();
 bs uuid:=gen_random_uuid(); os uuid:=gen_random_uuid(); ads uuid:=gen_random_uuid(); course uuid:=gen_random_uuid(); section uuid:=gen_random_uuid(); lesson uuid:=gen_random_uuid(); asset uuid:=gen_random_uuid();
 rid uuid:=gen_random_uuid(); legacy_rid uuid; license uuid:=gen_random_uuid(); policy uuid:='14000000-0000-4000-8000-000000000002'; response jsonb; path text; catalog_status text;
begin
 insert into auth.users(id) values(buyer),(other_user),(admin);
 insert into auth.sessions(id,user_id,aal,not_after) values(bs,buyer,'aal1',now()+interval '1 day'),(os,other_user,'aal1',now()+interval '1 day'),(ads,admin,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select admin,id from public.roles where code='super_admin';
 insert into public.courses(id,slug,title,price_minor,status,published_at) values(course,'pdf-test-'||course,'Synthetic PDF',100,'published',now());
 insert into public.course_sections(id,course_id,title,position,is_published) values(section,course,'Synthetic',0,true);
 insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values(lesson,section,'Synthetic','pdf',0,true);
 insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,checksum_sha256,validation_status,validated_at)
 values(asset,'course_pdf','supabase','course-pdfs','originals/'||asset||'/v1.pdf','application/pdf',100,repeat('a',64),'validated',clock_timestamp());
 insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values(lesson,asset,'primary',0);
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson); raise exception 'Unpaid access'; exception when insufficient_privilege then null; end;
 perform public.csa116_grant_admin(admin,ads,'aal2','pdf-grant',buyer,course,'Synthetic',null);
 -- A ready v1 object stays immutable and must not satisfy the branded v2 policy.
 path:='derivatives/'||asset||'/v1/'||license||'/14000000-0000-4000-8000-000000000001.pdf';
 insert into app_private.pdf_derivatives(actor_id,asset_id,asset_version,source_digest,license_id,policy_id,display_name,object_path,state,size_bytes,checksum_sha256,ready_at)
 select buyer,asset,1,repeat('a',64),license,'14000000-0000-4000-8000-000000000001',p.display_name,path,'ready',120,repeat('b',64),clock_timestamp()
 from public.profiles p where p.id=buyer returning id into legacy_rid;
 insert into storage.objects(bucket_id,name) values('course-pdfs',path);
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,legacy_rid); raise exception 'Legacy policy reused as branded'; exception when no_data_found then null; end;
 foreach catalog_status in array array['archived','draft'] loop
  update public.courses set status=catalog_status,published_at=null where id=course;
  response:=public.csa140_resolve_pdf(buyer,bs,'aal1',lesson);
  if response->>'state'<>'preparing' then raise exception 'Catalog change blocked preparing PDF'; end if;
  response:=public.csa148_claim_pdf_job();
  if response is null then raise exception 'Catalog change blocked PDF generation'; end if;
  -- Return this synthetic lease so the remaining lifecycle tests can claim it.
  update app_private.pdf_derivatives set lease_token=null,lease_until=null,attempts=0
   where id=(response->>'resource_id')::uuid;
 end loop;
 update public.courses set status='published',published_at=now() where id=course;
 response:=public.csa140_resolve_pdf(buyer,bs,'aal1',lesson);
 if response<>jsonb_build_object('state','preparing','lesson_id',lesson,'resource_id',null) then raise exception 'Original fallback'; end if;
 select id into rid from app_private.pdf_derivatives where actor_id=buyer and asset_id=asset and policy_id=policy;
 if rid is null then raise exception 'V2 reservation missing'; end if;
 if not exists(select 1 from app_private.pdf_derivatives where id=legacy_rid and state='ready' and checksum_sha256=repeat('b',64) and policy_id='14000000-0000-4000-8000-000000000001') then raise exception 'Legacy object changed'; end if;
 begin perform public.csa148_complete_pdf_job(rid,null,repeat('b',64),120); raise exception 'Null unclaimed lease accepted'; exception when invalid_parameter_value then null; end;
 update app_private.pdf_derivatives set attempts=3 where id=rid;
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson); raise exception 'Exhausted infinite preparing'; exception when object_not_in_prerequisite_state then null; end;
 update app_private.pdf_derivatives set attempts=0 where id=rid;
 response:=public.csa148_claim_pdf_job();
 if response->>'source_digest'<>repeat('a',64) or response->>'source_path'<>'originals/'||asset||'/v1.pdf' then raise exception 'Wrong work reservation'; end if;
 rid:=(response->>'resource_id')::uuid; path:=response->>'object_path';
 if path not like '%/'||policy::text||'.pdf' then raise exception 'Wrong immutable watermark policy'; end if;
 if public.csa148_claim_pdf_job() is not null then raise exception 'Active lease duplicated'; end if;
 begin perform public.csa148_complete_pdf_job(rid,(response->>'lease_token')::uuid,repeat('b',64),120); raise exception 'Missing output ready'; exception when object_not_in_prerequisite_state then null; end;
 insert into storage.objects(bucket_id,name) values('course-pdfs',path);
 begin perform public.csa148_complete_pdf_job(rid,gen_random_uuid(),repeat('b',64),120); raise exception 'Wrong worker lease'; exception when invalid_parameter_value then null; end;
 perform public.csa148_complete_pdf_job(rid,(response->>'lease_token')::uuid,repeat('b',64),120);
 response:=public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid);
 if response->>'resource_id'<>rid::text or response->>'object_path'<>path or response->>'bucket'<>'course-pdfs' then raise exception 'Wrong derivative'; end if;
 foreach catalog_status in array array['archived','draft'] loop
  update public.courses set status=catalog_status,published_at=null where id=course;
  response:=public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid);
  if response->>'state'<>'ready' or response->>'resource_id'<>rid::text then raise exception 'Catalog change blocked ready PDF'; end if;
 end loop;
 update public.courses set status='published',published_at=now() where id=course;
 update app_private.media_assets set validation_status='rejected' where id=asset;
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid); raise exception 'Rejected source served'; exception when no_data_found then null; end;
 update app_private.media_assets set validation_status='validated' where id=asset;
 begin update app_private.pdf_derivatives set size_bytes=121 where id=rid; raise exception 'Ready mutated'; exception when check_violation then null; end;
 perform public.csa116_grant_admin(admin,ads,'aal2','other-pdf-grant',other_user,course,'Synthetic',null);
 begin perform public.csa140_resolve_pdf(other_user,os,'aal1',lesson,rid); raise exception 'Cross user reuse'; exception when no_data_found then null; end;
 update auth.sessions set not_after=clock_timestamp()-interval '1 second' where id=bs;
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid); raise exception 'Expired session'; exception when insufficient_privilege then null; end;
 update auth.sessions set not_after=now()+interval '1 day' where id=bs;
 update auth.users set banned_until=now()+interval '1 day' where id=buyer;
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid); raise exception 'Banned access'; exception when insufficient_privilege then null; end;
 update auth.users set banned_until=null where id=buyer;
 update public.lessons set is_published=false where id=lesson;
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid); raise exception 'Unpublished lesson'; exception when no_data_found then null; end;
 update public.lessons set is_published=true where id=lesson;
 perform public.csa118_revoke_access(admin,ads,'aal2','pdf-revoke',buyer,course,null,'course','Synthetic restriction');
 begin perform public.csa140_resolve_pdf(buyer,bs,'aal1',lesson,rid); raise exception 'Revoked bytes'; exception when insufficient_privilege then null; end;
 if has_function_privilege('anon','public.csa140_resolve_pdf(uuid,uuid,text,uuid,uuid)','execute') or has_function_privilege('authenticated','public.csa140_resolve_pdf(uuid,uuid,text,uuid,uuid)','execute') then raise exception 'Browser RPC privilege'; end if;
 if has_table_privilege('service_role','app_private.pdf_derivatives','insert') or has_table_privilege('authenticated','app_private.pdf_derivatives','select') then raise exception 'Private table privilege'; end if;
end $$;
select 'ok 1 - current session, owned grant, publication, immutable personalized derivative and private privileges';
rollback;
