-- Synthetic transactional schema checks. Helpers never leave this transaction.
begin;
create temporary sequence csa077_assertion;
grant usage, select on sequence csa077_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa077_assertion') || ' - ' || description;
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
select pg_temp.assert_ok((select count(*) = 2 from pg_class where oid in
  ('public.categories'::regclass,'public.courses'::regclass) and relrowsecurity), 'RLS enabled');
insert into public.categories(id,name,slug) values
  ('07700000-0000-0000-0000-000000000001','Synthetic category','synthetic-category');
insert into public.courses(id,category_id,slug,title,price_minor,created_at,updated_at) values
  ('07700000-0000-0000-0000-000000000002','07700000-0000-0000-0000-000000000001',
   'synthetic-course','Synthetic course',0,now()-interval '1 day',now()-interval '1 day');
select pg_temp.assert_ok((select status='draft' and currency_code='LKR' and published_at is null
  from public.courses where slug='synthetic-course'), 'safe course defaults');
select pg_temp.assert_ok((select sort_order=0 and is_active and created_at=updated_at
  from public.categories where slug='synthetic-category'), 'category defaults');
select pg_temp.expect_error($q$update public.categories set name=chr(9)||chr(10)||' ' where slug='synthetic-category'$q$, '23514', 'control whitespace-only category rejected');
select pg_temp.expect_error($q$update public.courses set title=chr(13)||' ' where slug='synthetic-course'$q$, '23514', 'control whitespace-only title rejected');
select pg_temp.expect_error($q$update public.courses set title=null where slug='synthetic-course'$q$, '23502', 'null title rejected');
select pg_temp.expect_error($q$update public.categories set sort_order=-1 where slug='synthetic-category'$q$, '23514', 'negative category order rejected');
select pg_temp.expect_error($q$update public.courses set price_minor=-1 where slug='synthetic-course'$q$, '23514', 'negative price rejected');
select pg_temp.expect_error($q$update public.courses set currency_code='USD' where slug='synthetic-course'$q$, '23514', 'unsupported currency rejected');
insert into auth.users(id) values('07700000-0000-0000-0000-000000000003');
insert into public.profiles(id,display_name) values('07700000-0000-0000-0000-000000000003','Synthetic author');
update public.courses set created_by='07700000-0000-0000-0000-000000000003' where slug='synthetic-course';
select pg_temp.expect_error($q$delete from public.profiles where id='07700000-0000-0000-0000-000000000003'$q$,'23503','course author deletion cannot cascade course');
update public.categories set name='Updated category' where slug='synthetic-category';
select pg_temp.assert_ok((select updated_at>=created_at and name='Updated category' from public.categories where slug='synthetic-category'),'category update supported');
select pg_temp.assert_ok((select count(*)=4 from pg_indexes where schemaname='public' and indexname in
('categories_listing_idx','courses_category_id_idx','courses_created_by_idx','courses_publication_idx')),'listing and foreign-key indexes present');
select pg_temp.expect_error($q$update public.courses set status='pending' where slug='synthetic-course'$q$, '23514', 'unknown state rejected');
select pg_temp.expect_error($q$update public.courses set status='published' where slug='synthetic-course'$q$, '23514', 'publication timestamp required');
select pg_temp.expect_error($q$update public.courses set category_id='07700000-0000-0000-0000-000000000099' where slug='synthetic-course'$q$, '23503', 'unknown category rejected');
select pg_temp.expect_error($q$update public.courses set created_by='07700000-0000-0000-0000-000000000099' where slug='synthetic-course'$q$, '23503', 'unknown author rejected');
select pg_temp.expect_error($q$delete from public.categories where slug='synthetic-category'$q$, '23503', 'category deletion cannot cascade courses');
select pg_temp.expect_error($q$insert into public.courses(slug,title,price_minor) values('synthetic-course','Duplicate',1)$q$, '23505', 'course slug unique');
select pg_temp.expect_error($q$insert into public.categories(slug,name) values('synthetic-category','Duplicate')$q$, '23505', 'category slug unique');
-- Validate both slug columns against noncanonical values.
select pg_temp.expect_error(format('update public.%I set slug=%L where slug=%L',t,s,case t when 'courses' then 'synthetic-course' else 'synthetic-category' end),'23514',t||' rejects noncanonical slug case '||ordinality)
from unnest(array['categories','courses']) as tables(t)
cross join unnest(array['','Upper',' spaced','trailing-','double--dash','under_score',chr(10),repeat('a',201)]) with ordinality as slugs(s,ordinality);
select pg_temp.expect_error($q$update public.categories set name=repeat('a',201) where slug='synthetic-category'$q$,'23514','overlong name rejected');
select pg_temp.expect_error($q$update public.courses set title=repeat('a',201) where slug='synthetic-course'$q$,'23514','overlong title rejected');
select pg_temp.expect_error($q$update public.categories set created_at=now()+interval '1 day' where slug='synthetic-category'$q$,'23514','category timestamp order enforced');
select pg_temp.expect_error($q$update public.courses set created_at=now()+interval '1 day' where slug='synthetic-course'$q$,'23514','course timestamp order enforced');
select pg_temp.expect_error($q$update public.courses set thumbnail_path=chr(9) where slug='synthetic-course'$q$,'23514','blank thumbnail rejected');
select pg_temp.assert_ok(not has_function_privilege(r,'public.csa077_set_updated_at()','EXECUTE'),r||' cannot call timestamp trigger')
from unnest(array['anon','authenticated','service_role']) as roles(r);
select pg_temp.assert_ok((select data_type='bigint' from information_schema.columns where table_schema='public'
  and table_name='courses' and column_name='price_minor'), 'exact BIGINT price storage');
update public.courses set price_minor=9223372036854775807,status='published',published_at=now(),title='Unicode 名' where slug='synthetic-course';
select pg_temp.assert_ok((select updated_at>created_at and status='published' from public.courses where slug='synthetic-course'), 'valid publication and timestamp trigger');
update public.courses set status='archived' where slug='synthetic-course';
select pg_temp.assert_ok((select status='archived' from public.courses where slug='synthetic-course'), 'archive preserves metadata');
select '1..' || last_value from pg_temp.csa077_assertion;
rollback;
