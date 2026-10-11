-- Transactional TAP, synthetic fixtures only. CSA-077 must be applied first.
begin;
create temporary sequence csa078_assertion;
grant usage, select on sequence csa078_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa078_assertion') || ' - ' || description;
end;
$$;
create function pg_temp.expect_error(command text, expected_state text, description text)
returns text language plpgsql as $$
declare actual_state text;
begin
  begin execute command; exception when others then actual_state := sqlstate; end;
  return pg_temp.assert_ok(actual_state = expected_state, description);
end;
$$;

-- Minimum parent fixture agreed with CSA-077 owner; replay actual migration in CI.
insert into public.courses(id, slug, title, price_minor) values
 ('07800000-0000-0000-0000-000000000001','csa078-course-a','Synthetic Course A',0),
 ('07800000-0000-0000-0000-000000000002','csa078-course-b','Synthetic Course B',0);
insert into public.course_sections(id,course_id,title,position,created_at,updated_at) values
 ('07810000-0000-0000-0000-000000000001','07800000-0000-0000-0000-000000000001','Section A',0,now()-interval '1 day',now()-interval '1 day'),
 ('07810000-0000-0000-0000-000000000002','07800000-0000-0000-0000-000000000002','Section B',0,now()-interval '1 day',now()-interval '1 day');
insert into public.lessons(id,section_id,title,lesson_type,position,created_at,updated_at) values
 ('07820000-0000-0000-0000-000000000001','07810000-0000-0000-0000-000000000001','Lesson A','text',0,now()-interval '1 day',now()-interval '1 day'),
 ('07820000-0000-0000-0000-000000000002','07810000-0000-0000-0000-000000000002','Lesson B','video',0,now()-interval '1 day',now()-interval '1 day');
select pg_temp.assert_ok((select bool_and(not is_published) from public.course_sections where course_id in ('07800000-0000-0000-0000-000000000001','07800000-0000-0000-0000-000000000002')),'sections default unpublished; same position allowed across courses');
select pg_temp.assert_ok((select bool_and(not is_published and not is_preview and duration_seconds is null) from public.lessons where section_id in ('07810000-0000-0000-0000-000000000001','07810000-0000-0000-0000-000000000002')),'lessons default unpublished, nonpreview, unknown duration; independent section ordering');
select pg_temp.expect_error($q$update public.course_sections set title=repeat('a',201) where id='07810000-0000-0000-0000-000000000002'$q$,'23514','overlong section title rejected');
select pg_temp.expect_error($q$update public.lessons set title=repeat('a',201) where id='07820000-0000-0000-0000-000000000002'$q$,'23514','overlong lesson title rejected');
select pg_temp.expect_error($q$update public.course_sections set title='' where id='07810000-0000-0000-0000-000000000002'$q$,'23514','empty section titles rejected');
select pg_temp.expect_error($q$update public.course_sections set title=chr(9)||chr(10)||chr(13)||' ' where id='07810000-0000-0000-0000-000000000002'$q$,'23514','control whitespace section titles rejected');
select pg_temp.expect_error($q$update public.lessons set title='' where id='07820000-0000-0000-0000-000000000002'$q$,'23514','empty lesson titles rejected');
select pg_temp.expect_error($q$update public.lessons set title=chr(9)||chr(10)||chr(13)||' ' where id='07820000-0000-0000-0000-000000000002'$q$,'23514','control whitespace lesson titles rejected');
select pg_temp.expect_error($q$update public.course_sections set title=null where id='07810000-0000-0000-0000-000000000002'$q$,'23502','section title required');
select pg_temp.expect_error($q$update public.lessons set title=null where id='07820000-0000-0000-0000-000000000002'$q$,'23502','lesson title required');
select pg_temp.expect_error($q$update public.course_sections set course_id=null where id='07810000-0000-0000-0000-000000000002'$q$,'23502','course parent required');
select pg_temp.expect_error($q$update public.lessons set section_id=null where id='07820000-0000-0000-0000-000000000002'$q$,'23502','section parent required');
select pg_temp.expect_error($q$update public.course_sections set course_id='07800000-0000-0000-0000-000000000099' where id='07810000-0000-0000-0000-000000000002'$q$,'23503','missing course rejected');
select pg_temp.expect_error($q$update public.lessons set section_id='07810000-0000-0000-0000-000000000099' where id='07820000-0000-0000-0000-000000000002'$q$,'23503','missing section rejected');
select pg_temp.expect_error($q$update public.course_sections set position=-1 where id='07810000-0000-0000-0000-000000000002'$q$,'23514','negative section order rejected');
select pg_temp.expect_error($q$update public.lessons set position=-1 where id='07820000-0000-0000-0000-000000000002'$q$,'23514','negative lesson order rejected');
select pg_temp.expect_error($q$update public.course_sections set course_id='07800000-0000-0000-0000-000000000001' where id='07810000-0000-0000-0000-000000000002'$q$,'23505','duplicate position within course rejected');
select pg_temp.expect_error($q$update public.lessons set section_id='07810000-0000-0000-0000-000000000001' where id='07820000-0000-0000-0000-000000000002'$q$,'23505','duplicate position within section rejected');
select pg_temp.expect_error($q$update public.lessons set duration_seconds=-1 where id='07820000-0000-0000-0000-000000000002'$q$,'23514','negative duration rejected');
select pg_temp.expect_error($q$update public.lessons set lesson_type='audio' where id='07820000-0000-0000-0000-000000000002'$q$,'23514','unsupported type rejected');
select pg_temp.expect_error($q$update public.lessons set lesson_type=null where id='07820000-0000-0000-0000-000000000002'$q$,'23502','type required');
select pg_temp.expect_error($q$delete from public.course_sections where id='07810000-0000-0000-0000-000000000002'$q$,'23503','referenced sections cannot cascade lessons');
select pg_temp.expect_error($q$delete from public.courses where id='07800000-0000-0000-0000-000000000001'$q$,'23503','referenced courses cannot cascade sections');
select pg_temp.expect_error($q$update public.course_sections set created_at=now()+interval '1 day' where id='07810000-0000-0000-0000-000000000002'$q$,'23514','section timestamp ordering enforced');
select pg_temp.expect_error($q$update public.lessons set created_at=now()+interval '1 day' where id='07820000-0000-0000-0000-000000000002'$q$,'23514','lesson timestamp ordering enforced');
update public.course_sections set title='章节' where course_id in ('07800000-0000-0000-0000-000000000001','07800000-0000-0000-0000-000000000002');
update public.lessons set title='课程',duration_seconds=0 where section_id in ('07810000-0000-0000-0000-000000000001','07810000-0000-0000-0000-000000000002');
select pg_temp.assert_ok((select bool_and(updated_at>created_at) from public.course_sections where course_id in ('07800000-0000-0000-0000-000000000001','07800000-0000-0000-0000-000000000002')),'Unicode section title and timestamp trigger');
select pg_temp.assert_ok((select bool_and(updated_at>created_at and duration_seconds=0) from public.lessons where section_id in ('07810000-0000-0000-0000-000000000001','07810000-0000-0000-0000-000000000002')),'Unicode lesson title, zero duration and timestamp trigger');
insert into public.lessons(section_id,title,lesson_type,position)
 select '07810000-0000-0000-0000-000000000001','Type '||t,t,p
 from (values ('pdf',1),('image',2),('video',3)) as types(t,p);
