-- CSA108/109/112/113 private receipt reservation and independently reviewed bank fulfillment.
-- Runtime Edge routes remain disabled pending receipt inspection/operational acceptance.
begin;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('bank-receipts','bank-receipts',false,5242880,array['image/jpeg','image/png','application/pdf']) on conflict(id) do nothing;
do $$begin if exists(select 1 from storage.buckets where id='bank-receipts' and public) then raise exception 'Private bank receipt bucket required.'; end if; end;$$;
create policy csa108_no_direct_receipts on storage.objects as restrictive for all to anon,authenticated
 using(bucket_id<>'bank-receipts') with check(bucket_id<>'bank-receipts');
create table app_private.bank_receipt_uploads (
 id uuid primary key references app_private.media_assets(id) on delete restrict,
 submission_id uuid not null unique references public.bank_transfer_submissions(id) on delete restrict,
 expected_digest text not null check(expected_digest ~ '^[0-9a-f]{64}$'),
 expected_size bigint not null check(expected_size between 1 and 5242880),
 expected_mime text not null check(expected_mime in ('image/jpeg','image/png','application/pdf')),
 extension text not null check(extension in ('jpg','jpeg','png','pdf')),
 object_path text not null unique, inspection_reference text, finalized_at timestamptz, finalize_result jsonb,
 created_at timestamptz not null default now(),
 check((finalized_at is null and inspection_reference is null and finalize_result is null)
 or (finalized_at is not null and inspection_reference is not null and finalize_result is not null))
);
create function app_private.csa109_upload_immutable() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op in ('DELETE','TRUNCATE') then raise exception using errcode='42501',message='Receipt reservation history is immutable.'; end if;
 if row(new.id,new.submission_id,new.expected_digest,new.expected_size,new.expected_mime,new.extension,new.object_path,new.created_at)
 is distinct from row(old.id,old.submission_id,old.expected_digest,old.expected_size,old.expected_mime,old.extension,old.object_path,old.created_at)
 or (old.finalized_at is not null and row(new.finalized_at,new.inspection_reference,new.finalize_result) is distinct from row(old.finalized_at,old.inspection_reference,old.finalize_result)) then
 raise exception using errcode='42501',message='Receipt reservation and inspection evidence are immutable.'; end if;
 return new;
end; $$;
create trigger csa109_upload_preserve before update or delete on app_private.bank_receipt_uploads for each row execute function app_private.csa109_upload_immutable();
create trigger csa109_upload_no_truncate before truncate on app_private.bank_receipt_uploads for each statement execute function app_private.csa109_upload_immutable();
revoke all on function app_private.csa109_upload_immutable() from public,anon,authenticated,service_role;
create table app_private.bank_transfer_reviews (
 id uuid primary key default gen_random_uuid(), submission_id uuid not null unique references public.bank_transfer_submissions(id) on delete restrict,
 actor_id uuid not null references public.profiles(id) on delete restrict, decision text not null check(decision in ('approve','reject')),
 verified_credit jsonb, private_notes text, reviewed_at timestamptz not null,
 check((decision='approve' and jsonb_typeof(verified_credit)='object') or (decision='reject' and verified_credit is null)),
 check(private_notes is null or char_length(private_notes)<=2000)
);
alter table app_private.bank_receipt_uploads enable row level security;
alter table app_private.bank_transfer_reviews enable row level security;
revoke all on app_private.bank_receipt_uploads,app_private.bank_transfer_reviews from public,anon,authenticated,service_role;
create trigger csa112_reviews_immutable before update or delete on app_private.bank_transfer_reviews for each row execute function app_private.csa096_immutable_record();
create trigger csa112_reviews_no_truncate before truncate on app_private.bank_transfer_reviews for each statement execute function app_private.csa096_immutable_record();
create function app_private.csa108_storage_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_table_name='buckets' then
 if new.id='bank-receipts' and new.public then raise exception using errcode='42501',message='Bank receipts must remain private.'; end if;
 return new;
 end if;
 if tg_op='DELETE' then
 if old.bucket_id='bank-receipts' and exists(select 1 from app_private.bank_receipt_uploads where object_path=old.name and finalized_at is not null) then
 raise exception using errcode='42501',message='Finalized receipt evidence is immutable.'; end if; return old;
 end if;
 if tg_op='UPDATE' and (old.bucket_id='bank-receipts' or new.bucket_id='bank-receipts') then
 raise exception using errcode='42501',message='Receipt object replacement is prohibited.'; end if;
 if new.bucket_id='bank-receipts' and not exists(select 1 from app_private.bank_receipt_uploads where object_path=new.name and finalized_at is null) then
 raise exception using errcode='42501',message='Server receipt reservation required.'; end if;
 return new;
