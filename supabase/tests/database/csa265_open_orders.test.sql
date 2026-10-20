begin;
select '1..1';
do $$
declare
 buyer uuid:=gen_random_uuid(); other_buyer uuid:=gen_random_uuid();
 session_id uuid:=gen_random_uuid(); other_session uuid:=gen_random_uuid();
 course uuid:=gen_random_uuid(); other_course uuid:=gen_random_uuid();
 bank uuid:=gen_random_uuid(); first_order jsonb; replay jsonb; result jsonb;
begin
 insert into auth.users(id) values(buyer),(other_buyer);
 insert into auth.sessions(id,user_id,aal,not_after) values
 (session_id,buyer,'aal1',now()+interval '1 day'),
 (other_session,other_buyer,'aal1',now()+interval '1 day');
 insert into public.courses(id,slug,title,price_minor,status,published_at) values
 (course,'guard-'||course,'Synthetic course',12345,'published',now()),
 (other_course,'guard-'||other_course,'Other synthetic course',12345,'published',now());
 insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name)
 values(bank,gen_random_uuid(),1,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','Synthetic branch');
 first_order:=public.csa265_create_checkout_order(buyer,session_id,'aal1','first',course,'online');
 if first_order->'data'->>'status' is distinct from 'pending_payment' or
 (first_order->'data'->>'amount_minor')::bigint<>12345 then raise exception 'authoritative pending order'; end if;
 replay:=public.csa265_create_checkout_order(buyer,session_id,'aal1','first',course,'online');
 if replay->>'replayed' is distinct from 'true' or replay->'data' is distinct from first_order->'data' then raise exception 'identical replay'; end if;
 begin
 perform public.csa265_create_checkout_order(buyer,session_id,'aal1','second',course,'online');
 raise exception 'duplicate online order accepted';
 exception when invalid_parameter_value then null; end;
 begin
 perform public.csa265_create_checkout_order(buyer,session_id,'aal1','bank',course,'bank_transfer',bank);
 raise exception 'duplicate bank order accepted';
 exception when invalid_parameter_value then null; end;
 result:=public.csa265_create_checkout_order(other_buyer,other_session,'aal1','first',course,'online');
 if result->>'replayed' is distinct from 'false' then raise exception 'buyer isolation'; end if;
 result:=public.csa265_create_checkout_order(buyer,session_id,'aal1','other',other_course,'online');
 if result->>'replayed' is distinct from 'false' then raise exception 'course isolation'; end if;
 update public.orders set status='cancelled' where id=(first_order->'data'->>'order_id')::uuid;
 result:=public.csa265_create_checkout_order(buyer,session_id,'aal1','after-cancel',course,'online');
 if result->>'replayed' is distinct from 'false' then raise exception 'new purchase after cancellation'; end if;
 if has_function_privilege('authenticated','public.csa265_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid)','EXECUTE') or
 has_function_privilege('anon','public.csa265_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid)','EXECUTE') or
 not has_function_privilege('service_role','public.csa265_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid)','EXECUTE') then raise exception 'trusted-only permission boundary'; end if;
 begin
 perform public.csa265_create_checkout_order(buyer,other_session,'aal1','forged-session',course,'online');
 raise exception 'foreign session accepted'; exception when insufficient_privilege then null; end;
 update auth.sessions set not_after=now()-interval '1 second' where id=session_id;
 begin
 perform public.csa265_create_checkout_order(buyer,session_id,'aal1','first',course,'online');
 raise exception 'expired session replay accepted'; exception when insufficient_privilege then null; end;
 if exists(select 1 from public.enrollments where user_id=buyer) then raise exception 'creation granted enrollment'; end if;
end $$;
select 'ok 1 - checkout creation guards open orders, isolates buyers, preserves replay and never grants access';
rollback;