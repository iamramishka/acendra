begin;
select '1..1';
do $$
declare adm uuid:=gen_random_uuid(); stu uuid:=gen_random_uuid(); mgr uuid:=gen_random_uuid(); fin uuid:=gen_random_uuid();
 ads uuid:=gen_random_uuid(); ss uuid:=gen_random_uuid(); ms uuid:=gen_random_uuid(); fs uuid:=gen_random_uuid();
 cid uuid:=gen_random_uuid(); sid uuid:=gen_random_uuid(); lid uuid:=gen_random_uuid(); asset uuid:=gen_random_uuid();
 request uuid:=gen_random_uuid(); rev timestamptz; result jsonb; before_rows jsonb; after_rows jsonb;
begin
 insert into auth.users(id,email) values(adm,'archive-admin@synthetic.test'),(stu,'archive-student@synthetic.test'),(mgr,'archive-manager@synthetic.test'),(fin,'archive-finance@synthetic.test');
 insert into auth.sessions(id,user_id,aal,not_after) values(ads,adm,'aal2',now()+interval '1 day'),(ss,stu,'aal1',now()+interval '1 day'),(ms,mgr,'aal1',now()+interval '1 day'),(fs,fin,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select adm,id from public.roles where code='super_admin';
 insert into public.user_roles(user_id,role_id) select mgr,id from public.roles where code='content_manager';
 insert into public.user_roles(user_id,role_id) select fin,id from public.roles where code='finance_admin';
 perform public.csa268_manage_course(adm,ads,'aal2','create',cid,null,gen_random_uuid(),jsonb_build_object('title','Retained course','slug','archive-'||cid,'category_id',null,'short_description','Summary','description','Description','price_minor','10000','currency_code','LKR'));
 insert into public.course_staff(course_id,user_id,staff_role,assigned_by) values(cid,mgr,'editor',adm);
 insert into public.course_sections(id,course_id,title,position,is_published) values(sid,cid,'Retained section',0,true);
 insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values(lid,sid,'Retained lesson','pdf',0,true);
 insert into public.orders(order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method)
 values('ARCHIVE-'||cid,stu,cid,'Retained course',10000,'LKR','bank_transfer');
 insert into public.enrollments(user_id,course_id,status,granted_at) values(stu,cid,'active',clock_timestamp());
 insert into public.lesson_progress(user_id,lesson_id,pdf_page) values(stu,lid,3);
 insert into app_private.media_assets(id,asset_type,storage_provider,uploaded_by) values(asset,'course_pdf','supabase',adm);
 insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values(lid,asset,'primary',0);
 update public.courses set status='published',published_at=clock_timestamp() where id=cid returning updated_at into rev;

 begin perform public.csa268_archive_course(stu,ss,'aal1',cid,rev,request);raise exception 'Student archive accepted';exception when insufficient_privilege then null;end;
 begin perform public.csa268_archive_course(mgr,ms,'aal1',cid,rev,request);raise exception 'Manager bypassed publication authority';exception when insufficient_privilege then null;end;
 begin perform public.csa268_archive_course(fin,fs,'aal2',cid,rev,request);raise exception 'Finance archive accepted';exception when insufficient_privilege then null;end;
 begin perform public.csa268_archive_course(adm,ads,'aal1',cid,rev,request);raise exception 'AAL1 archive accepted';exception when insufficient_privilege then null;end;
 begin perform public.csa268_archive_course(adm,ads,'aal2',cid,rev-interval '1 second',request);raise exception 'Stale archive accepted';exception when serialization_failure then null;end;
 begin perform public.csa268_archive_course(adm,ads,'aal2',cid,rev,null);raise exception 'Missing idempotency accepted';exception when invalid_parameter_value then null;end;

 select jsonb_build_object(
  'orders',(select jsonb_agg(to_jsonb(o)) from public.orders o where course_id=cid),
  'enrollments',(select jsonb_agg(to_jsonb(e)) from public.enrollments e where course_id=cid),
  'progress',(select jsonb_agg(to_jsonb(p)) from public.lesson_progress p where lesson_id=lid),
  'sections',(select jsonb_agg(to_jsonb(s)) from public.course_sections s where course_id=cid),
  'lessons',(select jsonb_agg(to_jsonb(l)) from public.lessons l where id=lid),
  'assets',(select jsonb_agg(to_jsonb(m)) from app_private.media_assets m where id=asset),
  'associations',(select jsonb_agg(to_jsonb(a)) from app_private.lesson_assets a where lesson_id=lid)
 ) into before_rows;
 result:=public.csa268_archive_course(adm,ads,'aal2',cid,rev,request);
 if result->>'status'<>'archived' or result->>'previous_status'<>'published'
  or (select status from public.courses where id=cid)<>'archived'
  or (result->>'updated_at')::timestamptz<=rev then raise exception 'Archival state/revision incorrect';end if;
 select jsonb_build_object(
  'orders',(select jsonb_agg(to_jsonb(o)) from public.orders o where course_id=cid),
  'enrollments',(select jsonb_agg(to_jsonb(e)) from public.enrollments e where course_id=cid),
  'progress',(select jsonb_agg(to_jsonb(p)) from public.lesson_progress p where lesson_id=lid),
  'sections',(select jsonb_agg(to_jsonb(s)) from public.course_sections s where course_id=cid),
  'lessons',(select jsonb_agg(to_jsonb(l)) from public.lessons l where id=lid),
  'assets',(select jsonb_agg(to_jsonb(m)) from app_private.media_assets m where id=asset),
  'associations',(select jsonb_agg(to_jsonb(a)) from app_private.lesson_assets a where lesson_id=lid)
 ) into after_rows;
 if before_rows is distinct from after_rows then raise exception 'Archival changed protected history';end if;
 if (select count(*) from app_private.csa268_authoring_audit where course_id=cid)<>2 then raise exception 'Create audit lost or archive audit missing';end if;
 result:=public.csa268_archive_course(adm,ads,'aal2',cid,rev,request);
 if result->>'replayed'<>'true' or (select count(*) from app_private.csa268_authoring_audit where course_id=cid)<>2 then raise exception 'Archive replay duplicated mutation';end if;
 begin perform public.csa268_archive_course(adm,ads,'aal2',cid,rev+interval '1 second',request);raise exception 'Changed replay accepted';exception when serialization_failure then null;end;
 update public.user_roles set revoked_at=clock_timestamp() where user_id=adm;
 begin perform public.csa268_archive_course(adm,ads,'aal2',cid,rev,request);raise exception 'Revoked role replay accepted';exception when insufficient_privilege then null;end;
 if has_function_privilege('anon','public.csa268_archive_course(uuid,uuid,text,uuid,timestamptz,uuid)','EXECUTE')
  or has_function_privilege('authenticated','public.csa268_archive_course(uuid,uuid,text,uuid,timestamptz,uuid)','EXECUTE')
  or not has_function_privilege('service_role','public.csa268_archive_course(uuid,uuid,text,uuid,timestamptz,uuid)','EXECUTE') then raise exception 'Archive RPC grants incorrect';end if;
end; $$;
select 'ok 1 - Course archival preserves protected history, authority, revisions and idempotency';
rollback;
