begin;
select '1..1';
do $$
declare actor uuid='27800000-0000-0000-0000-000000000001';
 other_actor uuid='27800000-0000-0000-0000-000000000002';
 session uuid='27800000-0000-0000-0000-000000000011';
 other_session uuid='27800000-0000-0000-0000-000000000012';
 course uuid='27800000-0000-0000-0000-000000000021';
 bank uuid='27800000-0000-0000-0000-000000000031';
 original jsonb; details jsonb; order_id uuid; ordered timestamptz;
begin
 if has_function_privilege('anon','public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean)','EXECUTE')
 or has_function_privilege('authenticated','public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean)','EXECUTE')
 or not has_function_privilege('service_role','public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean)','EXECUTE') then
 raise exception 'Metadata RPC grants are unsafe'; end if;
 insert into auth.users(id) values(actor),(other_actor);
 insert into auth.sessions(id,user_id,aal,not_after) values(session,actor,'aal1',now()+interval '1 day'),(other_session,other_actor,'aal1',now()+interval '1 day');
 insert into public.courses(id,slug,title,price_minor,status,published_at) values(course,'com013-synthetic','Synthetic Course',12345,'published',now());
 insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name) values(bank,bank,1,'Synthetic Bank','Synthetic Holder','TEST-ONLY','Synthetic Branch');
 original:=public.csa265_create_checkout_order(actor,session,'aal1','com013-test',course,'bank_transfer',bank)->'data';
 order_id:=(original->>'order_id')::uuid;
 select created_at into ordered from public.orders where id=order_id;
 details:=public.csa179_read_bank_transfer(actor,session,'aal1',order_id,false);
 if details->>'amount_minor' is distinct from '12345'
 or jsonb_typeof(details->'amount_minor') is distinct from 'string'
 or details->>'currency' is distinct from 'LKR'
 or (details->>'order_created_at')::timestamptz is distinct from ordered
 or details->>'status' is distinct from 'awaiting_receipt' then
   raise exception 'Owner metadata must match the immutable order, with an exact string amount'; end if;
 if details ?| array['object_path','verified_credit','buyer_id','bank_instructions'] then
   raise exception 'Status exposed private data'; end if;
 insert into public.bank_transfer_submissions(order_id,submitted_by) values(order_id,actor);
 details:=public.csa179_read_bank_transfer(actor,session,'aal1',order_id,false);
 if details->>'submission_id' is null or details->>'amount_minor' is distinct from '12345'
 or (details->>'order_created_at')::timestamptz is distinct from ordered then
   raise exception 'Latest-submission reads must retain exact immutable order metadata'; end if;
 begin
   perform public.csa179_read_bank_transfer(other_actor,other_session,'aal1',order_id,false);
   raise exception 'Cross-user metadata read succeeded';
 exception when sqlstate 'P0002' then null; end;
 begin
   perform public.csa179_read_bank_transfer(actor,session,'aal1','27800000-0000-0000-0000-000000000099',false);
   raise exception 'Missing-order read succeeded';
 exception when sqlstate 'P0002' then null; end;
 begin
   perform public.csa179_read_bank_transfer(actor,session,'aal1',null,true);
   raise exception 'Student accessed finance queue';
 exception when sqlstate '42501' then null; end;
 update auth.sessions set not_after=now()-interval '1 second' where id=session;
 begin
   perform public.csa179_read_bank_transfer(actor,session,'aal1',order_id,false);
   raise exception 'Expired session exposed metadata';
 exception when sqlstate '42501' then null; end;
 if exists(select 1 from public.enrollments where user_id=actor and course_id=course) then
   raise exception 'Metadata read granted access'; end if;
end $$;
select 'ok 1 - owner-only exact amount/order date with grants, session and finance isolation retained';
rollback;
