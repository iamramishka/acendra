-- CSA116–119: source-based access, audited manual changes, postcommit delivery.
begin;
create table app_private.access_restrictions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete restrict,
 course_id uuid references public.courses(id) on delete restrict, actor_id uuid references public.profiles(id) on delete restrict,
 reason text not null check(char_length(reason) between 1 and 1000 and reason ~ '[^[:space:]]'),
 created_at timestamptz not null default clock_timestamp()
);
create index access_restrictions_beneficiary on app_private.access_restrictions(user_id,course_id);
-- Preserve preexisting revoked projections conservatively; no source inference
-- can silently lift an older safety decision lacking explicit scope history.
insert into app_private.access_restrictions(user_id,course_id,reason)
select user_id,course_id,revocation_reason from public.enrollments where status='revoked';
create table app_private.access_restriction_releases (
 restriction_id uuid primary key references app_private.access_restrictions(id) on delete restrict,
 actor_id uuid not null references public.profiles(id) on delete restrict,
 reason text not null check(char_length(reason) between 1 and 1000 and reason ~ '[^[:space:]]'),
 created_at timestamptz not null default clock_timestamp()
);
alter table app_private.access_restrictions enable row level security;
alter table app_private.access_restriction_releases enable row level security;
revoke all on app_private.access_restrictions,app_private.access_restriction_releases from public,anon,authenticated,service_role;
create trigger access_restrictions_immutable before update or delete on app_private.access_restrictions for each row execute function app_private.csa096_immutable_record();
create trigger access_restrictions_no_truncate before truncate on app_private.access_restrictions for each statement execute function app_private.csa096_immutable_record();
create trigger access_releases_immutable before update or delete on app_private.access_restriction_releases for each row execute function app_private.csa096_immutable_record();
create trigger access_releases_no_truncate before truncate on app_private.access_restriction_releases for each statement execute function app_private.csa096_immutable_record();

create function app_private.csa117_has_access(p_user uuid,p_course uuid)
returns boolean language sql volatile security definer set search_path='' as $$
 select not exists(select 1 from app_private.access_restrictions r where r.user_id=p_user and (r.course_id is null or r.course_id=p_course)
 and not exists(select 1 from app_private.access_restriction_releases l where l.restriction_id=r.id))
 and exists(select 1 from public.enrollment_grants g where g.user_id=p_user and g.course_id=p_course
 and g.invalidated_at is null and g.valid_from<=clock_timestamp() and (g.valid_until is null or g.valid_until>clock_timestamp())
 and (g.source_type='admin_grant' or exists(select 1 from public.orders o join app_private.verified_settlements s on s.id=g.settlement_id and s.order_id=o.id
 where o.id=g.source_order_id and o.buyer_id=p_user and o.course_id=p_course and o.status='paid' and o.paid_at=g.valid_from)));
$$;
create function public.csa117_check_entitlement(p_actor uuid,p_session_id uuid,p_aal text,p_course uuid)
returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,false);
 return app_private.csa117_has_access(p_actor,p_course);
