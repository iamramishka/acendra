-- Preserve all reserved receipt objects until retention/deletion policy is approved.
-- Unconditional denial also closes deletion concurrent with finalization.
create or replace function app_private.csa108_storage_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_table_name='buckets' then
 if new.id='bank-receipts' and new.public then raise exception using errcode='42501',message='Bank receipts must remain private.'; end if;
 return new;
 end if;
 if tg_op='DELETE' then
 if old.bucket_id='bank-receipts' then
 raise exception using errcode='42501',message='Receipt deletion awaits approved retention operations.'; end if; return old;
 end if;
 if tg_op='UPDATE' and (old.bucket_id='bank-receipts' or new.bucket_id='bank-receipts') then
 raise exception using errcode='42501',message='Receipt object replacement is prohibited.'; end if;
 if new.bucket_id='bank-receipts' and not exists(select 1 from app_private.bank_receipt_uploads where object_path=new.name and finalized_at is null) then
 raise exception using errcode='42501',message='Server receipt reservation required.'; end if;
 return new;
end; $$;
