begin;
select '1..1';
-- Prove restrictive denial survives an accidental permissive storage policy.
create policy csa139_test_permissive on storage.objects for all to anon,authenticated using(true) with check(true);
create policy csa139_test_bucket_permissive on storage.buckets for all to anon,authenticated using(true) with check(true);
do $$
declare asset uuid:=gen_random_uuid(); object_id uuid; role_name text;
 object_name text; unsafe text;
begin
 if not exists(select 1 from storage.buckets where id='course-pdfs' and not public and file_size_limit=52428800 and allowed_mime_types=array['application/pdf']) then raise exception 'bucket configuration'; end if;
 object_name:='originals/'||asset||'/v1.pdf';
 insert into storage.objects(bucket_id,name) values('course-pdfs',object_name) returning id into object_id;
 insert into storage.objects(bucket_id,name) values('course-pdfs','derivatives/'||asset||'/v2/'||gen_random_uuid()||'/'||gen_random_uuid()||'.pdf');
 foreach unsafe in array array['private.pdf','originals/'||asset||'/v0.pdf','originals/'||asset||'/v1.pdf/../secret.pdf','originals/'||asset||'/v1.png','originals/'||upper(asset::text)||'/v1.pdf'] loop
  begin insert into storage.objects(bucket_id,name) values('course-pdfs',unsafe); raise exception 'unsafe path accepted'; exception when check_violation then null; end;
 end loop;
 begin update storage.objects set name=object_name||'.pdf' where id=object_id; raise exception 'rewrite accepted'; exception when check_violation then null; end;
 begin update storage.buckets set public=true where id='course-pdfs'; raise exception 'public accepted'; exception when check_violation then null; end;
 begin update storage.buckets set file_size_limit=null where id='course-pdfs'; raise exception 'unbounded accepted'; exception when check_violation then null; end;
 begin update storage.buckets set allowed_mime_types=array['application/pdf','image/png'] where id='course-pdfs'; raise exception 'unsafe MIME accepted'; exception when check_violation then null; end;
 foreach role_name in array array['anon','authenticated'] loop
  execute format('set local role %I',role_name);
  if exists(select 1 from storage.buckets where id='course-pdfs') then raise exception 'private bucket metadata leaked'; end if;
  if exists(select 1 from storage.objects where bucket_id='course-pdfs') then raise exception 'private object list/read leaked'; end if;
  begin insert into storage.objects(bucket_id,name) values('course-pdfs','originals/'||gen_random_uuid()||'/v1.pdf'); raise exception 'client upload accepted'; exception when insufficient_privilege then null; end;
  update storage.objects set name='changed.pdf' where id=object_id;
  delete from storage.objects where id=object_id;
  reset role;
  if not exists(select 1 from storage.objects where id=object_id) then raise exception 'client deletion succeeded'; end if;
 end loop;
end; $$;
select 'ok 1 - private PDF bucket, restrictive direct denial, opaque paths, immutable objects and safe configuration';
rollback;
