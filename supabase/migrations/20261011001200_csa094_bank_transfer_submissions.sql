-- CSA-094: evidence records only; receipt submission never fulfills an order.
begin;
create table public.bank_transfer_submissions (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete restrict,
 submitted_by uuid not null references public.profiles(id) on delete restrict,
 receipt_asset_id uuid references app_private.media_assets(id) on delete restrict,
 status text not null default 'awaiting_receipt',
 submitted_at timestamptz,
 reviewed_by uuid references public.profiles(id) on delete restrict,
 reviewed_at timestamptz,
 public_rejection_reason text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint bank_submissions_status check (status in ('awaiting_receipt','submitted','under_review','approved','rejected')),
 constraint bank_submissions_receipt_shape check (status = 'awaiting_receipt' or (receipt_asset_id is not null and submitted_at is not null)),
 constraint bank_submissions_review_shape check (
   (status in ('approved','rejected') and reviewed_by is not null and reviewed_at is not null)
   or (status not in ('approved','rejected') and reviewed_by is null and reviewed_at is null)
 ),
 constraint bank_submissions_independent_review check (reviewed_by is null or reviewed_by <> submitted_by),
 constraint bank_submissions_rejection_reason check (
   (status='rejected' and public_rejection_reason is not null and length(public_rejection_reason) between 1 and 1000 and public_rejection_reason ~ '[^[:space:]]')
   or (status<>'rejected' and public_rejection_reason is null)
 ),
 constraint bank_submissions_time check (
   (submitted_at is null or submitted_at >= created_at)
   and (reviewed_at is null or reviewed_at >= submitted_at)
 )
);
create unique index bank_submissions_one_active_order_idx
 on public.bank_transfer_submissions(order_id)
 where status in ('awaiting_receipt','submitted','under_review');
create index bank_submissions_order_created_idx on public.bank_transfer_submissions(order_id,created_at);
create index bank_submissions_submitter_idx on public.bank_transfer_submissions(submitted_by);
create index bank_submissions_reviewer_idx on public.bank_transfer_submissions(reviewed_by);
create index bank_submissions_receipt_idx on public.bank_transfer_submissions(receipt_asset_id);
create index bank_submissions_review_queue_idx on public.bank_transfer_submissions(status,submitted_at);
create function app_private.csa094_validate_submission()
returns trigger language plpgsql set search_path='' as $$
begin
 if not exists (select 1 from public.orders o where o.id=new.order_id
   and o.buyer_id=new.submitted_by and o.payment_method='bank_transfer') then
   raise exception 'Submission must match the bank order purchaser.' using errcode='23514';
 end if;
 if new.receipt_asset_id is not null and not exists (
   select 1 from app_private.media_assets a where a.id=new.receipt_asset_id
   and a.asset_type='bank_receipt' and a.uploaded_by=new.submitted_by
   and a.validation_status='validated' and a.validated_at is not null and a.deleted_at is null
 ) then
   raise exception 'Receipt must be a validated available asset owned by the purchaser.' using errcode='23514';
 end if;
 if tg_op='UPDATE' then
   if row(new.id,new.order_id,new.submitted_by,new.created_at)
      is distinct from row(old.id,old.order_id,old.submitted_by,old.created_at)
      or (old.receipt_asset_id is not null and new.receipt_asset_id is distinct from old.receipt_asset_id)
      or (old.submitted_at is not null and new.submitted_at is distinct from old.submitted_at)
      or old.status in ('approved','rejected') then
     raise exception 'Submission identity and completed review evidence are immutable; resubmit a new record.' using errcode='23514';
   end if;
   new.updated_at:=statement_timestamp();
 end if;
 return new;
end;
$$;
create trigger bank_submissions_validate before insert or update on public.bank_transfer_submissions
 for each row execute function app_private.csa094_validate_submission();
revoke all on function app_private.csa094_validate_submission() from public,anon,authenticated,service_role;
alter table public.bank_transfer_submissions enable row level security;
revoke all on table public.bank_transfer_submissions from public,anon,authenticated,service_role;
comment on table public.bank_transfer_submissions is
 'Private evidence despite public schema: no direct student reads exposing receipt IDs. Future safe-view and independently verified finance workflow are required; upload alone grants no access.';
commit;
