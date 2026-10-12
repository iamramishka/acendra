-- Additive, read-only staff reporting. No financial state mutations.
begin;
create function app_private.csa158_reporting_roles(p_actor uuid,p_session_id uuid,p_aal text)
returns text[] language plpgsql security definer set search_path='' as $$
declare roles text[];
begin
 perform pg_catalog.pg_advisory_xact_lock(610061);
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,false);
 select array_agg(r.code) into roles from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p_actor and ur.revoked_at is null;
 if not coalesce(roles&&array['content_manager','finance_admin','super_admin'],false) then raise exception using errcode='42501',message='Staff authority required.'; end if;
 if roles&&array['finance_admin','super_admin'] and p_aal<>'aal2' then raise exception using errcode='42501',message='Verified MFA required.'; end if;
 return roles;
end; $$;
create function app_private.csa172_settlement_facts(p_from timestamptz,p_to timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 -- Financial adjustments are not implemented in this baseline. Never claim
 -- zero refunds/net income if imported history contains unsupported outcomes.
 if exists(select 1 from public.orders where status='refunded') then raise exception using errcode='55000',message='Confirmed adjustment reporting unavailable.'; end if;
 select jsonb_build_object('basis','verified_settlement_receipts','currency_code','LKR',
 'confirmed_settlements',count(*)::text,'confirmed_amount_minor',coalesce(sum(s.amount_minor),0)::text,'environment_basis','production_online_and_verified_bank',
 'revenue_status','definition_pending','refunds_status','adjustment_reporting_unavailable','net_status','definition_pending') into result
 from app_private.verified_settlements s where s.confirmed_at>=p_from and s.confirmed_at<p_to and (s.method='bank_transfer' or s.provider_environment='production');
 return result;
end; $$;
create function public.csa158_dashboard_stats(p_actor uuid,p_session_id uuid,p_aal text,p_period text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare roles text[]; result jsonb:='{}'; n bigint; boundary timestamptz:=statement_timestamp();
begin
 roles:=app_private.csa158_reporting_roles(p_actor,p_session_id,p_aal);
 if p_period is distinct from 'last_30_days' then raise exception using errcode='22023',message='Unsupported reporting period.'; end if;
 if roles&&array['content_manager','super_admin'] then
  select count(*) into n from public.courses c where c.status='published' and c.published_at is not null and ('super_admin'=any(roles) or exists(select 1 from public.course_staff cs where cs.course_id=c.id and cs.user_id=p_actor and cs.revoked_at is null));
  result:=result||jsonb_build_object('published_courses',n::text);
  select count(*) into n from public.courses c where 'super_admin'=any(roles) or exists(select 1 from public.course_staff cs where cs.course_id=c.id and cs.user_id=p_actor and cs.revoked_at is null);
  result:=result||jsonb_build_object('total_courses',n::text);
 end if;
 if 'super_admin'=any(roles) then
  select count(*) into n from public.profiles p join auth.users u on u.id=p.id where u.deleted_at is null and not coalesce(u.is_anonymous,false) and (exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p.id and ur.revoked_at is null and r.code='student') or not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p.id and ur.revoked_at is null and r.code in ('content_manager','finance_admin','super_admin')));
  result:=result||jsonb_build_object('registered_students',n::text);
  select count(*) into n from public.enrollments e join auth.users u on u.id=e.user_id where u.deleted_at is null and not coalesce(u.is_anonymous,false) and (u.banned_until is null or u.banned_until<=clock_timestamp()) and app_private.csa117_has_access(e.user_id,e.course_id);
  result:=result||jsonb_build_object('active_enrollments',n::text);
 end if;
 if roles&&array['finance_admin','super_admin'] then
  select count(*) into n from public.bank_transfer_submissions b join public.orders o on o.id=b.order_id where b.status in ('submitted','under_review') and o.status='pending_verification';
  result:=result||jsonb_build_object('pending_bank_reviews',n::text,'confirmed_receipts',app_private.csa172_settlement_facts(boundary-interval '30 days',boundary));
 end if;
 return result||jsonb_build_object('as_of',boundary,'period',p_period,'count_basis','current_snapshot');
end; $$;
create function public.csa172_financial_report(p_actor uuid,p_session_id uuid,p_aal text,p_from date,p_to date,p_currency text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare roles text[]; start_time timestamptz; end_time timestamptz;
begin
 roles:=app_private.csa158_reporting_roles(p_actor,p_session_id,p_aal);
 if not roles&&array['finance_admin','super_admin'] then raise exception using errcode='42501',message='Finance authority required.'; end if;
 if p_from is null or p_to is null or not isfinite(p_from) or not isfinite(p_to) or p_to<p_from or p_to-p_from>365 or p_currency is distinct from 'LKR' then raise exception using errcode='22023',message='Invalid reporting range or currency.'; end if;
 start_time:=p_from::timestamp at time zone 'Asia/Colombo';end_time:=(p_to+1)::timestamp at time zone 'Asia/Colombo';
 return app_private.csa172_settlement_facts(start_time,end_time)||jsonb_build_object('from',p_from,'to',p_to,'timezone','Asia/Colombo','end_exclusive',end_time);
end; $$;
revoke all on function app_private.csa158_reporting_roles(uuid,uuid,text),app_private.csa172_settlement_facts(timestamptz,timestamptz),public.csa158_dashboard_stats(uuid,uuid,text,text),public.csa172_financial_report(uuid,uuid,text,date,date,text) from public,anon,authenticated,service_role;
grant execute on function public.csa158_dashboard_stats(uuid,uuid,text,text),public.csa172_financial_report(uuid,uuid,text,date,date,text) to service_role;
commit;