end; $$;
-- Authenticated students cannot supply another beneficiary/session.
create function public.csa117_verify_entitlement(p_course uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare claims jsonb:=auth.jwt();
begin
 if claims->>'role' is distinct from 'authenticated' then raise exception using errcode='42501',message='Authenticated session required.'; end if;
 return public.csa117_check_entitlement(auth.uid(),(claims->>'session_id')::uuid,claims->>'aal',p_course);
end; $$;

-- New triggers integrate with the existing serialized online/bank grant seams.
-- First fulfillment time and source history remain immutable. No financial mutation.
create function app_private.csa116_project_enrollment() returns trigger
language plpgsql security definer set search_path='' as $$
declare expiry timestamptz;
begin
 if app_private.csa117_has_access(new.user_id,new.course_id) then
  select case when bool_or(g.valid_until is null) then null else max(g.valid_until) end into expiry
  from public.enrollment_grants g where g.enrollment_id=new.id and g.invalidated_at is null
  and g.valid_from<=clock_timestamp() and (g.valid_until is null or g.valid_until>clock_timestamp())
  and (g.source_type='admin_grant' or exists(select 1 from public.orders o where o.id=g.source_order_id and o.status='paid'));
  new.status:='active'; new.expires_at:=expiry; new.revoked_at:=null; new.revocation_reason:=null;
 elsif not exists(select 1 from app_private.access_restrictions r where r.user_id=new.user_id and (r.course_id is null or r.course_id=new.course_id)
  and not exists(select 1 from app_private.access_restriction_releases l where l.restriction_id=r.id))
  and exists(select 1 from public.enrollment_grants g where g.enrollment_id=new.id and g.invalidated_at is null and g.valid_until<=clock_timestamp()
  and (g.source_type='admin_grant' or exists(select 1 from public.orders o where o.id=g.source_order_id and o.status='paid'))) then
  new.status:='expired'; new.revoked_at:=null; new.revocation_reason:=null;
 elsif exists(select 1 from public.enrollment_grants where enrollment_id=new.id) then
  new.status:='revoked'; new.expires_at:=null; new.revoked_at:=greatest(new.granted_at,clock_timestamp()); new.revocation_reason:='No currently eligible access source.';
 end if;
 return new;
end; $$;
create trigger csa116_project_enrollment before update on public.enrollments for each row execute function app_private.csa116_project_enrollment();
create function app_private.csa116_refresh_grant() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 -- Fulfillment already holds order then beneficiary/course; manual operations
 -- use the same beneficiary/course lock and never acquire funding-order locks.
 perform pg_advisory_xact_lock(hashtext(new.user_id::text),hashtext(new.course_id::text));
 update public.enrollments set updated_at=clock_timestamp() where id=new.enrollment_id;
 return new;
end; $$;
create trigger csa116_refresh_grant after insert or update on public.enrollment_grants for each row execute function app_private.csa116_refresh_grant();

create function app_private.csa118_require_admin(p_actor uuid,p_session uuid,p_aal text,p_key text,p_reason text)
returns void language plpgsql security definer set search_path='' as $$
begin
 perform app_private.csa108_require_session(p_actor,p_session,p_aal,true);
 if not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p_actor and ur.revoked_at is null and r.code='super_admin') then
 raise exception using errcode='42501',message='Current super-admin required.'; end if;
 if p_key is null or p_key !~ '^[A-Za-z0-9._:-]{1,128}$' or p_reason is null or char_length(p_reason) not between 1 and 1000 or p_reason !~ '[^[:space:]]' then
 raise exception using errcode='22023',message='Bounded reason and idempotency key required.'; end if;
end; $$;
create function app_private.csa118_prior(p_actor uuid,p_operation text,p_key text,p_hash text)
returns jsonb language plpgsql set search_path='' as $$
declare prior app_private.idempotency_records%rowtype;
begin
 perform pg_advisory_xact_lock(hashtext('user:'||p_actor::text),hashtext(p_operation||':'||p_key));
 select * into prior from app_private.idempotency_records where principal_scope='user:'||p_actor::text and operation=p_operation and idempotency_key=p_key;
 if found then
  if prior.request_hash is distinct from p_hash then raise exception using errcode='22023',message='Idempotency conflict.'; end if;
  return prior.safe_result||jsonb_build_object('replayed',true);
 end if;
 return null;
end; $$;
create function app_private.csa118_record(p_actor uuid,p_operation text,p_key text,p_hash text,p_result jsonb,p_user uuid,p_resource uuid)
returns void language plpgsql set search_path='' as $$
begin
 insert into app_private.audit_logs(actor_user_id,action,resource_type,resource_id,request_id,outcome,safe_metadata)
 values(p_actor,p_operation,'entitlement',p_resource,p_key,'committed',p_result);
 insert into app_private.idempotency_records(principal_scope,operation,idempotency_key,request_hash,safe_result)
 values('user:'||p_actor::text,p_operation,p_key,p_hash,p_result);
 insert into app_private.notification_outbox(event_key,recipient_user_id,notification_type,safe_payload)
 values(p_operation||':'||p_actor::text||':'||p_key,p_user,case when p_operation='revoke-access' then 'enrollment_revoked' else 'enrollment_changed' end,
 jsonb_build_object('course_id',p_result->'course_id'));