select pg_temp.assert_ok((select count(distinct lesson_type)=4 from public.lessons where section_id in ('07810000-0000-0000-0000-000000000001','07810000-0000-0000-0000-000000000002')),'all four approved types accepted');
select pg_temp.expect_error($q$update public.course_sections set position=null where id='07810000-0000-0000-0000-000000000002'$q$,'23502','section position required');
select pg_temp.expect_error($q$update public.lessons set position=null where id='07820000-0000-0000-0000-000000000002'$q$,'23502','lesson position required');
select pg_temp.expect_error($q$update public.course_sections set is_published=null where id='07810000-0000-0000-0000-000000000002'$q$,'23502','section publication flag required');
select pg_temp.expect_error($q$update public.lessons set is_published=null where id='07820000-0000-0000-0000-000000000002'$q$,'23502','lesson publication flag required');
select pg_temp.expect_error($q$update public.lessons set is_preview=null where id='07820000-0000-0000-0000-000000000002'$q$,'23502','preview flag required');
insert into public.course_sections(course_id,title,position) values ('07800000-0000-0000-0000-000000000001',repeat('名',200),1);
select pg_temp.assert_ok((select id is not null and created_at is not null and updated_at>=created_at from public.course_sections where position=1 and course_id='07800000-0000-0000-0000-000000000001'),'section UUID/timestamps default and Unicode title boundary');
select pg_temp.assert_ok((select bool_and(id is not null and created_at is not null and updated_at>=created_at) from public.lessons where position>0 and section_id='07810000-0000-0000-0000-000000000001'),'lesson UUID/timestamps default');
select pg_temp.assert_ok((select count(*)=2 from pg_class where oid in ('public.course_sections'::regclass,'public.lessons'::regclass) and relrowsecurity),'RLS enabled on both metadata tables');
select pg_temp.assert_ok((select array_agg(column_name::text order by ordinal_position)=array['id','course_id','title','description','position','is_published','created_at','updated_at'] from information_schema.columns where table_schema='public' and table_name='course_sections'),'exact approved section metadata columns');
select pg_temp.assert_ok((select array_agg(column_name::text order by ordinal_position)=array['id','section_id','title','description','lesson_type','position','duration_seconds','is_preview','is_published','created_at','updated_at'] from information_schema.columns where table_schema='public' and table_name='lessons'),'exact lesson metadata columns without private content');
select pg_temp.assert_ok(not has_function_privilege(r,'public.csa078_set_metadata_updated_at()','EXECUTE'),r||' cannot execute timestamp helper')
 from unnest(array['anon','authenticated','service_role']) r;
select '1..'||last_value from pg_temp.csa078_assertion;
rollback;
