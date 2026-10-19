-- CSA268: trusted metadata authoring. No client table grants, financial writes,
-- paid body storage, media validation bypass or entitlement changes.
begin;

create table app_private.csa268_authoring_audit (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references public.profiles(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 request_id uuid not null, action text not null, payload jsonb not null,
 result jsonb not null, occurred_at timestamptz not null default clock_timestamp(),
 unique(actor_id,request_id)
);
alter table app_private.csa268_authoring_audit enable row level security;
revoke all on app_private.csa268_authoring_audit from public,anon,authenticated,service_role;
create trigger csa268_audit_no_change before update or delete on app_private.csa268_authoring_audit
 for each row execute function app_private.csa089_audit_immutable();
create trigger csa268_audit_no_truncate before truncate on app_private.csa268_authoring_audit
 for each statement execute function app_private.csa089_audit_immutable();

-- Keep existing immediate uniqueness/ON CONFLICT seed compatibility. Select a
-- free temporary range disjoint from both occupied and final [0,size) positions;
-- two bulk updates then perform a swap atomically in this one transaction.
create function app_private.csa268_order_offset(p_course uuid,p_section uuid,p_size integer)
returns integer language sql stable set search_path='' as $$
 with occupied as (
  select position from public.course_sections where p_section is null and course_id=p_course
  union all select position from public.lessons where p_section is not null and section_id=p_section
 ), starts as (
  select p_size::bigint pos union select position::bigint+1 from occupied
 )
 select min(pos)::integer from starts
 where pos>=p_size and pos+p_size<=2147483648::bigint
  and not exists(select 1 from occupied o where o.position>=starts.pos and o.position<starts.pos+p_size);
$$;
revoke all on function app_private.csa268_order_offset(uuid,uuid,integer) from public,anon,authenticated,service_role;

-- Every course writer, including publication, advances the same revision even
-- when two changes occur in the same database statement/transaction.
create function app_private.csa268_course_revision() returns trigger language plpgsql set search_path='' as $$
begin new.updated_at:=greatest(clock_timestamp(),old.updated_at+interval '1 microsecond'); return new; end; $$;
revoke all on function app_private.csa268_course_revision() from public,anon,authenticated,service_role;
create trigger zz_csa268_course_revision before update on public.courses for each row
 execute function app_private.csa268_course_revision();

create function app_private.csa268_validate_payload(p_action text,p jsonb)
returns void language plpgsql set search_path='' as $$
declare keys text[]; n numeric;
begin
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>65536 then
  raise exception using errcode='22023',message='Invalid authoring payload.'; end if;
 keys:=case
  when p_action in ('get','curriculum') then array[]::text[]
  when p_action in ('create','update') then array['title','slug','category_id','short_description','description','price_minor','currency_code']
  when p_action='upsert_section' then array['id','title','position','is_published']
  when p_action in ('delete_section','delete_lesson') then array['id']
  when p_action='upsert_lesson' then array['id','section_id','title','description','lesson_type','position','is_preview','is_published','duration_seconds']
  when p_action='reorder_sections' then array['ids']
  when p_action='reorder_lessons' then array['section_id','ids'] end;
 if keys is null or not p ?& keys or exists(select 1 from jsonb_object_keys(p) k where not k=any(keys)) then
  raise exception using errcode='22023',message='Unexpected authoring fields.'; end if;
 if p ? 'title' and (jsonb_typeof(p->'title')<>'string' or length(p->>'title') not between 1 and 200 or (p->>'title')!~'[^[:space:]]') then
  raise exception using errcode='22023',message='Invalid title.'; end if;
 if p ? 'id' then perform (p->>'id')::uuid; if p->>'id' is null then raise exception using errcode='22023',message='ID required.';end if;end if;
 if p ? 'section_id' then perform (p->>'section_id')::uuid; if p->>'section_id' is null then raise exception using errcode='22023',message='Section required.';end if;end if;
 if p_action in ('create','update') then
  if jsonb_typeof(p->'slug')<>'string' or length(p->>'slug') not between 1 and 200 or (p->>'slug')!~'^[a-z0-9]+(-[a-z0-9]+)*$'
   or jsonb_typeof(p->'description')<>'string' or length(p->>'description')>40000
   or jsonb_typeof(p->'short_description')<>'string' or length(p->>'short_description')>2000
   or jsonb_typeof(p->'category_id') not in ('null','string')
   or jsonb_typeof(p->'price_minor')<>'string' or (p->>'price_minor')!~'^(0|[1-9][0-9]{0,18})$'
   or p->>'currency_code' is distinct from 'LKR' then
   raise exception using errcode='22023',message='Invalid course metadata.'; end if;
  perform (p->>'price_minor')::bigint; perform (p->>'category_id')::uuid;
 end if;
 if p ? 'position' then
  if jsonb_typeof(p->'position')<>'number' then raise exception using errcode='22023',message='Invalid position.';end if;
  n:=(p->>'position')::numeric;
  if n<>trunc(n) or n<0 or n>1000000 then raise exception using errcode='22023',message='Invalid position.';end if;
 end if;
 if p ? 'is_published' and jsonb_typeof(p->'is_published')<>'boolean' then raise exception using errcode='22023',message='Invalid publication marker.';end if;
 if p_action='upsert_lesson' then
  if p->>'lesson_type' is null or p->>'lesson_type' not in ('video','pdf','text','image') or jsonb_typeof(p->'description')<>'string'
   or length(p->>'description')>2000 or jsonb_typeof(p->'is_preview')<>'boolean' or jsonb_typeof(p->'duration_seconds') not in ('null','number') then
   raise exception using errcode='22023',message='Invalid lesson metadata.';end if;
  if p->>'duration_seconds' is not null then
   n:=(p->>'duration_seconds')::numeric;
   if n<>trunc(n) or n<0 or n>2147483647 then raise exception using errcode='22023',message='Invalid duration.';end if;
  end if;
 end if;
 if p ? 'ids' then
  if jsonb_typeof(p->'ids')<>'array' or jsonb_array_length(p->'ids')>1000 then raise exception using errcode='22023',message='Bounded ordered IDs required.';end if;
  perform value::uuid from jsonb_array_elements_text(p->'ids');
  if exists(select 1 from jsonb_array_elements(p->'ids') v where jsonb_typeof(v)<>'string')
   or (select count(distinct value::uuid) from jsonb_array_elements_text(p->'ids'))<>jsonb_array_length(p->'ids') then
   raise exception using errcode='22023',message='Unique ordered IDs required.';end if;
 end if;
exception when invalid_text_representation or numeric_value_out_of_range then
 raise exception using errcode='22023',message='Invalid authoring value.';
end; $$;
revoke all on function app_private.csa268_validate_payload(text,jsonb) from public,anon,authenticated,service_role;

create or replace function public.csa268_manage_course(p_actor uuid,p_session_id uuid,p_aal text,p_action text,p_course uuid,p_expected timestamptz,p_request_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare roles text[]; c public.courses%rowtype; v_section public.course_sections%rowtype; v_lesson public.lessons%rowtype;
 prior app_private.csa268_authoring_audit%rowtype; command jsonb; result jsonb; target uuid;
 ids uuid[]; old_ids uuid[]; is_read boolean; temp_offset integer;
begin
 -- Same authority/course/curriculum lock order as publication and media.
 roles:=app_private.csa158_reporting_roles(p_actor,p_session_id,p_aal);
 if not coalesce(roles&&array['super_admin','content_manager'],false) then raise exception using errcode='42501',message='Content authority required.';end if;
 if p_course is null or p_action is null then raise exception using errcode='22023',message='Course command required.';end if;
 perform app_private.csa268_validate_payload(p_action,p_payload);
 is_read:=p_action in ('get','curriculum');
 if not is_read and (p_request_id is null or (p_action<>'create' and (p_expected is null or not isfinite(p_expected)))) then
  raise exception using errcode='22023',message='Request identity and revision required.';end if;
 if p_action<>'create' then
  select * into c from public.courses where id=p_course for update;
  if not found then raise exception using errcode='P0002',message='Course missing.';end if;
  if not 'super_admin'=any(roles) and not exists(select 1 from public.course_staff cs where cs.course_id=p_course and cs.user_id=p_actor and cs.revoked_at is null) then
   raise exception using errcode='42501',message='Current course assignment required.';end if;
 end if;
 if not is_read then
  command:=jsonb_build_object('action',p_action,'course_id',p_course,'expected_updated_at',p_expected,'payload',p_payload);
  select * into prior from app_private.csa268_authoring_audit where actor_id=p_actor and request_id=p_request_id;
  if found then
   if prior.payload is distinct from command then raise exception using errcode='40001',message='Request conflict.';end if;
   if p_action='create' and not 'super_admin'=any(roles) and not exists(select 1 from public.course_staff cs where cs.course_id=p_course and cs.user_id=p_actor and cs.revoked_at is null) then raise exception using errcode='42501',message='Current course assignment required.';end if;
   return prior.result||jsonb_build_object('replayed',true);
  end if;
  if p_action<>'create' and c.updated_at is distinct from p_expected then raise exception using errcode='40001',message='Course changed. Reload before saving.';end if;
 end if;
 if p_action='get' then
  return jsonb_build_object('course',jsonb_build_object('id',c.id,'title',c.title,'slug',c.slug,'category_id',c.category_id,
   'short_description',coalesce(c.short_description,''),'description',coalesce(c.description,''),'price_minor',c.price_minor::text,'currency_code',c.currency_code,
   'status',c.status,'created_at',c.created_at,'updated_at',c.updated_at,
   'enrollment_count',(select count(*) from public.enrollments where course_id=c.id),
   'section_count',(select count(*) from public.course_sections where course_id=c.id),
   'lesson_count',(select count(*) from public.lessons l join public.course_sections s on s.id=l.section_id where s.course_id=c.id)),
   'categories',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by sort_order,id) from
    (select id,name,sort_order from public.categories where is_active order by sort_order,id limit 1000) cats),'[]'::jsonb));
 elsif p_action='curriculum' then
  if (select count(*) from public.course_sections where course_id=p_course)>1000 or
   (select count(*) from public.lessons l join public.course_sections s on s.id=l.section_id where s.course_id=p_course)>1000 then
   raise exception using errcode='22023',message='Curriculum exceeds editor bounds.';end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'course_id',s.course_id,'title',s.title,'position',s.position,'is_published',s.is_published,'updated_at',s.updated_at,
   'lessons',coalesce((select jsonb_agg(jsonb_build_object('id',l.id,'section_id',l.section_id,'course_id',p_course,'title',l.title,'description',coalesce(l.description,''),
    'lesson_type',l.lesson_type,'position',l.position,'is_preview',l.is_preview,'is_published',l.is_published,'duration_seconds',l.duration_seconds,'updated_at',l.updated_at) order by l.position,l.id)
    from public.lessons l where l.section_id=s.id),'[]'::jsonb)) order by s.position,s.id),'[]'::jsonb) into result
   from public.course_sections s where s.course_id=p_course;
  return jsonb_build_object('sections',result,'updated_at',c.updated_at);
 elsif p_action in ('create','update') then
  if p_payload->>'category_id' is not null and not exists(select 1 from public.categories where id=(p_payload->>'category_id')::uuid and is_active) then raise exception using errcode='22023',message='Active category required.';end if;
  if p_action='create' then
   insert into public.courses(id,title,slug,category_id,short_description,description,price_minor,currency_code,status,created_by)
    values(p_course,p_payload->>'title',p_payload->>'slug',(p_payload->>'category_id')::uuid,p_payload->>'short_description',p_payload->>'description',(p_payload->>'price_minor')::bigint,'LKR','draft',p_actor);
   insert into public.course_staff(course_id,user_id,staff_role,assigned_by) values(p_course,p_actor,'owner',p_actor);
  else
   if c.status='archived' then raise exception using errcode='55000',message='Archived courses cannot be edited.';end if;
   if c.status='published' and (nullif(btrim(p_payload->>'description'),'') is null or nullif(btrim(p_payload->>'short_description'),'') is null) then raise exception using errcode='23514',message='Published metadata must remain ready.';end if;
   update public.courses set title=p_payload->>'title',slug=p_payload->>'slug',category_id=(p_payload->>'category_id')::uuid,
    short_description=p_payload->>'short_description',description=p_payload->>'description',price_minor=(p_payload->>'price_minor')::bigint where id=p_course;
  end if;
 else
  if c.status<>'draft' then raise exception using errcode='55000',message='Unpublish the course before curriculum changes.';end if;
  target:=(p_payload->>'id')::uuid;
  if p_action='upsert_section' then
   select * into v_section from public.course_sections where id=target;
   if found and v_section.course_id<>p_course then raise exception using errcode='42501',message='Foreign section.';end if;
   if found and v_section.is_published and not (p_payload->>'is_published')::boolean
    and exists(select 1 from public.enrollments where course_id=p_course) then
    raise exception using errcode='23503',message='Purchased curriculum must remain available.';end if;
   if found then update public.course_sections set title=p_payload->>'title',position=(p_payload->>'position')::integer,is_published=(p_payload->>'is_published')::boolean where id=target;
   else
    if (select count(*) from public.course_sections where course_id=p_course)>=1000 then raise exception using errcode='22023',message='Section limit reached.';end if;
    insert into public.course_sections(id,course_id,title,position,is_published) values(target,p_course,p_payload->>'title',(p_payload->>'position')::integer,(p_payload->>'is_published')::boolean);
   end if;
  elsif p_action='upsert_lesson' then
   select * into v_section from public.course_sections where id=(p_payload->>'section_id')::uuid and course_id=p_course;
   if not found then raise exception using errcode='42501',message='Current course section required.';end if;
   select * into v_lesson from public.lessons where id=target;
   if found then
    if v_lesson.section_id<>v_section.id then raise exception using errcode='42501',message='Lesson parent cannot change through this operation.';end if;
    if v_lesson.is_published and not (p_payload->>'is_published')::boolean
     and exists(select 1 from public.enrollments where course_id=p_course) then
     raise exception using errcode='23503',message='Purchased curriculum must remain available.';end if;
    if v_lesson.lesson_type<>p_payload->>'lesson_type' and exists(select 1 from app_private.lesson_assets where lesson_id=v_lesson.id) then raise exception using errcode='23503',message='Linked content type is immutable.';end if;
    update public.lessons set title=p_payload->>'title',description=p_payload->>'description',lesson_type=p_payload->>'lesson_type',position=(p_payload->>'position')::integer,
     is_preview=(p_payload->>'is_preview')::boolean,is_published=(p_payload->>'is_published')::boolean,duration_seconds=(p_payload->>'duration_seconds')::integer where id=target;
   else
    if (select count(*) from public.lessons l join public.course_sections s on s.id=l.section_id where s.course_id=p_course)>=1000 then raise exception using errcode='22023',message='Lesson limit reached.';end if;
    insert into public.lessons(id,section_id,title,description,lesson_type,position,is_preview,is_published,duration_seconds)
     values(target,v_section.id,p_payload->>'title',p_payload->>'description',p_payload->>'lesson_type',(p_payload->>'position')::integer,(p_payload->>'is_preview')::boolean,(p_payload->>'is_published')::boolean,(p_payload->>'duration_seconds')::integer);
   end if;
  elsif p_action in ('delete_section','delete_lesson') then
   -- Never cascade away students' progress or purchased curriculum. Media FKs
   -- additionally prevent deleting an uploaded/validated lesson association.
   if exists(select 1 from public.enrollments where course_id=p_course) then raise exception using errcode='23503',message='Purchased curriculum must be retained.';end if;
   if p_action='delete_section' then
    if not exists(select 1 from public.course_sections where id=target and course_id=p_course) then raise exception using errcode='42501',message='Foreign section.';end if;
    if exists(select 1 from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id where l.section_id=target) then raise exception using errcode='23503',message='Learning history must be retained.';end if;
    delete from public.lessons where section_id=target;
    delete from public.course_sections where id=target;
   else
    if not exists(select 1 from public.lessons l join public.course_sections s on s.id=l.section_id where l.id=target and s.course_id=p_course) then raise exception using errcode='42501',message='Foreign lesson.';end if;
    if exists(select 1 from public.lesson_progress where lesson_id=target) then raise exception using errcode='23503',message='Learning history must be retained.';end if;
    delete from public.lessons where id=target;
   end if;
  elsif p_action in ('reorder_sections','reorder_lessons') then
   select coalesce(array_agg(value::uuid order by ordinality),array[]::uuid[]) into ids from jsonb_array_elements_text(p_payload->'ids') with ordinality;
   if p_action='reorder_sections' then
    select coalesce(array_agg(id order by id),array[]::uuid[]) into old_ids from public.course_sections where course_id=p_course;
   else
    if not exists(select 1 from public.course_sections where id=(p_payload->>'section_id')::uuid and course_id=p_course) then raise exception using errcode='42501',message='Foreign section.';end if;
    select coalesce(array_agg(id order by id),array[]::uuid[]) into old_ids from public.lessons where section_id=(p_payload->>'section_id')::uuid;
   end if;
   if cardinality(ids)<>cardinality(old_ids) or not ids @> old_ids then raise exception using errcode='40001',message='Ordering must include the current complete collection.';end if;
   temp_offset:=app_private.csa268_order_offset(p_course,case when p_action='reorder_lessons' then (p_payload->>'section_id')::uuid else null end,cardinality(ids));
   if temp_offset is null then raise exception using errcode='40001',message='No safe ordering range available.';end if;
   if p_action='reorder_sections' then
    update public.course_sections s set position=(temp_offset+x.n-1)::integer from unnest(ids) with ordinality x(id,n) where s.id=x.id and s.course_id=p_course;
    update public.course_sections s set position=x.n::integer-1 from unnest(ids) with ordinality x(id,n) where s.id=x.id and s.course_id=p_course;
   else
    update public.lessons l set position=(temp_offset+x.n-1)::integer from unnest(ids) with ordinality x(id,n) where l.id=x.id and l.section_id=(p_payload->>'section_id')::uuid;
    update public.lessons l set position=x.n::integer-1 from unnest(ids) with ordinality x(id,n) where l.id=x.id and l.section_id=(p_payload->>'section_id')::uuid;
   end if;
  end if;
  update public.courses set title=title where id=p_course;
 end if;
 select * into c from public.courses where id=p_course;
 result:=jsonb_build_object('course_id',p_course,'updated_at',c.updated_at,'replayed',false);
 insert into app_private.csa268_authoring_audit(actor_id,course_id,request_id,action,payload,result) values(p_actor,p_course,p_request_id,p_action,command,result);
 return result;
end; $$;
revoke all on function public.csa268_manage_course(uuid,uuid,text,text,uuid,timestamptz,uuid,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.csa268_manage_course(uuid,uuid,text,text,uuid,timestamptz,uuid,jsonb) to service_role;
commit;