end; $$;
create function public.csa116_grant_admin(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_user uuid,p_course uuid,p_reason text,p_expires_at timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare h text; prior jsonb; result jsonb; enrollment uuid; gid uuid; t timestamptz:=clock_timestamp();
begin
 perform app_private.csa118_require_admin(p_actor,p_session_id,p_aal,p_key,p_reason);
 if p_user is null or p_course is null or p_user=p_actor then raise exception using errcode='42501',message='Independent beneficiary required.'; end if;
 h:=encode(sha256(convert_to(jsonb_build_array(p_user,p_course,p_reason,p_expires_at)::text,'UTF8')),'hex');
 prior:=app_private.csa118_prior(p_actor,'grant-admin',p_key,h); if prior is not null then return prior; end if;
 if p_expires_at is not null and (not isfinite(p_expires_at) or p_expires_at<=clock_timestamp()) then raise exception using errcode='22023',message='Future expiry required.'; end if;
 perform 1 from auth.users where id=p_user and deleted_at is null and not coalesce(is_anonymous,false) and (banned_until is null or banned_until<=clock_timestamp()) for share;
 if not found then raise exception using errcode='42501',message='Eligible beneficiary required.'; end if;
 perform pg_advisory_xact_lock(hashtext(p_user::text),hashtext(p_course::text));
 insert into public.enrollments(user_id,course_id,status,granted_at) values(p_user,p_course,'active',t) on conflict(user_id,course_id) do nothing;
 select id into enrollment from public.enrollments where user_id=p_user and course_id=p_course for update;
 insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,granted_by,reason,valid_from,valid_until)
 values(enrollment,p_user,p_course,'admin_grant',p_actor,p_reason,t,p_expires_at) returning id into gid;
 result:=jsonb_build_object('replayed',false,'grant_id',gid,'course_id',p_course,'reason',p_reason);
 perform app_private.csa118_record(p_actor,'grant-admin',p_key,h,result,p_user,gid);
 return result;
end; $$;
create function public.csa118_revoke_access(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_user uuid,p_course uuid,p_grant uuid,p_scope text,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare h text; prior jsonb; result jsonb; rid uuid; g public.enrollment_grants%rowtype; e record;
begin
 perform app_private.csa118_require_admin(p_actor,p_session_id,p_aal,p_key,p_reason);
 if p_user is null or p_user=p_actor then raise exception using errcode='42501',message='Independent beneficiary required.'; end if;
 if p_scope is null or p_scope not in ('grant','course','account') or (p_scope='account' and (p_course is not null or p_grant is not null))
 or (p_scope in ('grant','course') and p_course is null) or (p_scope='grant' and p_grant is null) or (p_scope='course' and p_grant is not null) then
 raise exception using errcode='22023',message='Explicit revocation scope required.'; end if;
 h:=encode(sha256(convert_to(jsonb_build_array(p_user,p_course,p_grant,p_scope,p_reason)::text,'UTF8')),'hex');
 prior:=app_private.csa118_prior(p_actor,'revoke-access',p_key,h); if prior is not null then return prior; end if;
 if p_scope='grant' then
  perform pg_advisory_xact_lock(hashtext(p_user::text),hashtext(p_course::text));
  select * into g from public.enrollment_grants where id=p_grant and user_id=p_user and course_id=p_course for update;
  if not found then raise exception using errcode='P0002',message='Matching grant required.'; end if;
  if g.invalidated_at is not null then raise exception using errcode='55000',message='Grant already invalidated.'; end if;
  update public.enrollment_grants set invalidated_at=greatest(valid_from,clock_timestamp()),invalidation_reason=p_reason where id=g.id;
  rid:=g.id;
 else
  -- Role mutation lock already serializes manual changes. Lock existing courses
  -- in order; concurrent purchases may finish but verification sees restriction.
  for e in select course_id from public.enrollments where user_id=p_user and (p_course is null or course_id=p_course) order by course_id loop
   perform pg_advisory_xact_lock(hashtext(p_user::text),hashtext(e.course_id::text));
  end loop;
  insert into app_private.access_restrictions(user_id,course_id,actor_id,reason) values(p_user,p_course,p_actor,p_reason) returning id into rid;
  update public.enrollments set updated_at=clock_timestamp() where user_id=p_user and (p_course is null or course_id=p_course);
 end if;
 result:=jsonb_build_object('replayed',false,'scope',p_scope,'course_id',p_course,'reason',p_reason,
 case when p_scope='grant' then 'grant_id' else 'restriction_id' end,rid);
 perform app_private.csa118_record(p_actor,'revoke-access',p_key,h,result,p_user,rid);
 return result;
end; $$;
create function public.csa118_release_restriction(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_restriction uuid,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare h text; prior jsonb; result jsonb; r app_private.access_restrictions%rowtype; e record;
begin
 perform app_private.csa118_require_admin(p_actor,p_session_id,p_aal,p_key,p_reason);
 h:=encode(sha256(convert_to(jsonb_build_array(p_restriction,p_reason)::text,'UTF8')),'hex');
 prior:=app_private.csa118_prior(p_actor,'release-restriction',p_key,h); if prior is not null then return prior; end if;
 select * into r from app_private.access_restrictions where id=p_restriction;
 if not found then raise exception using errcode='P0002',message='Restriction required.'; end if;
 if r.user_id=p_actor then raise exception using errcode='42501',message='Independent beneficiary required.'; end if;
 for e in select course_id from public.enrollments where user_id=r.user_id and (r.course_id is null or course_id=r.course_id) order by course_id loop
  perform pg_advisory_xact_lock(hashtext(r.user_id::text),hashtext(e.course_id::text));
 end loop;
 insert into app_private.access_restriction_releases(restriction_id,actor_id,reason) values(r.id,p_actor,p_reason);
 update public.enrollments set updated_at=clock_timestamp() where user_id=r.user_id and (r.course_id is null or course_id=r.course_id);
 result:=jsonb_build_object('replayed',false,'restriction_id',r.id,'course_id',r.course_id,'reason',p_reason);
 perform app_private.csa118_record(p_actor,'release-restriction',p_key,h,result,r.user_id,r.id);
 return result;
end; $$;

alter table app_private.notification_outbox add column lease_token uuid, add column lease_until timestamptz,
 add column last_error_code text check(last_error_code is null or last_error_code='DELIVERY_FAILED');
create index csa119_due_notifications on app_private.notification_outbox(status,next_attempt_at,lease_until);
create function public.csa119_claim_notifications(p_limit integer default 10)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if p_limit is null or p_limit not between 1 and 50 then raise exception using errcode='22023',message='Bounded batch required.'; end if;
 -- Exhausted crashed leases become observable terminal failures.
 update app_private.notification_outbox set status='failed',lease_token=null,lease_until=null,last_error_code='DELIVERY_FAILED'
 where status='processing' and lease_until<=clock_timestamp() and attempt_count>=5;
 with due as (select id from app_private.notification_outbox where attempt_count<5 and
 ((status='pending' and (next_attempt_at is null or next_attempt_at<=clock_timestamp())) or (status='processing' and lease_until<=clock_timestamp()))
 order by created_at,id for update skip locked limit p_limit), claimed as (
 update app_private.notification_outbox n set status='processing',lease_token=gen_random_uuid(),lease_until=clock_timestamp()+interval '5 minutes',attempt_count=attempt_count+1
 from due where n.id=due.id returning n.*)
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'event_key',event_key,'recipient_user_id',recipient_user_id,'notification_type',notification_type,
 'safe_payload',safe_payload,'lease_token',lease_token)), '[]'::jsonb) into result from claimed;
 return result;
