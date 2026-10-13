-- A deferred trigger must retain its invariant authority after the RPC returns.
begin;
create function pg_temp.assert_ok(c boolean,d text) returns text language plpgsql as $$
begin if c is distinct from true then raise exception 'Assertion failed: %',d; end if; return d; end;$$;
insert into auth.users(id) values('17800000-0000-0000-0000-000000000001');
insert into auth.sessions(id,user_id,aal,not_after) values
 ('17800000-0000-0000-0000-000000000002','17800000-0000-0000-0000-000000000001','aal1',now()+interval '1 day');
insert into public.courses(id,slug,title,price_minor,status,published_at) values
 ('17800000-0000-0000-0000-000000000003','csa178-deferred','Synthetic deferred check',12345,'published',now());
set local role service_role;
do $$begin
 perform public.csa098_create_checkout_order('17800000-0000-0000-0000-000000000001',
 '17800000-0000-0000-0000-000000000002','aal1','csa178-deferred-order',
 '17800000-0000-0000-0000-000000000003','online');
end;$$;
-- Before migration034 this raises42501: permission denied for table orders.
set constraints all immediate;
reset role;
select '1..4';
select pg_temp.assert_ok((select count(*)=1 from public.orders where buyer_id='17800000-0000-0000-0000-000000000001')
 and not exists(select 1 from public.enrollment_grants where user_id='17800000-0000-0000-0000-000000000001'),
 'ok 1 - restricted trusted RPC completes deferred checks without paid access');
select pg_temp.assert_ok((select count(*)=2 from pg_proc where oid in
 ('app_private.csa096_require_paid_settlement()'::regprocedure,'app_private.csa096_require_grant_fulfillment()'::regprocedure)
 and prosecdef and proconfig @> array['search_path=""']),
 'ok 2 - only trusted empty-search-path deferred check functions are definers');
select pg_temp.assert_ok(not has_table_privilege('service_role','public.orders','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('authenticated','public.orders','INSERT,UPDATE,DELETE'),
 'ok 3 - API roles gain no direct financial write or service read privileges');
select pg_temp.assert_ok(not exists(select 1 from unnest(array['anon','authenticated','service_role']) r
 cross join unnest(array['app_private.csa096_require_paid_settlement()'::regprocedure,
 'app_private.csa096_require_grant_fulfillment()'::regprocedure]) f where has_function_privilege(r,f,'EXECUTE')),
 'ok 4 - deferred checks are not directly client or service executable');
rollback;
