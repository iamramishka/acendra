-- Cross-ledger security regression; all fixtures and fault triggers roll back.
begin;
select '1..1';
create function pg_temp.csa174_fail_audit() returns trigger language plpgsql as $$
begin raise exception using errcode='P0001',message='CSA174 injected audit failure'; end; $$;
do $$
declare actor uuid:=gen_random_uuid(); beneficiary uuid:=gen_random_uuid(); session_id uuid:=gen_random_uuid();
 course uuid; v_request uuid:=gen_random_uuid(); result jsonb; relation text; principal text; privilege text;
 state text; command text; before_count bigint; ledger regclass; media uuid;
begin
 insert into auth.users(id) values(actor),(beneficiary);
 insert into public.profiles(id,display_name) values(actor,'Synthetic auditor'),(beneficiary,'Synthetic beneficiary') on conflict(id) do nothing;
 insert into auth.sessions(id,user_id,aal,not_after) values(session_id,actor,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select actor,id from public.roles where code='super_admin';
 result:=public.csa089_create_course(actor,session_id,'aal2',v_request,jsonb_build_object('slug','audit-'||v_request,'title','Synthetic audit'));
 course:=(result->>'course_id')::uuid;
 perform public.csa089_create_course(actor,session_id,'aal2',v_request,jsonb_build_object('title','Synthetic audit','slug','audit-'||v_request));
 if (select count(*) from app_private.csa089_course_creation_audit where actor_id=actor)<>1 then raise exception 'Course replay duplicated audit';end if;
 if not exists(select 1 from app_private.csa089_course_creation_audit a where a.actor_id=actor and a.request_id=v_request and a.course_id=course and a.occurred_at is not null and a.payload=jsonb_build_object('title','Synthetic audit','slug','audit-'||v_request)) then raise exception 'Course audit attribution/payload';end if;
 perform public.csa116_grant_admin(actor,session_id,'aal2','audit-grant',beneficiary,course,'Synthetic complimentary grant',null);
 perform public.csa116_grant_admin(actor,session_id,'aal2','audit-grant',beneficiary,course,'Synthetic complimentary grant',null);
 if (select count(*) from app_private.audit_logs where actor_user_id=actor and request_id='audit-grant')<>1 then raise exception 'Entitlement replay duplicated audit';end if;
 if exists(select 1 from app_private.audit_logs where actor_user_id=actor and (created_at is null or outcome<>'committed' or safe_metadata ?| array['email','password','access_token','receipt_path','bank_account'])) then raise exception 'Unsafe or incomplete entitlement audit';end if;
 -- Nonempty fixtures make row-level mutation checks meaningful.
 perform public.csa061_change_role(actor,'aal2',beneficiary,'content_manager','grant','Synthetic role audit',gen_random_uuid());
 insert into app_private.csa165_publication_audit(actor_id,course_id,command_key,payload,result,old_status,new_status)
 values(actor,course,'synthetic-audit','{}','{}','draft','published');
 insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes)
 values(v_request,'public_thumbnail','supabase','course-media',course||'/thumbnails/'||v_request||'.png','image/png',8);
 insert into app_private.csa164_media_validation_audit(asset_id,actor_id,checksum_sha256,policy_reference) values(v_request,actor,repeat('a',64),'synthetic-policy');
 foreach relation in array array['public.csa061_role_audit','app_private.csa089_course_creation_audit','app_private.audit_logs','app_private.csa164_media_validation_audit','app_private.csa165_publication_audit'] loop
  ledger:=relation::regclass;
  if not (select relrowsecurity from pg_class where oid=ledger) then raise exception 'Audit RLS missing: %',relation;end if;
  foreach principal in array array['anon','authenticated','service_role'] loop
   foreach privilege in array array['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] loop
    if has_table_privilege(principal,ledger,privilege) then raise exception 'Audit privilege leaked: % % %',principal,relation,privilege;end if;
   end loop;
  end loop;
  execute format('select count(*) from %s',ledger) into before_count;
  if before_count=0 then raise exception 'Missing audit fixture: %',relation;end if;
  foreach command in array array[format('update %s set %I=%I',ledger,case when relation='app_private.audit_logs' then 'action' when relation='app_private.csa164_media_validation_audit' then 'policy_reference' else 'actor_id' end,case when relation='app_private.audit_logs' then 'action' when relation='app_private.csa164_media_validation_audit' then 'policy_reference' else 'actor_id' end),format('delete from %s',ledger),format('truncate %s',ledger)] loop
   state:=null;
   begin execute command;exception when others then state:=sqlstate;end;
   if state is distinct from (case when relation='app_private.audit_logs' then '23514' else '42501' end) then raise exception 'Audit mutation not denied: % state %',command,state;end if;
  end loop;
 end loop;
 -- Failure at audit insertion must roll back course and owner assignment.
 execute 'create trigger csa174_fault before insert on app_private.csa089_course_creation_audit for each row execute function pg_temp.csa174_fail_audit()';
 state:=null;
 begin perform public.csa089_create_course(actor,session_id,'aal2',gen_random_uuid(),jsonb_build_object('slug','audit-fault-'||actor,'title','Fault'));exception when others then state:=sqlstate;end;
 if state is distinct from 'P0001' or exists(select 1 from public.courses where slug='audit-fault-'||actor) then raise exception 'Audit fault did not roll back course';end if;
 execute 'drop trigger csa174_fault on app_private.csa089_course_creation_audit';
 execute 'create trigger csa174_fault before insert on app_private.audit_logs for each row execute function pg_temp.csa174_fail_audit()';
 state:=null;
 begin perform public.csa116_grant_admin(actor,session_id,'aal2','audit-fault-grant',beneficiary,course,'Synthetic failure',null);exception when others then state:=sqlstate;end;
 if state is distinct from 'P0001' or exists(select 1 from app_private.idempotency_records where principal_scope='user:'||actor and idempotency_key='audit-fault-grant') or (select count(*) from public.enrollment_grants where user_id=beneficiary and course_id=course)<>1 then raise exception 'Audit fault left partial entitlement';end if;
 execute 'drop trigger csa174_fault on app_private.audit_logs';
 result:=public.csa164_prepare_media_upload(actor,session_id,'aal2',gen_random_uuid(),course,null,'public_thumbnail','image/png',8,'synthetic-policy');
 media:=(result->>'asset_id')::uuid;
 execute 'create trigger csa174_fault before insert on app_private.csa164_media_validation_audit for each row execute function pg_temp.csa174_fail_audit()';
 state:=null;
 begin perform public.csa164_finalize_media_upload(actor,session_id,'aal2',media,repeat('b',64),8,'image/png','synthetic-policy');exception when others then state:=sqlstate;end;
 if state is distinct from 'P0001' or exists(select 1 from app_private.media_assets where id=media and (validation_status='validated' or checksum_sha256 is not null)) or exists(select 1 from app_private.csa164_media_validation_audit where asset_id=media) then raise exception 'Media audit failure left validated asset';end if;
 execute 'drop trigger csa174_fault on app_private.csa164_media_validation_audit';
 perform public.csa164_finalize_media_upload(actor,session_id,'aal2',media,repeat('b',64),8,'image/png','synthetic-policy');
 perform public.csa164_finalize_media_upload(actor,session_id,'aal2',media,repeat('b',64),8,'image/png','synthetic-policy');
 if (select count(*) from app_private.csa164_media_validation_audit where asset_id=media and actor_id=actor and checksum_sha256=repeat('b',64) and policy_reference='synthetic-policy')<>1 then raise exception 'Media replay/attribution';end if;
 raise notice 'CSA174 cross-ledger immutability, least privilege, attribution, replay and atomic audit checks passed';
end; $$;
select 'ok 1 - cross-ledger immutability privileges attribution replay and audit rollback';
rollback;