end; $$;
create function public.csa119_complete_notification(p_id uuid,p_lease_token uuid,p_sent boolean)
returns boolean language plpgsql security definer set search_path='' as $$
begin
 if p_sent is null then raise exception using errcode='22023',message='Delivery outcome required.'; end if;
 update app_private.notification_outbox set status=case when p_sent then 'sent' when attempt_count>=5 then 'failed' else 'pending' end,
 sent_at=case when p_sent then clock_timestamp() else null end,
 next_attempt_at=case when p_sent or attempt_count>=5 then null else clock_timestamp()+interval '1 minute'*power(2,attempt_count) end,
 lease_token=null,lease_until=null,last_error_code=case when p_sent then null else 'DELIVERY_FAILED' end
 where id=p_id and status='processing' and lease_token=p_lease_token and lease_until>clock_timestamp();
 return found;
end; $$;
revoke all on function app_private.csa117_has_access(uuid,uuid),app_private.csa116_project_enrollment(),app_private.csa116_refresh_grant(),
 app_private.csa118_require_admin(uuid,uuid,text,text,text),app_private.csa118_prior(uuid,text,text,text),app_private.csa118_record(uuid,text,text,text,jsonb,uuid,uuid)
 from public,anon,authenticated,service_role;
revoke all on function public.csa117_verify_entitlement(uuid),public.csa117_check_entitlement(uuid,uuid,text,uuid),
 public.csa116_grant_admin(uuid,uuid,text,text,uuid,uuid,text,timestamptz),public.csa118_revoke_access(uuid,uuid,text,text,uuid,uuid,uuid,text,text),
 public.csa118_release_restriction(uuid,uuid,text,text,uuid,text),public.csa119_claim_notifications(integer),public.csa119_complete_notification(uuid,uuid,boolean)
 from public,anon,authenticated,service_role;
grant execute on function public.csa117_verify_entitlement(uuid) to authenticated;
grant execute on function public.csa117_check_entitlement(uuid,uuid,text,uuid),public.csa116_grant_admin(uuid,uuid,text,text,uuid,uuid,text,timestamptz),
 public.csa118_revoke_access(uuid,uuid,text,text,uuid,uuid,uuid,text,text),public.csa118_release_restriction(uuid,uuid,text,text,uuid,text),
 public.csa119_claim_notifications(integer),public.csa119_complete_notification(uuid,uuid,boolean) to service_role;
commit;
