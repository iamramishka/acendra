begin;
select '1..1';
do $$
declare actor uuid='27600000-0000-0000-0000-000000000001';
 other_actor uuid='27600000-0000-0000-0000-000000000002';
 session uuid='27600000-0000-0000-0000-000000000011';
 other_session uuid='27600000-0000-0000-0000-000000000012';
 course uuid='27600000-0000-0000-0000-000000000021';
 bank uuid='27600000-0000-0000-0000-000000000031';
 original jsonb; recovered jsonb; order_id uuid;
begin
 if has_function_privilege('anon','public.csa276_read_bank_instructions(uuid,uuid,text,uuid)','EXECUTE')
 or has_function_privilege('authenticated','public.csa276_read_bank_instructions(uuid,uuid,text,uuid)','EXECUTE')
 or not has_function_privilege('service_role','public.csa276_read_bank_instructions(uuid,uuid,text,uuid)','EXECUTE') then
 raise exception 'Instructions RPC grants are unsafe'; end if;
 insert into auth.users(id) values(actor),(other_actor);
 insert into auth.sessions(id,user_id,aal,not_after) values(session,actor,'aal1',now()+interval '1 day'),(other_session,other_actor,'aal1',now()+interval '1 day');
 insert into public.courses(id,slug,title,price_minor,status,published_at) values(course,'com012-synthetic','Synthetic Course',12345,'published',now());
 insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name) values(bank,bank,1,'Synthetic Bank','Synthetic Holder','TEST-ONLY','Synthetic Branch');
 original:=public.csa265_create_checkout_order(actor,session,'aal1','com012-test',course,'bank_transfer',bank)->'data';
 order_id:=(original->>'order_id')::uuid;
 recovered:=public.csa276_read_bank_instructions(actor,session,'aal1',order_id);
 if recovered is distinct from original then raise exception 'Recovered instructions must match immutable checkout snapshot'; end if;
 begin
   perform public.csa276_read_bank_instructions(other_actor,other_session,'aal1',order_id);
   raise exception 'Cross-user read succeeded';
 exception when sqlstate 'P0002' then null; end;
 begin
   perform public.csa276_read_bank_instructions(actor,session,'aal1','27600000-0000-0000-0000-000000000099');
   raise exception 'Missing order read succeeded';
 exception when sqlstate 'P0002' then null; end;
 if exists(select 1 from public.enrollments where user_id=actor and course_id=course) then raise exception 'Read granted access'; end if;
 update public.orders set status='pending_verification' where id=order_id;
 begin
   perform public.csa276_read_bank_instructions(actor,session,'aal1',order_id);
   raise exception 'Non-payable order exposed transfer instructions';
 exception when sqlstate 'P0002' then null; end;
 update auth.sessions set not_after=now()-interval '1 second' where id=session;
 begin
   perform public.csa276_read_bank_instructions(actor,session,'aal1',order_id);
   raise exception 'Expired session read succeeded';
 exception when sqlstate '42501' then null; end;
 raise notice 'COM-012: grants, snapshot recovery, cross-user, missing order, no entitlement, stale status and expired session checks passed';
end $$;
select 'ok 1 - immutable instructions recover only for current owner sessions and payable bank orders without granting access';
rollback;
