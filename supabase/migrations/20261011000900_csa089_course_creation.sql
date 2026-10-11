begin;
create table public.course_staff (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.courses(id) on delete restrict,
 user_id uuid not null references public.profiles(id) on delete restrict,
 staff_role text not null check(staff_role in ('owner','editor')),
 assigned_by uuid references public.profiles(id) on delete restrict,
 assigned_at timestamptz not null default now(), revoked_at timestamptz,
 check(revoked_at is null or revoked_at>=assigned_at)
);
create unique index course_staff_active_unique on public.course_staff(course_id,user_id) where revoked_at is null;
create index course_staff_user_idx on public.course_staff(user_id);
create index course_staff_actor_idx on public.course_staff(assigned_by);
alter table public.course_staff enable row level security;
revoke all on public.course_staff from public,anon,authenticated,service_role;
create schema if not exists app_private;

create table app_private.csa089_course_creation_audit (
 id uuid primary key default gen_random_uuid(), actor_id uuid not null references public.profiles(id) on delete restrict,
 request_id uuid not null, payload jsonb not null,
 course_id uuid not null references public.courses(id) on delete restrict,
 occurred_at timestamptz not null default now(), unique(actor_id,request_id)
);
alter table app_private.csa089_course_creation_audit enable row level security;
revoke all on app_private.csa089_course_creation_audit from public,anon,authenticated,service_role;
create function app_private.csa089_audit_immutable() returns trigger language plpgsql set search_path='' as $$
begin raise exception using errcode='42501',message='Course creation audit is immutable.'; end; $$;
revoke all on function app_private.csa089_audit_immutable() from public,anon,authenticated,service_role;
create trigger csa089_no_change before update or delete on app_private.csa089_course_creation_audit for each row execute function app_private.csa089_audit_immutable();
create trigger csa089_no_truncate before truncate on app_private.csa089_course_creation_audit for each statement execute function app_private.csa089_audit_immutable();
create function public.csa089_create_course(p_actor uuid,p_session_id uuid,p_aal text,p_request_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s auth.sessions%rowtype; u auth.users%rowtype; v_super boolean; v_manager boolean; v_course uuid;
 v_prior app_private.csa089_course_creation_audit%rowtype; v_category uuid;
begin
 -- Shared role-write lock prevents revocation racing this authority check/commit.
 perform pg_catalog.pg_advisory_xact_lock(610061);
 select * into u from auth.users where id=p_actor for share;
 if not found or u.deleted_at is not null or coalesce(u.is_anonymous,false)
 or (u.banned_until is not null and u.banned_until>clock_timestamp()) then
 raise exception using errcode='42501',message='Current account required.'; end if;
 select * into s from auth.sessions where id=p_session_id and user_id=p_actor for share;
 if not found or p_aal is null or p_aal not in ('aal1','aal2') or s.aal::text is distinct from p_aal
 or (s.not_after is not null and s.not_after<=clock_timestamp()) then
 raise exception using errcode='42501',message='Current verified session required.'; end if;
 select coalesce(bool_or(r.code='super_admin'),false),coalesce(bool_or(r.code='content_manager'),false)
 into v_super,v_manager from public.user_roles ur join public.roles r on r.id=ur.role_id
 where ur.user_id=p_actor and ur.revoked_at is null;
 if (not v_super and not v_manager) or (v_super and p_aal<>'aal2') then
 raise exception using errcode='42501',message='Current content authority required.'; end if;
 if p_request_id is null or p_payload is null or jsonb_typeof(p_payload)<>'object'
 or exists(select 1 from jsonb_object_keys(p_payload) k where k not in ('title','slug','category_id','short_description','description'))
 or jsonb_typeof(p_payload->'title') is distinct from 'string'
 or jsonb_typeof(p_payload->'slug') is distinct from 'string'
 or char_length(p_payload->>'title') not between 1 and 200 or (p_payload->>'title') !~ '[^[:space:]]'
 or char_length(p_payload->>'slug') not between 1 and 200 or (p_payload->>'slug') !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
 or (p_payload ? 'category_id' and jsonb_typeof(p_payload->'category_id') not in ('string','null'))
 or (p_payload ? 'short_description' and jsonb_typeof(p_payload->'short_description') not in ('string','null'))
 or (p_payload ? 'description' and jsonb_typeof(p_payload->'description') not in ('string','null'))
 or octet_length(p_payload::text)>65536 then
 raise exception using errcode='22023',message='Invalid course payload.'; end if;
 select * into v_prior from app_private.csa089_course_creation_audit where actor_id=p_actor and request_id=p_request_id;
 if found then
 if v_prior.payload is distinct from p_payload then raise exception using errcode='22023',message='Request payload conflict.'; end if;
 return jsonb_build_object('course_id',v_prior.course_id,'status','draft'); end if;
 begin v_category := (p_payload->>'category_id')::uuid;
 exception when invalid_text_representation then raise exception using errcode='22023',message='Invalid category.'; end;
 insert into public.courses(slug,title,category_id,short_description,description,price_minor,currency_code,status,created_by)
 values(p_payload->>'slug',p_payload->>'title',v_category,p_payload->>'short_description',p_payload->>'description',0,'LKR','draft',p_actor)
 returning id into v_course;
 insert into public.course_staff(course_id,user_id,staff_role,assigned_by) values(v_course,p_actor,'owner',p_actor);
 insert into app_private.csa089_course_creation_audit(actor_id,request_id,payload,course_id) values(p_actor,p_request_id,p_payload,v_course);
 return jsonb_build_object('course_id',v_course,'status','draft');
end; $$;
revoke all on function public.csa089_create_course(uuid,uuid,text,uuid,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.csa089_create_course(uuid,uuid,text,uuid,jsonb) to service_role;
commit;
