-- Incoming COM-021 private avatar storage must preserve cross-account isolation.
begin;
select '1..1';
insert into auth.users(id,email) values
 ('02100000-0000-4000-8000-000000000001','avatar-a@synthetic.test'),
 ('02100000-0000-4000-8000-000000000002','avatar-b@synthetic.test');
insert into storage.objects(bucket_id,name) values
 ('avatars','02100000-0000-4000-8000-000000000001/avatar'),
 ('avatars','02100000-0000-4000-8000-000000000002/avatar');
select set_config('request.jwt.claims','{"sub":"02100000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select set_config('request.jwt.claim.sub','02100000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$
declare changed integer;
begin
 if (select count(*) from storage.objects where bucket_id='avatars')<>1 then raise exception 'Foreign avatar visible';end if;
 if not exists(select 1 from storage.objects where bucket_id='avatars' and name='02100000-0000-4000-8000-000000000001/avatar') then raise exception 'Own avatar unavailable';end if;
 insert into storage.objects(bucket_id,name) values('avatars','02100000-0000-4000-8000-000000000001/new-photo');
 begin insert into storage.objects(bucket_id,name) values('avatars','02100000-0000-4000-8000-000000000002/forged');raise exception 'Foreign upload accepted';exception when insufficient_privilege then null;end;
 update public.profiles set avatar_path='02100000-0000-4000-8000-000000000001/avatar'
  where id='02100000-0000-4000-8000-000000000001';
 get diagnostics changed=row_count;
 if changed<>1 then raise exception 'Own avatar profile not updated';end if;
 begin update public.profiles set avatar_path='02100000-0000-4000-8000-000000000002/avatar'
  where id='02100000-0000-4000-8000-000000000001';raise exception 'Foreign avatar reference accepted';exception when check_violation then null;end;
 update public.profiles set avatar_path='02100000-0000-4000-8000-000000000001/avatar'
  where id='02100000-0000-4000-8000-000000000002';
 get diagnostics changed=row_count;
 if changed<>0 then raise exception 'Foreign avatar profile changed';end if;
 update storage.objects set name='02100000-0000-4000-8000-000000000001/stolen'
  where bucket_id='avatars' and name='02100000-0000-4000-8000-000000000002/avatar';
 get diagnostics changed=row_count;
 if changed<>0 then raise exception 'Foreign avatar object changed';end if;
end; $$;
reset role;
do $$ begin
 if not exists(select 1 from storage.objects where bucket_id='avatars' and name='02100000-0000-4000-8000-000000000002/avatar')
  or (select avatar_path from public.profiles where id='02100000-0000-4000-8000-000000000002') is not null then raise exception 'Foreign avatar history was altered';end if;
 if exists(select 1 from storage.buckets where id='avatars' and public) then raise exception 'Avatar bucket became public';end if;
end; $$;
select 'ok 1 - Private avatars enforce own-folder storage, own-row updates and foreign-path denial';
rollback;
