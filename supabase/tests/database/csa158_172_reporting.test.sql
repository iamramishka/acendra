begin;
select '1..1';
do $$
declare admin uuid:=gen_random_uuid(); finance uuid:=gen_random_uuid(); manager uuid:=gen_random_uuid(); student uuid:=gen_random_uuid();
 ads uuid:=gen_random_uuid(); fs uuid:=gen_random_uuid(); ms uuid:=gen_random_uuid(); ss uuid:=gen_random_uuid(); c uuid:=gen_random_uuid(); other uuid:=gen_random_uuid(); r jsonb; before_count bigint; oid uuid:=gen_random_uuid();
begin
 insert into auth.users(id) values(admin),(finance),(manager),(student);
 insert into auth.sessions(id,user_id,aal,not_after) values(ads,admin,'aal2',now()+interval '1 day'),(fs,finance,'aal2',now()+interval '1 day'),(ms,manager,'aal1',now()+interval '1 day'),(ss,student,'aal1',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select admin,id from public.roles where code='super_admin';
 insert into public.user_roles(user_id,role_id) select finance,id from public.roles where code='finance_admin';
 insert into public.user_roles(user_id,role_id) select manager,id from public.roles where code='content_manager';
 insert into public.courses(id,slug,title,price_minor,status,published_at) values(c,'report-'||c,'Synthetic',100,'published',now()),(other,'report-'||other,'Other',100,'published',now());
 insert into public.course_staff(course_id,user_id,staff_role,assigned_by) values(c,manager,'editor',admin);
 r:=public.csa158_dashboard_stats(manager,ms,'aal1','last_30_days');
 if r->>'published_courses'<>'1' or r ? 'registered_students' or r ? 'confirmed_receipts' or r ? 'pending_bank_reviews' or r ? 'active_enrollments' then raise exception 'manager metric disclosure'; end if;
 r:=public.csa158_dashboard_stats(finance,fs,'aal2','last_30_days');
 if r ? 'registered_students' or r ? 'active_enrollments' or r ? 'total_courses' or not r ? 'confirmed_receipts' then raise exception 'finance metric disclosure'; end if;
 begin perform public.csa158_dashboard_stats(student,ss,'aal1','last_30_days');raise exception 'student allowed';exception when insufficient_privilege then null;end;
 begin perform public.csa158_dashboard_stats(admin,ads,'aal1','last_30_days');raise exception 'MFA bypass';exception when insufficient_privilege then null;end;
 begin perform public.csa172_financial_report(manager,ms,'aal1','2026-01-01','2026-01-01','LKR');raise exception 'manager finance allowed';exception when insufficient_privilege then null;end;
 begin perform public.csa172_financial_report(finance,fs,'aal2','2026-01-02','2026-01-01','LKR');raise exception 'reverse range';exception when invalid_parameter_value then null;end;
 begin perform public.csa172_financial_report(finance,fs,'aal2','2026-01-01','2026-01-01','USD');raise exception 'currency';exception when invalid_parameter_value then null;end;
 r:=public.csa158_dashboard_stats(admin,ads,'aal2','last_30_days');before_count:=(r->>'active_enrollments')::bigint;
 perform public.csa116_grant_admin(admin,ads,'aal2','report-grant',student,c,'Synthetic',null);
 r:=public.csa158_dashboard_stats(admin,ads,'aal2','last_30_days');if (r->>'active_enrollments')::bigint<>before_count+1 then raise exception 'effective grant missing';end if;
 update auth.users set banned_until=clock_timestamp()+interval '1 day' where id=student;
 r:=public.csa158_dashboard_stats(admin,ads,'aal2','last_30_days');if (r->>'active_enrollments')::bigint<>before_count then raise exception 'banned account counted active';end if;
 update auth.users set banned_until=null where id=student;
 perform public.csa118_revoke_access(admin,ads,'aal2','report-revoke',student,c,null,'course','Synthetic');
 r:=public.csa158_dashboard_stats(admin,ads,'aal2','last_30_days');if (r->>'active_enrollments')::bigint<>before_count then raise exception 'restriction ignored';end if;
 -- Receipt facts include additional verified receipts exactly once; they do
 -- not represent additional sales. Pending orders/attempt labels cannot inflate them.
 insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status) values(oid,'R-'||oid,student,c,'Synthetic',9007199254740993,'LKR','online','pending_payment');
 insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
 values(oid,'online',9007199254740993,'LKR','payhere','synthetic','production','receipt-one','provider_retrieval','synthetic','2026-01-01T18:30:00Z'),
 (oid,'online',9007199254740993,'LKR','payhere','synthetic','production','receipt-two','provider_retrieval','synthetic','2026-01-02T18:29:59Z'),
 (oid,'online',9007199254740993,'LKR','payhere','synthetic','sandbox','sandbox','provider_retrieval','synthetic','2026-01-01T18:30:00Z'),
 (oid,'online',9007199254740993,'LKR','payhere','synthetic','production','next-day','provider_retrieval','synthetic','2026-01-02T18:30:00Z');
 r:=public.csa172_financial_report(finance,fs,'aal2','2026-01-02','2026-01-02','LKR');
 if r->>'confirmed_amount_minor'<>'18014398509481986' or r->>'confirmed_settlements'<>'2' or r ? 'net_amount_minor' or r ? 'refunded_amount_minor' then raise exception 'settlement precision/date/sandbox/definition';end if;
 if r->>'gross_receipts_minor'<>r->>'confirmed_amount_minor' or r->>'recognition_status'<>'approved' or r->>'net_status'<>'confirmed_adjustment_ledger_unavailable' then raise exception 'approved recognition or unavailable net';end if;
 update public.orders set status='refunded',paid_at=clock_timestamp() where id=oid;
 begin perform public.csa172_financial_report(finance,fs,'aal2','2026-01-02','2026-01-02','LKR');raise exception 'invented refund zero';exception when object_not_in_prerequisite_state then null;end;
 update public.user_roles set revoked_at=clock_timestamp() where user_id=finance;
 begin perform public.csa158_dashboard_stats(finance,fs,'aal2','last_30_days');raise exception 'stale finance token';exception when insufficient_privilege then null;end;
 update public.course_staff set revoked_at=clock_timestamp() where course_id=c;
 r:=public.csa158_dashboard_stats(manager,ms,'aal1','last_30_days');if r->>'published_courses'<>'0' then raise exception 'stale assignment';end if;
 if has_function_privilege('authenticated','public.csa158_dashboard_stats(uuid,uuid,text,text)','execute') or has_function_privilege('anon','public.csa172_financial_report(uuid,uuid,text,date,date,text)','execute') then raise exception 'public RPC grants';end if;
 update auth.sessions set not_after=clock_timestamp()-interval '1 second' where id=ads;
 begin perform public.csa158_dashboard_stats(admin,ads,'aal2','last_30_days');raise exception 'expired session';exception when insufficient_privilege then null;end;
end; $$;
select 'ok 1 - current reporting authority, omission, scope, MFA, range and entitlement';
rollback;