end; $$;
create trigger csa108_storage_receipt_guard before insert or update or delete on storage.objects for each row execute function app_private.csa108_storage_guard();
create trigger csa108_bucket_private_guard before insert or update on storage.buckets for each row execute function app_private.csa108_storage_guard();
revoke all on function app_private.csa108_storage_guard() from public,anon,authenticated,service_role;

create function app_private.csa108_require_session(p_actor uuid,p_session_id uuid,p_aal text,p_finance boolean default false)
returns void language plpgsql security definer set search_path='' as $$
declare u auth.users%rowtype; s auth.sessions%rowtype;
begin
 if p_finance then perform pg_advisory_xact_lock(610061); end if;
 select * into u from auth.users where id=p_actor for share;
 if not found or u.deleted_at is not null or coalesce(u.is_anonymous,false) or u.banned_until>clock_timestamp() then
 raise exception using errcode='42501',message='Current account required.'; end if;
 select * into s from auth.sessions where id=p_session_id and user_id=p_actor for share;
 if not found or p_aal is null or p_aal not in ('aal1','aal2') or s.aal::text is distinct from p_aal or s.not_after<=clock_timestamp()
 or (p_finance and p_aal<>'aal2') then raise exception using errcode='42501',message='Current verified session required.'; end if;
 if p_finance and not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p_actor and ur.revoked_at is null and r.code in ('finance_admin','super_admin')) then
 raise exception using errcode='42501',message='Current finance authority required.'; end if;
end; $$;
revoke all on function app_private.csa108_require_session(uuid,uuid,text,boolean) from public,anon,authenticated,service_role;

