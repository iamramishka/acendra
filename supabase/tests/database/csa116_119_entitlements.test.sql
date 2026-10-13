begin;
select '1..1';
do $$
declare buyer uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid(); finance uuid:=gen_random_uuid();
 bs uuid:=gen_random_uuid(); ads uuid:=gen_random_uuid(); fs uuid:=gen_random_uuid(); course uuid:=gen_random_uuid();
 result jsonb; grant_id uuid; second_id uuid; restriction uuid; event uuid; lease uuid; reclaimed uuid;
 timed_course uuid:=gen_random_uuid(); expires timestamptz; count_before integer;
begin
 insert into auth.users(id) values(buyer),(admin),(finance);
 insert into auth.sessions(id,user_id,aal,not_after) values(bs,buyer,'aal1',now()+interval '1 day'),(ads,admin,'aal2',now()+interval '1 day'),(fs,finance,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select admin,id from public.roles where code='super_admin';
 insert into public.user_roles(user_id,role_id) select finance,id from public.roles where code='finance_admin';
 insert into public.courses(id,slug,title,price_minor,status) values(course,'entitlement-'||course,'Synthetic',10000,'draft');
 if public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'unpaid access'; end if;
 begin perform public.csa116_grant_admin(finance,fs,'aal2','finance-grant',buyer,course,'Synthetic',null); raise exception 'finance override'; exception when insufficient_privilege then null; end;
 begin perform public.csa116_grant_admin(admin,ads,'aal1','low-aal',buyer,course,'Synthetic',null); raise exception 'low AAL'; exception when insufficient_privilege then null; end;
 begin perform public.csa116_grant_admin(admin,ads,'aal2','self-grant',admin,course,'Synthetic',null); raise exception 'self grant'; exception when insufficient_privilege then null; end;
 result:=public.csa116_grant_admin(admin,ads,'aal2','grant-one',buyer,course,'Synthetic complimentary access',null);
 grant_id:=(result->>'grant_id')::uuid;
 if not public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'draft purchase not preserved'; end if;
 if (public.csa116_grant_admin(admin,ads,'aal2','grant-one',buyer,course,'Synthetic complimentary access',null)->>'replayed')::boolean is not true then raise exception 'grant replay'; end if;
 begin perform public.csa116_grant_admin(admin,ads,'aal2','grant-one',buyer,course,'Changed',null); raise exception 'changed replay'; exception when invalid_parameter_value then null; end;
 result:=public.csa116_grant_admin(admin,ads,'aal2','grant-two',buyer,course,'Independent source',null); second_id:=(result->>'grant_id')::uuid;
 perform public.csa118_revoke_access(admin,ads,'aal2','revoke-one',buyer,course,grant_id,'grant','Source invalidated');
 if not public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'independent source lost'; end if;
 perform public.csa118_revoke_access(admin,ads,'aal2','revoke-two',buyer,course,second_id,'grant','Source invalidated');
 if public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'revoked source access'; end if;
 perform public.csa116_grant_admin(admin,ads,'aal2','fresh-grant',buyer,course,'Fresh source',null);
 if not public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'fresh source blocked'; end if;
 result:=public.csa118_revoke_access(admin,ads,'aal2','restrict-course',buyer,course,null,'course','Safety restriction'); restriction:=(result->>'restriction_id')::uuid;
 perform public.csa116_grant_admin(admin,ads,'aal2','under-restriction',buyer,course,'Another independent source',null);
 if public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'grant bypassed restriction'; end if;
 perform public.csa118_release_restriction(admin,ads,'aal2','release-course',restriction,'Restriction reviewed');
 if not public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'restriction release'; end if;
 perform public.csa118_revoke_access(admin,ads,'aal2','restrict-account',buyer,null,null,'account','Account safety');
 if public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'account restriction'; end if;
 update public.courses set status='published',published_at=clock_timestamp() where id=course;
 -- Synthetic stale projection: the authority of restrictions must not depend
 -- on a projection label. These DDL changes are rolled back with the fixture.
 alter table public.enrollments disable trigger csa116_project_enrollment;
 update public.enrollments set status='active',revoked_at=null,revocation_reason=null where user_id=buyer and course_id=course;
 alter table public.enrollments enable trigger csa116_project_enrollment;
 if public.csa117_check_entitlement(buyer,bs,'aal1',course) then raise exception 'stale label bypassed restriction'; end if;
 -- A restricted buyer may purchase, but funding cannot lift safety restrictions.
 result:=public.csa098_create_checkout_order(buyer,bs,'aal1','restricted-purchase',course,'online',null);
 if result->'data'->>'status' is distinct from 'pending_payment' then raise exception 'checkout predicate drift'; end if;
 begin perform public.csa117_check_entitlement(buyer,ads,'aal1',course); raise exception 'foreign session'; exception when insufficient_privilege then null; end;
 update auth.users set banned_until=now()+interval '1 hour' where id=buyer;
 begin perform public.csa117_check_entitlement(buyer,bs,'aal1',course); raise exception 'banned access'; exception when insufficient_privilege then null; end;
 update auth.users set banned_until=null where id=buyer;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',finance,'session_id',fs,'aal','aal2','role','authenticated')::text,true);
 if public.csa117_verify_entitlement(course) then raise exception 'cross-user access'; end if;
 if has_function_privilege('authenticated','public.csa117_check_entitlement(uuid,uuid,text,uuid)','EXECUTE') then raise exception 'spoofable actor RPC'; end if;
 if has_table_privilege('authenticated','public.enrollment_grants','INSERT') then raise exception 'client grants'; end if;
 if has_function_privilege('authenticated','public.csa118_revoke_access(uuid,uuid,text,text,uuid,uuid,uuid,text,text)','EXECUTE') then raise exception 'client revoke'; end if;
 insert into app_private.notification_outbox(event_key,recipient_user_id,notification_type,safe_payload) values('synthetic-lease',buyer,'bank_transfer_approved',jsonb_build_object('order_id',course)) returning id into event;
 -- Exclude prior transactional notices from this isolated claim test.
 update app_private.notification_outbox set next_attempt_at=now()+interval '1 day' where id<>event;
 select (x->>'lease_token')::uuid into lease from jsonb_array_elements(public.csa119_claim_notifications(1)) x;
 if lease is null or jsonb_array_length(public.csa119_claim_notifications(1))<>0 then raise exception 'double claim'; end if;
 if public.csa119_complete_notification(event,gen_random_uuid(),true) then raise exception 'foreign lease acknowledgement'; end if;
 update app_private.notification_outbox set lease_until=now()-interval '1 second' where id=event;
 if public.csa119_complete_notification(event,lease,true) then raise exception 'expired lease acknowledgement'; end if;
 select (x->>'lease_token')::uuid into reclaimed from jsonb_array_elements(public.csa119_claim_notifications(1)) x;
 if reclaimed is null or reclaimed=lease then raise exception 'reclaim token'; end if;
 if public.csa119_complete_notification(event,lease,true) then raise exception 'stale lease acknowledgement'; end if;
 if not public.csa119_complete_notification(event,reclaimed,false) then raise exception 'failure acknowledgement'; end if;
 if not exists(select 1 from app_private.notification_outbox where id=event and status='pending' and attempt_count=2 and last_error_code='DELIVERY_FAILED' and next_attempt_at>now()) then raise exception 'retry missing'; end if;
 update app_private.notification_outbox set next_attempt_at=now()-interval '1 second' where id=event;
 select (x->>'lease_token')::uuid into reclaimed from jsonb_array_elements(public.csa119_claim_notifications(1)) x;
 if not public.csa119_complete_notification(event,reclaimed,true) then raise exception 'send acknowledgement'; end if;
 if not exists(select 1 from app_private.notification_outbox where id=event and status='sent' and sent_at is not null and attempt_count=3) then raise exception 'sent state'; end if;
 insert into public.courses(id,slug,title,price_minor,status) values(timed_course,'expiry-'||timed_course,'Synthetic expiry',10000,'draft');
 -- Use another eligible buyer to isolate the account restriction above.
 -- Allow preceding real RPC/constraint work on slow CI hosts; wait for the actual deadline below.
 expires:=clock_timestamp()+interval '5 seconds';
 perform public.csa116_grant_admin(admin,ads,'aal2','timed-grant',finance,timed_course,'Timed complimentary',expires);
 if not public.csa117_check_entitlement(finance,fs,'aal2',timed_course) then raise exception 'timed grant initially denied'; end if;
 update public.courses set status='published',published_at=clock_timestamp() where id=timed_course;
 begin perform public.csa098_create_checkout_order(finance,fs,'aal2','duplicate-entitlement',timed_course,'online',null); raise exception 'duplicate access purchase'; exception when unique_violation then null; end;
 perform pg_sleep(greatest(0,extract(epoch from (expires-clock_timestamp())))+0.05);
 if public.csa117_check_entitlement(finance,fs,'aal2',timed_course) then raise exception 'expiry requires worker'; end if;
 update public.enrollments set updated_at=clock_timestamp() where user_id=finance and course_id=timed_course;
 if not exists(select 1 from public.enrollments where user_id=finance and course_id=timed_course and status='expired') then raise exception 'expired projection'; end if;
 if (public.csa116_grant_admin(admin,ads,'aal2','timed-grant',finance,timed_course,'Timed complimentary',expires)->>'replayed')::boolean is not true then raise exception 'expired grant retry'; end if;
 begin
  update public.enrollment_grants set invalidated_at=null,invalidation_reason=null where id=grant_id;
  raise exception 'invalidated source restored';
 exception when check_violation then null; end;
 select count(*) into count_before from public.enrollment_grants;
 -- A deliberately injected transaction failure rolls back grant, audit, notice
 -- and idempotency together (the subtransaction is a real PostgreSQL boundary).
 begin
  perform public.csa116_grant_admin(admin,ads,'aal2','rollback-grant',finance,timed_course,'Rollback probe',null);
  raise exception using errcode='P0001',message='Synthetic injected failure';
 exception when raise_exception then null; end;
 if (select count(*) from public.enrollment_grants)<>count_before or exists(select 1 from app_private.idempotency_records where operation='grant-admin' and idempotency_key='rollback-grant')
 or exists(select 1 from app_private.audit_logs where request_id='rollback-grant') then raise exception 'partial rollback'; end if;
 update app_private.notification_outbox set status='processing',attempt_count=5,lease_token=gen_random_uuid(),lease_until=now()-interval '1 second',sent_at=null where id=event;
 perform public.csa119_claim_notifications(1);
 if not exists(select 1 from app_private.notification_outbox where id=event and status='failed' and last_error_code='DELIVERY_FAILED') then raise exception 'exhausted crashed lease'; end if;
 update public.user_roles set revoked_at=clock_timestamp() where user_id=admin;
 begin perform public.csa116_grant_admin(admin,ads,'aal2','old-token',finance,timed_course,'Forbidden',null); raise exception 'revoked authority'; exception when insufficient_privilege then null; end;
end $$;
select 'ok 1 - grant, verification, scope revocation, authority, replay and notification leases';
rollback;
