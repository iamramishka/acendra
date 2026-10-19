begin;
select '1..1';
do $$
declare adm uuid:=gen_random_uuid(); mgr uuid:=gen_random_uuid(); stu uuid:=gen_random_uuid(); fin uuid:=gen_random_uuid();
 ads uuid:=gen_random_uuid(); ms uuid:=gen_random_uuid(); ss uuid:=gen_random_uuid(); fs uuid:=gen_random_uuid();
 cid uuid:=gen_random_uuid(); foreign_course uuid:=gen_random_uuid(); section1 uuid:=gen_random_uuid(); section2 uuid:=gen_random_uuid();
 lesson1 uuid:=gen_random_uuid(); lesson2 uuid:=gen_random_uuid(); category uuid:=gen_random_uuid(); request uuid:=gen_random_uuid();
 metadata jsonb; payload jsonb; result jsonb; repeated jsonb; rev timestamptz; oldrev timestamptz; n integer;
begin
 insert into auth.users(id,email) values(adm,'admin@synthetic.test'),(mgr,'manager@synthetic.test'),(stu,'student@synthetic.test'),(fin,'finance@synthetic.test');
 insert into auth.sessions(id,user_id,aal,not_after) values(ads,adm,'aal2',now()+interval '1 day'),(ms,mgr,'aal1',now()+interval '1 day'),(ss,stu,'aal1',now()+interval '1 day'),(fs,fin,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select adm,id from public.roles where code='super_admin';
 insert into public.user_roles(user_id,role_id) select mgr,id from public.roles where code='content_manager';
 insert into public.user_roles(user_id,role_id) select fin,id from public.roles where code='finance_admin';
 insert into public.categories(id,name,slug) values(category,'Category','csa268-'||category);
 metadata:=jsonb_build_object('title','Test course','slug','csa268-'||cid,'category_id',category,'short_description','Summary','description','Full public description','price_minor','12345','currency_code','LKR');

 -- Actual persistent create; clients may supply identity, never authority/status.
 result:=public.csa268_manage_course(mgr,ms,'aal1','create',cid,null,request,metadata);
 rev:=(result->>'updated_at')::timestamptz;
 if result->>'course_id'<>cid::text or (select price_minor from public.courses where id=cid)<>12345 or
  (select status from public.courses where id=cid)<>'draft' or not exists(select 1 from public.course_staff where course_id=cid and user_id=mgr and revoked_at is null) then raise exception 'Persistent exact-price draft creation failed';end if;
 repeated:=public.csa268_manage_course(mgr,ms,'aal1','create',cid,null,request,metadata);
 if repeated->>'replayed'<>'true' or (select count(*) from app_private.csa268_authoring_audit where course_id=cid)<>1 then raise exception 'Idempotent create duplicated audit';end if;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','create',cid,null,request,metadata||'{"title":"Different"}');raise exception 'Changed replay accepted';exception when serialization_failure then null;end;

 result:=public.csa268_manage_course(mgr,ms,'aal1','get',cid,null,null,'{}');
 if result->'course'->>'price_minor'<>'12345' or result->'course'->>'slug'<>metadata->>'slug' or result->'course'->>'category_id'<>category::text or jsonb_array_length(result->'categories')<1 then raise exception 'Editor detail contract lost metadata';end if;
 if result::text like '%object_path%' or result::text like '%service_role%' then raise exception 'Private fields leaked';end if;
 begin perform public.csa268_manage_course(stu,ss,'aal1','get',cid,null,null,'{}');raise exception 'Student read accepted';exception when insufficient_privilege then null;end;
 begin perform public.csa268_manage_course(fin,fs,'aal2','get',cid,null,null,'{}');raise exception 'Finance authoring accepted';exception when insufficient_privilege then null;end;
 begin perform public.csa268_manage_course(adm,ads,'aal1','get',cid,null,null,'{}');raise exception 'Admin without MFA accepted';exception when insufficient_privilege then null;end;
 begin perform public.csa268_manage_course(mgr,ss,'aal1','get',cid,null,null,'{}');raise exception 'Foreign session accepted';exception when insufficient_privilege then null;end;
 insert into public.courses(id,title,slug,price_minor) values(foreign_course,'Other','csa268-'||foreign_course,0);
 begin perform public.csa268_manage_course(mgr,ms,'aal1','get',foreign_course,null,null,'{}');raise exception 'Unassigned course readable';exception when insufficient_privilege then null;end;

 -- An update uses the user's original microsecond revision, not a refetch.
 oldrev:=rev;
 result:=public.csa268_manage_course(mgr,ms,'aal1','update',cid,rev,gen_random_uuid(),metadata||'{"title":"Saved title","price_minor":"9223372036854775807"}');
 rev:=(result->>'updated_at')::timestamptz;
 if rev<=oldrev or (select title from public.courses where id=cid)<>'Saved title' or (select price_minor from public.courses where id=cid)<>9223372036854775807 then raise exception 'Metadata update lost price or revision';end if;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','update',cid,oldrev,gen_random_uuid(),metadata);raise exception 'Stale metadata overwrote current record';exception when serialization_failure then null;end;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','update',cid,rev,gen_random_uuid(),metadata||'{"status":"published"}');raise exception 'Client published through metadata';exception when invalid_parameter_value then null;end;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','update',cid,rev,gen_random_uuid(),metadata||'{"price_minor":"1.23"}');raise exception 'Fractional minor units accepted';exception when invalid_parameter_value then null;end;

 result:=public.csa268_manage_course(mgr,ms,'aal1','upsert_section',cid,rev,gen_random_uuid(),jsonb_build_object('id',section1,'title','First','position',0,'is_published',true)); rev:=(result->>'updated_at')::timestamptz;
 result:=public.csa268_manage_course(mgr,ms,'aal1','upsert_section',cid,rev,gen_random_uuid(),jsonb_build_object('id',section2,'title','Second','position',1,'is_published',false)); rev:=(result->>'updated_at')::timestamptz;
 payload:=jsonb_build_object('id',lesson1,'section_id',section2,'title','Image lesson','description','Safe metadata only','lesson_type','image','position',0,'is_preview',false,'is_published',false,'duration_seconds',null);
 result:=public.csa268_manage_course(mgr,ms,'aal1','upsert_lesson',cid,rev,gen_random_uuid(),payload); rev:=(result->>'updated_at')::timestamptz;
 result:=public.csa268_manage_course(mgr,ms,'aal1','upsert_lesson',cid,rev,gen_random_uuid(),payload||jsonb_build_object('id',lesson2,'title','PDF lesson','lesson_type','pdf','position',1)); rev:=(result->>'updated_at')::timestamptz;
 if (select section_id from public.lessons where id=lesson1)<>section2 then raise exception 'Lesson saved in wrong section';end if;
 result:=public.csa268_manage_course(mgr,ms,'aal1','upsert_lesson',cid,rev,gen_random_uuid(),payload||'{"title":"Edited image","is_preview":true}'); rev:=(result->>'updated_at')::timestamptz;
 if (select title from public.lessons where id=lesson1)<>'Edited image' or (select position from public.lessons where id=lesson2)<>1 then raise exception 'Lesson edit reset order';end if;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','upsert_lesson',cid,rev,gen_random_uuid(),payload||jsonb_build_object('section_id',section1));raise exception 'Existing lesson reparented';exception when insufficient_privilege then null;end;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','delete_section',foreign_course,rev,gen_random_uuid(),jsonb_build_object('id',section2));raise exception 'Foreign-course deletion accepted';exception when insufficient_privilege then null;end;

 -- Complete permutations swap unique positions atomically.
 result:=public.csa268_manage_course(mgr,ms,'aal1','reorder_sections',cid,rev,gen_random_uuid(),jsonb_build_object('ids',jsonb_build_array(section2,section1))); rev:=(result->>'updated_at')::timestamptz;
 result:=public.csa268_manage_course(mgr,ms,'aal1','reorder_lessons',cid,rev,gen_random_uuid(),jsonb_build_object('section_id',section2,'ids',jsonb_build_array(lesson2,lesson1))); rev:=(result->>'updated_at')::timestamptz;
 if (select position from public.course_sections where id=section2)<>0 or (select position from public.lessons where id=lesson2)<>0 then raise exception 'Atomic swap failed';end if;
 -- Legacy sparse positions, including INT_MAX, must not overflow a temporary
 -- max+size strategy or collide with the final low positions.
 update public.course_sections set position=2147483647 where id=section1;
 update public.course_sections set position=2 where id=section2;
 result:=public.csa268_manage_course(mgr,ms,'aal1','reorder_sections',cid,rev,gen_random_uuid(),jsonb_build_object('ids',jsonb_build_array(section2,section1))); rev:=(result->>'updated_at')::timestamptz;
 if (select position from public.course_sections where id=section2)<>0 or (select position from public.course_sections where id=section1)<>1 then raise exception 'Sparse boundary reorder failed';end if;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','reorder_sections',cid,rev,gen_random_uuid(),jsonb_build_object('ids',jsonb_build_array(section1)));raise exception 'Partial ordering accepted';exception when serialization_failure then null;end;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','reorder_sections',cid,rev,gen_random_uuid(),jsonb_build_object('ids',jsonb_build_array(section1,section1)));raise exception 'Duplicate ordering accepted';exception when invalid_parameter_value then null;end;
 result:=public.csa268_manage_course(mgr,ms,'aal1','curriculum',cid,null,null,'{}');
 if result->'sections'->0->>'id'<>section2::text or result->'sections'->0->'lessons'->0->>'id'<>lesson2::text then raise exception 'Curriculum read order wrong';end if;

 -- Database and privilege invariants remain authoritative.
 select count(*) into n from app_private.csa268_authoring_audit where course_id=cid;
 begin update app_private.csa268_authoring_audit set action='fake' where course_id=cid;raise exception 'Audit changed';exception when insufficient_privilege then null;end;
 if has_function_privilege('authenticated','public.csa268_manage_course(uuid,uuid,text,text,uuid,timestamptz,uuid,jsonb)','EXECUTE') or has_function_privilege('anon','public.csa268_manage_course(uuid,uuid,text,text,uuid,timestamptz,uuid,jsonb)','EXECUTE') then raise exception 'Client can bypass verified Edge';end if;
 if not has_function_privilege('service_role','public.csa268_manage_course(uuid,uuid,text,text,uuid,timestamptz,uuid,jsonb)','EXECUTE') or has_table_privilege('service_role','app_private.csa268_authoring_audit','UPDATE') then raise exception 'RPC/audit grants wrong';end if;
 update public.courses set status='published',published_at=clock_timestamp() where id=cid returning updated_at into rev;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','delete_lesson',cid,rev,gen_random_uuid(),jsonb_build_object('id',lesson1));raise exception 'Published curriculum deleted';exception when object_not_in_prerequisite_state then null;end;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','update',cid,rev,gen_random_uuid(),metadata||'{"description":""}');raise exception 'Published metadata readiness removed';exception when check_violation then null;end;
 begin perform public.csa165_publish_course(mgr,ms,'aal1',cid,rev,'unpublish','csa268-manager');raise exception 'Manager published/unpublished';exception when insufficient_privilege then null;end;
 result:=public.csa165_publish_course(adm,ads,'aal2',cid,rev,'unpublish','csa268-admin'); rev:=(result->>'updated_at')::timestamptz;
 begin perform public.csa165_publish_course(adm,ads,'aal2',cid,rev,'publish','csa268-unready');raise exception 'Unready course published';exception when check_violation then null;end;
 -- Unpublishing a course preserves paid delivery. Editing its curriculum must
 -- not hide formerly published resources from an existing student either.
 begin
  insert into public.enrollments(user_id,course_id,status,granted_at) values(stu,cid,'active',clock_timestamp());
  update public.lessons set is_published=true where id=lesson1;
  begin perform public.csa268_manage_course(mgr,ms,'aal1','upsert_section',cid,rev,gen_random_uuid(),jsonb_build_object('id',section1,'title','First','position',1,'is_published',false));raise exception 'Purchased section hidden';exception when foreign_key_violation then null;end;
  begin perform public.csa268_manage_course(mgr,ms,'aal1','upsert_lesson',cid,rev,gen_random_uuid(),payload||jsonb_build_object('position',1,'is_published',false));raise exception 'Purchased lesson hidden';exception when foreign_key_violation then null;end;
  begin perform public.csa268_manage_course(mgr,ms,'aal1','delete_lesson',cid,rev,gen_random_uuid(),jsonb_build_object('id',lesson1));raise exception 'Purchased lesson deleted';exception when foreign_key_violation then null;end;
  raise exception using errcode='P0268',message='Rollback synthetic retention fixture';
 exception when sqlstate 'P0268' then null;
 end;
 insert into public.lesson_progress(user_id,lesson_id) values(stu,lesson1);
 begin perform public.csa268_manage_course(mgr,ms,'aal1','delete_lesson',cid,rev,gen_random_uuid(),jsonb_build_object('id',lesson1));raise exception 'Progress cascaded away';exception when foreign_key_violation then null;end;
 delete from public.lesson_progress where lesson_id=lesson1;
 result:=public.csa268_manage_course(mgr,ms,'aal1','delete_lesson',cid,rev,gen_random_uuid(),jsonb_build_object('id',lesson1)); rev:=(result->>'updated_at')::timestamptz;
 if exists(select 1 from public.lessons where id=lesson1) then raise exception 'Draft lesson not removed';end if;
 result:=public.csa268_manage_course(mgr,ms,'aal1','delete_section',cid,rev,gen_random_uuid(),jsonb_build_object('id',section2)); rev:=(result->>'updated_at')::timestamptz;
 if exists(select 1 from public.lessons where id=lesson2) or exists(select 1 from public.course_sections where id=section2) then raise exception 'Draft section deletion incomplete';end if;
 update public.course_staff set revoked_at=clock_timestamp() where course_id=cid and user_id=mgr;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','create',cid,null,request,metadata);raise exception 'Revoked assignment replay accepted';exception when insufficient_privilege then null;end;
 update public.user_roles set revoked_at=clock_timestamp() where user_id=mgr;
 begin perform public.csa268_manage_course(mgr,ms,'aal1','get',cid,null,null,'{}');raise exception 'Revoked role read accepted';exception when insufficient_privilege then null;end;
end; $$;
select 'ok 1 - CSA268 authorized persistent course authoring, concurrency, audit and parent boundaries';
rollback;
