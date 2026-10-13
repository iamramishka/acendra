-- CSA-155: real save/read RPC checks. Disposable database only; all fixtures roll back.
begin;
create temporary table csa155_results(n integer primary key, description text not null);
do $$
declare
 buyer uuid:=gen_random_uuid(); peer uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid();
 buyer_session uuid:=gen_random_uuid(); peer_session uuid:=gen_random_uuid(); admin_session uuid:=gen_random_uuid();
 course uuid:=gen_random_uuid(); section uuid:=gen_random_uuid(); txt uuid:=gen_random_uuid(); img uuid:=gen_random_uuid();
 pdf uuid:=gen_random_uuid(); video uuid:=gen_random_uuid(); grant_id uuid;
 response jsonb; prior jsonb; snapshot jsonb; records jsonb; opened timestamptz; updated timestamptz;
begin
 insert into auth.users(id) values(buyer),(peer),(admin);
 insert into auth.sessions(id,user_id,aal,not_after) values
  (buyer_session,buyer,'aal1',now()+interval '1 day'),(peer_session,peer,'aal1',now()+interval '1 day'),(admin_session,admin,'aal2',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select admin,id from public.roles where code='super_admin';
 insert into public.courses(id,slug,title,price_minor,status) values(course,'csa155-'||course,'Synthetic progress persistence',10000,'draft');
 insert into public.course_sections(id,course_id,title,position,is_published) values(section,course,'Synthetic section',0,true);
 insert into public.lessons(id,section_id,title,lesson_type,position,is_published,duration_seconds) values
  (txt,section,'Text','text',0,true,null),(img,section,'Image','image',1,true,null),
  (pdf,section,'PDF','pdf',2,true,null),(video,section,'Video','video',3,true,90);
 grant_id:=(public.csa116_grant_admin(admin,admin_session,'aal2','csa155-buyer',buyer,course,'Synthetic progress fixture',null)->>'grant_id')::uuid;
 perform public.csa116_grant_admin(admin,admin_session,'aal2','csa155-peer',peer,course,'Synthetic peer fixture',null);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',buyer,'session_id',buyer_session,'aal','aal1','role','authenticated')::text,true);
 execute 'set local role authenticated';
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if records is distinct from '[]'::jsonb then raise exception 'New entitled learner has unexpected progress'; end if;
 insert into csa155_results values(1,'entitled current-session learner initially has no saved progress');
 execute 'set local role authenticated';
 response:=public.csa133_save_progress(txt,true,null,null,null);
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if response->>'lesson_id' is distinct from txt::text or response->'is_completed' is distinct from 'true'::jsonb
  or records->0 is distinct from response or jsonb_array_length(records)<>1 then raise exception 'Text completion did not roundtrip'; end if;
 insert into csa155_results values(2,'text completion roundtrips through authenticated save/read RPCs');
 execute 'set local role authenticated';
 response:=public.csa133_save_progress(img,false,null,null,null);
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if records->1 is distinct from response or response->'is_completed' is distinct from 'false'::jsonb
  or response->'pdf_page' is distinct from 'null'::jsonb or response->'progress_seconds' is distinct from 'null'::jsonb then raise exception 'Image completion did not roundtrip'; end if;
 insert into csa155_results values(3,'image incomplete state roundtrips without media-specific positions');
 execute 'set local role authenticated';
 response:=public.csa133_save_progress(pdf,false,7,0.625,null);
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if records->2 is distinct from response or (response->>'pdf_page')::integer<>7 or (response->>'pdf_position')::numeric<>0.625 then raise exception 'PDF resume did not roundtrip'; end if;
 insert into csa155_results values(4,'PDF page and normalized fractional offset roundtrip exactly');
 execute 'set local role authenticated';
 response:=public.csa133_save_progress(video,true,null,null,90);
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if records->3 is distinct from response or (response->>'progress_seconds')::integer<>90 or jsonb_array_length(records)<>4 then raise exception 'Video resume did not roundtrip'; end if;
 insert into csa155_results values(5,'video timestamp at duration boundary roundtrips in curriculum order');
 prior:=response; opened:=(response->>'last_opened_at')::timestamptz; updated:=(response->>'updated_at')::timestamptz;
 execute 'set local role authenticated';
 response:=public.csa133_save_progress(video,true,null,null,90);
 execute 'reset role';
 if (response-'last_opened_at'-'updated_at') is distinct from (prior-'last_opened_at'-'updated_at')
  or (response->>'last_opened_at')::timestamptz<opened or (response->>'updated_at')::timestamptz<updated
  or (select count(*) from public.lesson_progress where user_id=buyer and lesson_id=video)<>1 then raise exception 'Retry duplicates or corrupts stored progress'; end if;
 insert into csa155_results values(6,'identical retry keeps one row and completion with nondecreasing timestamps');
 execute 'set local role authenticated';
 response:=public.csa133_save_progress(video,false,null,null,null);
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if records->3 is distinct from response or response->'is_completed' is distinct from 'false'::jsonb
  or response->'progress_seconds' is distinct from 'null'::jsonb then raise exception 'Complete snapshot update did not clear resume'; end if;
 insert into csa155_results values(7,'later snapshot can clear completion and nullable resume state');
 select to_jsonb(p) into snapshot from public.lesson_progress p where user_id=buyer and lesson_id=pdf;
 execute 'set local role authenticated';
 begin perform public.csa133_save_progress(pdf,true,0,0,null); raise exception 'Zero page accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(pdf,true,1,-0.01,null); raise exception 'Negative offset accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(pdf,true,1,1.01,null); raise exception 'Offset overflow accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(pdf,true,null,0.5,null); raise exception 'Offset without page accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(pdf,true,1,'NaN'::numeric,null); raise exception 'NaN offset accepted'; exception when invalid_parameter_value then null; end;
 execute 'reset role';
 if snapshot is distinct from (select to_jsonb(p) from public.lesson_progress p where user_id=buyer and lesson_id=pdf) then raise exception 'Invalid PDF input mutated saved row'; end if;
 insert into csa155_results values(8,'invalid PDF page offset and NaN are denied without corrupting persistence');
 select to_jsonb(p) into snapshot from public.lesson_progress p where user_id=buyer and lesson_id=video;
 execute 'set local role authenticated';
 begin perform public.csa133_save_progress(video,true,null,null,-1); raise exception 'Negative seconds accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(video,true,null,null,91); raise exception 'Duration overflow accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(txt,true,null,null,10); raise exception 'Text video position accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.csa133_save_progress(img,true,1,0,null); raise exception 'Image PDF position accepted'; exception when invalid_parameter_value then null; end;
 execute 'reset role';
 if snapshot is distinct from (select to_jsonb(p) from public.lesson_progress p where user_id=buyer and lesson_id=video) then raise exception 'Invalid video input mutated saved row'; end if;
 insert into csa155_results values(9,'invalid video seconds and cross-type positions cannot mutate stored progress');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',peer,'session_id',peer_session,'aal','aal1','role','authenticated')::text,true);
 execute 'set local role authenticated';
 records:=public.csa133_read_progress(course);
 response:=public.csa133_save_progress(txt,false,null,null,null);
 execute 'reset role';
 if records is distinct from '[]'::jsonb or (select is_completed from public.lesson_progress where user_id=buyer and lesson_id=txt) is not true
  or (select is_completed from public.lesson_progress where user_id=peer and lesson_id=txt) is not false then raise exception 'Peer progress leaked or overwrote buyer'; end if;
 insert into csa155_results values(10,'equally entitled foreign learner has isolated read and write records');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',buyer,'session_id',peer_session,'aal','aal1','role','authenticated')::text,true);
 execute 'set local role authenticated';
 begin perform public.csa133_read_progress(course); raise exception 'Foreign session read accepted'; exception when insufficient_privilege then null; end;
 begin perform public.csa133_save_progress(txt,false,null,null,null); raise exception 'Foreign session save accepted'; exception when insufficient_privilege then null; end;
 execute 'reset role';
 perform set_config('request.jwt.claims',jsonb_build_object('sub',buyer,'session_id',buyer_session,'aal','aal1','role','authenticated')::text,true);
 update auth.sessions set not_after=now()-interval '1 second' where id=buyer_session;
 execute 'set local role authenticated';
 begin perform public.csa133_read_progress(course); raise exception 'Expired owner session read accepted'; exception when insufficient_privilege then null; end;
 begin perform public.csa133_save_progress(txt,false,null,null,null); raise exception 'Expired owner session save accepted'; exception when insufficient_privilege then null; end;
 execute 'reset role';
 update auth.sessions set not_after=now()+interval '1 day' where id=buyer_session;
 insert into csa155_results values(11,'foreign and expired owner sessions cannot read or update progress');
 execute 'set local role authenticated';
 records:=public.csa133_read_progress(course);
 execute 'reset role';
 if jsonb_array_length(records)<>4 or records->0->'is_completed' is distinct from 'true'::jsonb then raise exception 'Reload lost buyer persisted rows'; end if;
 insert into csa155_results values(12,'later owner read reloads saved records independently from foreign writes');
 select jsonb_agg(to_jsonb(p) order by p.lesson_id) into snapshot from public.lesson_progress p where p.user_id=buyer;
 perform public.csa118_revoke_access(admin,admin_session,'aal2','csa155-revoke',buyer,course,grant_id,'grant','Synthetic revocation');
 execute 'set local role authenticated';
 begin perform public.csa133_read_progress(course); raise exception 'Revoked read accepted'; exception when insufficient_privilege then null; end;
 begin perform public.csa133_save_progress(txt,false,null,null,null); raise exception 'Revoked save accepted'; exception when insufficient_privilege then null; end;
 execute 'reset role';
 if snapshot is distinct from (select jsonb_agg(to_jsonb(p) order by p.lesson_id) from public.lesson_progress p where p.user_id=buyer) then raise exception 'Revoked save mutated history'; end if;
 insert into csa155_results values(13,'revoked entitlement denies reads and updates while preserving saved history');
 if (select count(*) from public.enrollment_grants where user_id in(buyer,peer))<>2
  or has_table_privilege('authenticated','public.lesson_progress','INSERT')
  or has_table_privilege('authenticated','public.lesson_progress','SELECT') then raise exception 'Progress bypasses source access or direct ownership boundary'; end if;
 insert into csa155_results values(14,'progress never grants entitlement or direct table access');
end $$;
select '1..14';
select 'ok '||n||' - '||description from csa155_results order by n;
rollback;