create function public.csa108_prepare_receipt(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_order uuid,p_digest text,p_size bigint,p_mime text,p_extension text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.orders%rowtype; prior app_private.idempotency_records%rowtype; sid uuid; aid uuid; path text; scope text; h text; result jsonb; finalized boolean;
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal);
 if p_key is null or p_key !~ '^[A-Za-z0-9._:-]{1,128}$' or p_order is null or p_digest is null or p_digest !~ '^[0-9a-f]{64}$'
 or p_size is null or p_size not between 1 and 5242880 or p_mime is null or p_extension is null
 or not ((p_mime='image/jpeg' and p_extension in ('jpg','jpeg')) or (p_mime='image/png' and p_extension='png') or (p_mime='application/pdf' and p_extension='pdf')) then
 raise exception using errcode='22023',message='Invalid receipt request.'; end if;
 scope:='user:'||p_actor::text;
 h:=encode(sha256(convert_to(jsonb_build_object('order',p_order,'digest',p_digest,'size',p_size,'mime',p_mime,'extension',p_extension)::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtext(scope),hashtext('prepare-bank-receipt:'||p_key));
 select * into o from public.orders where id=p_order for update;
 if not found or o.buyer_id is distinct from p_actor or o.payment_method<>'bank_transfer' then raise exception using errcode='42501',message='Owned bank order required.'; end if;
 select * into prior from app_private.idempotency_records where principal_scope=scope and operation='prepare-bank-receipt' and idempotency_key=p_key;
 if found then
 if prior.request_hash is distinct from h then raise exception using errcode='22023',message='Idempotency conflict.'; end if;
 select finalized_at is not null into finalized from app_private.bank_receipt_uploads where id=(prior.safe_result->>'upload_id')::uuid;
 return prior.safe_result||jsonb_build_object('replayed',true,'finalized',finalized); end if;
 if o.status<>'pending_payment' then raise exception using errcode='55000',message='Payable bank order required.'; end if;
 if not exists(select 1 from app_private.order_bank_instructions where order_id=o.id) then raise exception using errcode='55000',message='Bound bank destination required.'; end if;
 if exists(select 1 from public.bank_transfer_submissions where order_id=o.id and status in ('awaiting_receipt','submitted','under_review')) then
 raise exception using errcode='23505',message='Active receipt submission exists.'; end if;
 sid:=gen_random_uuid(); aid:=gen_random_uuid(); path:=p_actor::text||'/'||o.id::text||'/'||sid::text||'/'||aid::text||'.'||p_extension;
 insert into public.bank_transfer_submissions(id,order_id,submitted_by) values(sid,o.id,p_actor);
 insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,uploaded_by)
 values(aid,'bank_receipt','supabase','bank-receipts',path,p_actor);
 insert into app_private.bank_receipt_uploads(id,submission_id,expected_digest,expected_size,expected_mime,extension,object_path)
 values(aid,sid,p_digest,p_size,p_mime,p_extension,path);
 result:=jsonb_build_object('upload_id',aid,'receipt_asset_id',aid,'submission_id',sid,'object_path',path,'bucket','bank-receipts','replayed',false,'finalized',false);
 insert into app_private.idempotency_records(principal_scope,operation,idempotency_key,request_hash,safe_result) values(scope,'prepare-bank-receipt',p_key,h,result);
 return result;
end; $$;

create function public.csa109_finalize_receipt(p_actor uuid,p_session_id uuid,p_aal text,p_upload_id uuid,p_digest text,p_size bigint,p_mime text,p_inspection_reference text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare upload app_private.bank_receipt_uploads%rowtype; submission public.bank_transfer_submissions%rowtype; o public.orders%rowtype; t timestamptz; result jsonb;
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal);
 if p_upload_id is null or p_inspection_reference is null or p_inspection_reference !~ '^[A-Za-z0-9._:-]{1,128}$' then
 raise exception using errcode='22023',message='Trusted receipt inspection required.'; end if;
 select * into upload from app_private.bank_receipt_uploads where id=p_upload_id;
 if not found then raise exception using errcode='P0002',message='Receipt reservation unavailable.'; end if;
 select * into submission from public.bank_transfer_submissions where id=upload.submission_id;
 select * into o from public.orders where id=submission.order_id for update;
 select * into submission from public.bank_transfer_submissions where id=upload.submission_id for update;
 select * into upload from app_private.bank_receipt_uploads where id=p_upload_id for update;
 if o.buyer_id is distinct from p_actor or submission.submitted_by is distinct from p_actor then raise exception using errcode='42501',message='Owned receipt required.'; end if;
 if upload.expected_digest is distinct from p_digest or upload.expected_size is distinct from p_size or upload.expected_mime is distinct from p_mime then
 raise exception using errcode='22023',message='Stored receipt evidence mismatch.'; end if;
 if upload.finalized_at is not null then
 if upload.inspection_reference is distinct from p_inspection_reference then raise exception using errcode='22023',message='Inspection replay conflict.'; end if;
 return upload.finalize_result||jsonb_build_object('replayed',true); end if;
 if o.status<>'pending_payment' or submission.status<>'awaiting_receipt' then raise exception using errcode='55000',message='Receipt no longer payable.'; end if;
 if not exists(select 1 from storage.buckets b join storage.objects obj on obj.bucket_id=b.id where b.id='bank-receipts' and b.public=false and obj.name=upload.object_path) then
 raise exception using errcode='55000',message='Private stored receipt required.'; end if;
 t:=clock_timestamp();
 update app_private.media_assets set validation_status='validated',validated_at=t,checksum_sha256=p_digest,size_bytes=p_size,mime_type=p_mime where id=upload.id;
 update public.bank_transfer_submissions set receipt_asset_id=upload.id,submitted_at=t,status='submitted' where id=submission.id;
 update public.orders set status='pending_verification' where id=o.id;
 result:=jsonb_build_object('order_id',o.id,'submission_id',submission.id,'status','submitted','replayed',false);
 update app_private.bank_receipt_uploads set finalized_at=t,inspection_reference=p_inspection_reference,finalize_result=result where id=upload.id;
 insert into app_private.audit_logs(actor_user_id,action,resource_type,resource_id,outcome,safe_metadata)
 values(p_actor,'bank_receipt_submitted','order',o.id,'submitted',jsonb_build_object('submission_id',submission.id));
 return result;
end; $$;

create function public.csa112_review_bank_transfer(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_submission uuid,p_decision text,p_verified_credit jsonb,p_public_reason text,p_private_notes text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare submission public.bank_transfer_submissions%rowtype; o public.orders%rowtype; prior app_private.idempotency_records%rowtype;
 scope text; h text; result jsonb; destination uuid; bank_transaction text; amount bigint; settled timestamptz; source text; settlement uuid; enrollment uuid; t timestamptz;
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,true);
 if p_key is null or p_key !~ '^[A-Za-z0-9._:-]{1,128}$' or p_submission is null or p_decision is null or p_decision not in ('approve','reject')
 or (p_private_notes is not null and char_length(p_private_notes)>2000) then raise exception using errcode='22023',message='Invalid bank review request.'; end if;
 if p_decision='approve' then
 if p_public_reason is not null or p_verified_credit is null or jsonb_typeof(p_verified_credit)<>'object'
 or p_verified_credit->'bank_credit_confirmed' is distinct from 'true'::jsonb
 or jsonb_typeof(p_verified_credit->'amount_minor') is distinct from 'string'
 or (p_verified_credit - array['destination_account_id','bank_transaction_id','amount_minor','currency','settled_at','source','order_reference','bank_credit_confirmed']) <> '{}'::jsonb
 or p_verified_credit->>'amount_minor' is null or p_verified_credit->>'amount_minor' !~ '^[1-9][0-9]{0,15}$'
 or p_verified_credit->>'currency' is distinct from 'LKR' or p_verified_credit->>'source' is null or p_verified_credit->>'source' not in ('bank_portal','bank_statement','authenticated_bank_feed')
 or p_verified_credit->>'bank_transaction_id' is null or char_length(p_verified_credit->>'bank_transaction_id') not between 1 and 200 or p_verified_credit->>'bank_transaction_id' !~ '[^[:space:]]'
 or p_verified_credit->>'destination_account_id' is null or p_verified_credit->>'settled_at' is null or p_verified_credit->>'order_reference' is null
 then raise exception using errcode='22023',message='Independent settled credit evidence required.'; end if;
 begin destination:=(p_verified_credit->>'destination_account_id')::uuid; amount:=(p_verified_credit->>'amount_minor')::bigint; settled:=(p_verified_credit->>'settled_at')::timestamptz;
 exception when invalid_text_representation or invalid_datetime_format or datetime_field_overflow or numeric_value_out_of_range then raise exception using errcode='22023',message='Invalid credit identity or time.'; end;
 if not isfinite(settled) or settled>clock_timestamp() then raise exception using errcode='22023',message='Settled credit time required.'; end if;
 bank_transaction:=p_verified_credit->>'bank_transaction_id'; source:=p_verified_credit->>'source';
 else
 if p_verified_credit is not null or p_public_reason is null or char_length(p_public_reason) not between 1 and 1000 or p_public_reason !~ '[^[:space:]]' then
 raise exception using errcode='22023',message='Safe rejection reason required.'; end if;
 end if;
 scope:='user:'||p_actor::text;
 h:=encode(sha256(convert_to(jsonb_build_object('submission',p_submission,'decision',p_decision,'credit',p_verified_credit,'reason',p_public_reason,'notes',p_private_notes)::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtext(scope),hashtext('review-bank-transfer:'||p_key));
 if p_decision='approve' then perform pg_advisory_xact_lock(hashtext(destination::text),hashtext(bank_transaction)); end if;
 select * into submission from public.bank_transfer_submissions where id=p_submission;
 if not found then raise exception using errcode='P0002',message='Bank submission unavailable.'; end if;
 select * into o from public.orders where id=submission.order_id for update;
 select * into submission from public.bank_transfer_submissions where id=p_submission for update;
 if p_actor=o.buyer_id or p_actor=submission.submitted_by then raise exception using errcode='42501',message='Independent reviewer required.'; end if;
 select * into prior from app_private.idempotency_records where principal_scope=scope and operation='review-bank-transfer' and idempotency_key=p_key;
 if found then
 if prior.request_hash is distinct from h then raise exception using errcode='22023',message='Idempotency conflict.'; end if;
 return prior.safe_result||jsonb_build_object('replayed',true); end if;
 if submission.status not in ('submitted','under_review') or o.status<>'pending_verification' or o.payment_method<>'bank_transfer' then
 raise exception using errcode='55000',message='Bank review finalized or order not payable.'; end if;
 if p_decision='approve' then
 if amount is distinct from o.amount_minor or p_verified_credit->>'order_reference' is distinct from o.order_number
 or not exists(select 1 from app_private.order_bank_instructions i join app_private.bank_account_versions b on b.id=i.bank_account_version_id where i.order_id=o.id and b.bank_account_id=destination)
 then raise exception using errcode='22023',message='Credit does not match stored order terms.'; end if;
 if exists(select 1 from app_private.verified_settlements where method='bank_transfer' and receiving_bank_account_scope=destination::text and external_settlement_id=bank_transaction) then
 raise exception using errcode='23505',message='Bank settlement identity already consumed.'; end if;
 end if;
 t:=clock_timestamp();
 if submission.status='submitted' then
 update public.bank_transfer_submissions set status='under_review' where id=submission.id;
 insert into app_private.audit_logs(actor_user_id,action,resource_type,resource_id,outcome,safe_metadata)
 values(p_actor,'bank_review_started','order',o.id,'under_review',jsonb_build_object('submission_id',submission.id));
 end if;
 if p_decision='approve' then
 settlement:=gen_random_uuid();
 insert into app_private.verified_settlements(id,order_id,method,amount_minor,currency_code,receiving_bank_account_scope,external_settlement_id,verification_method,evidence_reference,confirmed_at,recorded_at)
 values(settlement,o.id,'bank_transfer',amount,'LKR',destination::text,bank_transaction,'bank_reconciliation',source||':'||bank_transaction,settled,t);
 perform pg_advisory_xact_lock(hashtext(o.buyer_id::text),hashtext(o.course_id::text));
 insert into public.payment_attempts(order_id,method,amount_minor,currency_code,status,provider_transaction_id,created_at,updated_at,completed_at)
 values(o.id,'bank_transfer',amount,'LKR','succeeded',bank_transaction,t,t,t);
 update public.orders set status='paid',paid_at=t where id=o.id;
 update public.bank_transfer_submissions set status='approved',reviewed_by=p_actor,reviewed_at=t,settlement_id=settlement where id=submission.id;
 insert into public.enrollments(user_id,course_id,status,granted_at) values(o.buyer_id,o.course_id,'active',t) on conflict(user_id,course_id) do nothing;
 select id into enrollment from public.enrollments where user_id=o.buyer_id and course_id=o.course_id for update;
 insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,valid_from,settlement_id) values(enrollment,o.buyer_id,o.course_id,'bank_transfer',o.id,t,settlement);
 update public.enrollments set status='active',expires_at=null where id=enrollment and status<>'revoked';
 else
 update public.bank_transfer_submissions set status='rejected',reviewed_by=p_actor,reviewed_at=t,public_rejection_reason=p_public_reason where id=submission.id;
 update public.orders set status='pending_payment' where id=o.id;
 end if;
 insert into app_private.bank_transfer_reviews(submission_id,actor_id,decision,verified_credit,private_notes,reviewed_at) values(submission.id,p_actor,p_decision,p_verified_credit,p_private_notes,t);
 insert into app_private.audit_logs(actor_user_id,action,resource_type,resource_id,request_id,outcome,safe_metadata)
 values(p_actor,case when p_decision='approve' then 'bank_transfer_approved' else 'bank_transfer_rejected' end,'order',o.id,p_key,p_decision,jsonb_build_object('submission_id',submission.id));
 insert into app_private.notification_outbox(event_key,recipient_user_id,notification_type,safe_payload)
 values('bank_review:'||submission.id::text,o.buyer_id,case when p_decision='approve' then 'bank_transfer_approved' else 'bank_transfer_rejected' end,
 jsonb_build_object('order_id',o.id,'submission_id',submission.id,'public_rejection_reason',p_public_reason));
 result:=jsonb_build_object('replayed',false,'submission_id',submission.id,'order_id',o.id,'status',case when p_decision='approve' then 'approved' else 'rejected' end,'order_status',case when p_decision='approve' then 'paid' else 'pending_payment' end);
 insert into app_private.idempotency_records(principal_scope,operation,idempotency_key,request_hash,safe_result) values(scope,'review-bank-transfer',p_key,h,result);
 return result;
end; $$;
revoke all on function public.csa108_prepare_receipt(uuid,uuid,text,text,uuid,text,bigint,text,text),public.csa109_finalize_receipt(uuid,uuid,text,uuid,text,bigint,text,text),public.csa112_review_bank_transfer(uuid,uuid,text,text,uuid,text,jsonb,text,text) from public,anon,authenticated,service_role;
grant execute on function public.csa108_prepare_receipt(uuid,uuid,text,text,uuid,text,bigint,text,text),public.csa109_finalize_receipt(uuid,uuid,text,uuid,text,bigint,text,text),public.csa112_review_bank_transfer(uuid,uuid,text,text,uuid,text,jsonb,text,text) to service_role;
commit;
