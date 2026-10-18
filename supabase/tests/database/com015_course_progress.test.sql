begin;
select '1..1';
do $$
declare
 actor uuid:=gen_random_uuid(); other_actor uuid:=gen_random_uuid(); admin_actor uuid:=gen_random_uuid();
 actor_session uuid:=gen_random_uuid(); other_session uuid:=gen_random_uuid(); admin_session uuid:=gen_random_uuid();
 course uuid:=gen_random_uuid(); section uuid:=gen_random_uuid(); first_lesson uuid:=gen_random_uuid(); second_lesson uuid:=gen_random_uuid();
 grant_id uuid; result jsonb;
begin
 insert into auth.users(id) values(actor),(other_actor),(admin_actor);
 insert into auth.sessions(id,user_id,aal,not_after) values
 (actor_session,actor,'aal1',now()+interval '1 day'),
 (other_session,other_actor,'aal1',now()+interval '1 day'),
 (admin_session,admin_actor,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select admin_actor,id from public.roles where code='super_admin';
 insert into public.courses(id,slug,title,price_minor,status) values(course,'summary-'||course,'Synthetic summary',10000,'draft');
 insert into public.course_sections(id,course_id,title,position,is_published) values(section,course,'Synthetic section',0,true);
 insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values
 (first_lesson,section,'First synthetic lesson','text',0,true),
 (second_lesson,section,'Second synthetic lesson','text',1,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',actor,'session_id',actor_session,'aal','aal1','role','authenticated')::text,true);
 if public.com015_my_course_progress()<>'[]'::jsonb then raise exception 'unentitled course leaked'; end if;
 grant_id:=(public.csa116_grant_admin(admin_actor,admin_session,'aal2','summary-grant',actor,course,'Synthetic',null)->>'grant_id')::uuid;
 execute 'set local role authenticated';
 result:=public.com015_my_course_progress();
 if jsonb_array_length(result)<>1 or result->0->>'course_id' is distinct from course::text or
 (result->0->>'total_lessons')::int<>2 or (result->0->>'completed_lessons')::int<>0 or
 result->0->>'next_lesson_id' is distinct from first_lesson::text then raise exception 'initial summary'; end if;
 perform public.csa133_save_progress(first_lesson,true,null,null,null);
 result:=public.com015_my_course_progress();
 if (result->0->>'completed_lessons')::int<>1 or result->0->>'next_lesson_id' is distinct from second_lesson::text then raise exception 'saved summary'; end if;
 execute 'reset role';
 update public.lessons set is_published=false where id=second_lesson;
 result:=public.com015_my_course_progress();
 if (result->0->>'total_lessons')::int<>1 or (result->0->>'completed_lessons')::int<>1 or
 result->0->>'next_lesson_id' is not null then raise exception 'unpublished lesson counted'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',other_actor,'session_id',other_session,'aal','aal1','role','authenticated')::text,true);
 if public.com015_my_course_progress()<>'[]'::jsonb then raise exception 'another student progress leaked'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',actor,'session_id',other_session,'aal','aal1','role','authenticated')::text,true);
 begin perform public.com015_my_course_progress(); raise exception 'foreign session accepted'; exception when insufficient_privilege then null; end;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',actor,'session_id',actor_session,'aal','aal1','role','authenticated')::text,true);
 update auth.sessions set not_after=now()-interval '1 second' where id=actor_session;
 begin perform public.com015_my_course_progress(); raise exception 'expired session accepted'; exception when insufficient_privilege then null; end;
 update auth.sessions set not_after=now()+interval '1 day' where id=actor_session;
 perform public.csa118_revoke_access(admin_actor,admin_session,'aal2','summary-revoke',actor,course,grant_id,'grant','Synthetic revoked');
 if public.com015_my_course_progress()<>'[]'::jsonb then raise exception 'revoked entitlement leaked'; end if;
 perform set_config('request.jwt.claims','{}',true);
 begin perform public.com015_my_course_progress(); raise exception 'anonymous session accepted'; exception when insufficient_privilege then null; end;
 if has_function_privilege('anon','public.com015_my_course_progress()','EXECUTE') or
 has_function_privilege('service_role','public.com015_my_course_progress()','EXECUTE') or
 not has_function_privilege('authenticated','public.com015_my_course_progress()','EXECUTE') then raise exception 'summary execute grants'; end if;
end $$;
select 'ok 1 - course summaries use current owner sessions, saved published progress and active entitlement';
rollback;
