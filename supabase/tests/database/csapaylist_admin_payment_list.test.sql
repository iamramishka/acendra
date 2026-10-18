begin;
select '1..1';
create function pg_temp.pl(a uuid,s uuid,aal text,size integer default 50,ac timestamptz default null,aid uuid default null,asof timestamptz default null,st text default null,m text default null,f date default null,t date default null,pre text default null)
returns jsonb language sql as $$select public.csapaylist_admin_payment_list(a,s,aal,size,ac,aid,asof,st,m,f,t,pre)$$;
create function pg_temp.mk(buyer uuid,course uuid,num text,method text,amount bigint,created timestamptz default now()) returns uuid language plpgsql as $$
declare oid uuid:=gen_random_uuid();
begin
 insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status,created_at)
 values(oid,num,buyer,course,'Synthetic snapshot',amount,'LKR',method,'pending_payment',created);
 return oid;
end; $$;
do $$
declare
 admin uuid:=gen_random_uuid(); finance uuid:=gen_random_uuid(); finance1 uuid:=gen_random_uuid(); manager uuid:=gen_random_uuid(); student uuid:=gen_random_uuid(); nobody uuid:=gen_random_uuid();
 ads uuid:=gen_random_uuid(); fs uuid:=gen_random_uuid(); f1s uuid:=gen_random_uuid(); ms uuid:=gen_random_uuid(); ss uuid:=gen_random_uuid();
 c uuid:=gen_random_uuid(); tag text:=substr(gen_random_uuid()::text,1,8); pre text; r jsonb; b jsonb; w jsonb;
 o1 uuid; o2 uuid; o3 uuid; o4 uuid; o5 uuid; o6 uuid; o7 uuid; o8 uuid; o9 uuid; o10 uuid; o11 uuid;
 seen uuid[]:='{}'; prev_created text; cursor_c timestamptz; cursor_i uuid; cursor_a timestamptz; n integer:=0; item jsonb; keys text[];
 receipt uuid:=gen_random_uuid(); submission uuid:=gen_random_uuid(); bank_version uuid:=gen_random_uuid(); bank_account uuid:=gen_random_uuid(); upload jsonb; snapshot_time timestamptz;
begin
 pre:='PL-'||tag;
 insert into auth.users(id) values(admin),(finance),(finance1),(manager),(student),(nobody);
 insert into auth.sessions(id,user_id,aal,not_after) values(ads,admin,'aal2',now()+interval '1 day'),(fs,finance,'aal2',now()+interval '1 day'),(f1s,finance1,'aal1',now()+interval '1 day'),(ms,manager,'aal1',now()+interval '1 day'),(ss,student,'aal1',now()+interval '1 day');
 insert into public.user_roles(user_id,role_id) select admin,id from public.roles where code='super_admin';
 insert into public.user_roles(user_id,role_id) select finance,id from public.roles where code='finance_admin';
 insert into public.user_roles(user_id,role_id) select finance1,id from public.roles where code='finance_admin';
 insert into public.user_roles(user_id,role_id) select manager,id from public.roles where code='content_manager';
 insert into public.courses(id,slug,title,price_minor,status,published_at) values(c,'paylist-'||c,'Synthetic',100,'published',now());
 insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name)
 values(bank_version,bank_account,1,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','Synthetic branch');

 -- Authority is checked before validation and before any data access.
 begin perform pg_temp.pl(student,ss,'aal1');raise exception 'student allowed';exception when insufficient_privilege then null;end;
 begin perform pg_temp.pl(manager,ms,'aal1');raise exception 'content manager allowed';exception when insufficient_privilege then null;end;
 begin perform pg_temp.pl(finance1,f1s,'aal1');raise exception 'finance AAL1 allowed';exception when insufficient_privilege then null;end;
 begin perform pg_temp.pl(finance,fs,'aal1');raise exception 'AAL claim mismatch allowed';exception when insufficient_privilege then null;end;
 begin perform pg_temp.pl(nobody,gen_random_uuid(),'aal2');raise exception 'unknown session allowed';exception when insufficient_privilege then null;end;
 begin perform pg_temp.pl(student,ss,'aal1',0);raise exception 'student validation oracle';exception when insufficient_privilege then null;end;
 begin perform public.csapaylist_admin_payment_detail(student,ss,'aal1',gen_random_uuid());raise exception 'student detail existence oracle';exception when insufficient_privilege then null;end;
 begin perform public.csapaylist_admin_payment_detail(manager,ms,'aal1',gen_random_uuid());raise exception 'manager detail';exception when insufficient_privilege then null;end;

 -- Direct SQL surface: only service_role may execute; internals are never granted.
 if has_function_privilege('anon','public.csapaylist_admin_payment_list(uuid,uuid,text,integer,timestamptz,uuid,timestamptz,text,text,date,date,text)','execute')
  or has_function_privilege('authenticated','public.csapaylist_admin_payment_list(uuid,uuid,text,integer,timestamptz,uuid,timestamptz,text,text,date,date,text)','execute')
  or has_function_privilege('anon','public.csapaylist_admin_payment_detail(uuid,uuid,text,uuid)','execute')
  or has_function_privilege('authenticated','public.csapaylist_admin_payment_detail(uuid,uuid,text,uuid)','execute')
  or has_function_privilege('authenticated','app_private.csapaylist_scope(timestamptz,text,timestamptz,timestamptz,uuid)','execute')
  or has_function_privilege('service_role','app_private.csapaylist_scope(timestamptz,text,timestamptz,timestamptz,uuid)','execute')
  or has_function_privilege('service_role','app_private.csapaylist_require_finance(uuid,uuid,text)','execute') then raise exception 'unexpected RPC grants';end if;
 if not has_function_privilege('service_role','public.csapaylist_admin_payment_list(uuid,uuid,text,integer,timestamptz,uuid,timestamptz,text,text,date,date,text)','execute')
  or not has_function_privilege('service_role','public.csapaylist_admin_payment_detail(uuid,uuid,text,uuid)','execute') then raise exception 'trusted gateway missing';end if;

 -- Validation (after authority).
 begin perform pg_temp.pl(admin,ads,'aal2',0);raise exception 'page_size 0';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',51);raise exception 'page_size 51';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,now(),null,null);raise exception 'partial cursor';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,null,null,null,'refunded');raise exception 'bad status';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,null,null,null,null,'stripe');raise exception 'bad method';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,null,null,null,null,null,null,null,'A%');raise exception 'wildcard prefix';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,null,null,null,null,null,'2026-01-02','2026-01-01');raise exception 'reverse range';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,null,null,null,null,null,'2025-01-01','2026-01-03');raise exception '367 day span';exception when invalid_parameter_value then null;end;
 begin perform pg_temp.pl(admin,ads,'aal2',10,null,null,null,null,null,'2026-01-02',null);raise exception 'half range';exception when invalid_parameter_value then null;end;
 begin perform public.csapaylist_admin_payment_detail(admin,ads,'aal2',null);raise exception 'null detail id';exception when invalid_parameter_value then null;end;

 -- Baselines (counts are global, so assert on deltas).
 b:=pg_temp.pl(finance,fs,'aal2',1)->'counts';
 w:=pg_temp.pl(finance,fs,'aal2',1,null,null,null,null,null,'2026-01-02','2026-01-02')->'counts';

 -- Every mapped status, both methods, large amounts, tied created_at.
 o1:=pg_temp.mk(student,c,pre||'-1','online',499900,now()-interval '9 minutes');
 o2:=pg_temp.mk(student,c,pre||'-2','online',0,now()-interval '8 minutes'); update public.orders set status='pending_payment' where id=o2;
 o3:=pg_temp.mk(student,c,pre||'-3','bank_transfer',250000,now()-interval '7 minutes'); update public.orders set status='pending_verification' where id=o3;
 o4:=pg_temp.mk(student,c,pre||'-4','online',100,now()-interval '6 minutes'); update public.orders set status='failed' where id=o4;
 o5:=pg_temp.mk(student,c,pre||'-5','bank_transfer',100,now()-interval '5 minutes'); update public.orders set status='cancelled',cancelled_at=clock_timestamp() where id=o5;
 o6:=pg_temp.mk(student,c,pre||'-6','online',9007199254740993,now()-interval '4 minutes');
 insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
  values(o6,'online',9007199254740993,'LKR','payhere','synthetic','production','SECRET-SETTLEMENT-'||tag,'provider_retrieval','SECRET-EVIDENCE-'||tag,now()-interval '3 minutes');
 update public.orders set status='paid',paid_at=clock_timestamp() where id=o6;
 o7:=pg_temp.mk(student,c,pre||'-7','bank_transfer',1,now()-interval '3 minutes');
 insert into app_private.order_bank_instructions(order_id,bank_account_version_id,instruction_snapshot)
 select o7,id,jsonb_build_object('bank_name',bank_name,'account_holder',account_holder,'account_number',account_number,'branch_name',branch_name,'currency_code',currency_code)
 from app_private.bank_account_versions where id=bank_version;
 insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,receiving_bank_account_scope,external_settlement_id,verification_method,evidence_reference,confirmed_at)
  values(o7,'bank_transfer',1,'LKR',bank_account::text,'SECRET-BANK-'||tag,'bank_reconciliation','SECRET-BANK-EVIDENCE-'||tag,now()-interval '2 minutes');
 update public.orders set status='paid',paid_at=clock_timestamp() where id=o7;
 o8:=pg_temp.mk(student,c,pre||'-8','online',100,now()-interval '2 minutes');
 o9:=pg_temp.mk(student,c,pre||'-9','online',100,(select created_at from public.orders where id=o8));

 r:=pg_temp.pl(finance,fs,'aal2',50,null,null,null,null,null,null,null,pre);
 if jsonb_array_length(r->'items')<>9 or (r->>'has_more')::boolean then raise exception 'prefix scope % %',jsonb_array_length(r->'items'),r->>'has_more';end if;
 if (r->'counts'->>'pending')::bigint-(b->>'pending')::bigint<>4 or (r->'counts'->>'processing')::bigint-(b->>'processing')::bigint<>1
  or (r->'counts'->>'approved')::bigint-(b->>'approved')::bigint<>2 or (r->'counts'->>'rejected')::bigint-(b->>'rejected')::bigint<>2
  or (r->'counts'->>'total')::bigint-(b->>'total')::bigint<>9 then raise exception 'status mapping/counts %',r->'counts';end if;
 if (r->'counts'->>'total')::bigint<>(r->'counts'->>'pending')::bigint+(r->'counts'->>'processing')::bigint+(r->'counts'->>'approved')::bigint+(r->'counts'->>'rejected')::bigint then raise exception 'counts do not sum';end if;
 if (select jsonb_typeof(r->'counts'->k) from unnest(array['pending','processing','approved','rejected','total']) k limit 1)<>'string' then raise exception 'counts not strings';end if;
 for item in select * from jsonb_array_elements(r->'items') loop
  if (item->>'order_number') like pre||'-6' and (item->>'amount_minor'<>'9007199254740993' or jsonb_typeof(item->'amount_minor')<>'string' or item->>'status'<>'approved' or item->>'settled_at' is null) then raise exception 'large amount/approved %',item;end if;
  if (item->>'order_number')=pre||'-1' and (item->>'status'<>'pending' or item->>'method'<>'online' or item->>'settled_at' is not null) then raise exception 'pending mapping';end if;
  if (item->>'order_number')=pre||'-3' and item->>'status'<>'processing' then raise exception 'processing mapping';end if;
  if (item->>'order_number') in (pre||'-4',pre||'-5') and item->>'status'<>'rejected' then raise exception 'rejected mapping';end if;
  if (item->>'order_number')=pre||'-2' and item->>'amount_minor'<>'0' then raise exception 'zero amount';end if;
  if (item->>'order_number')=pre||'-7' and (item->>'status'<>'approved' or item->>'method'<>'bank_transfer') then raise exception 'bank approved mapping';end if;
 end loop;

 -- Privacy: exact key allowlist; seeded evidence/settlement references never appear.
 select array_agg(k order by k) into keys from jsonb_object_keys(r->'items'->0) k;
 if keys is distinct from array['amount_minor','course_id','course_title','created_at','currency_code','method','order_id','order_number','payment_id','settled_at','status','updated_at'] then raise exception 'item keys %',keys;end if;
 select array_agg(k order by k) into keys from jsonb_object_keys(r) k;
 if keys is distinct from array['as_of','count_as_of','counts','has_more','items'] then raise exception 'result keys %',keys;end if;
 if r->>'as_of' is distinct from r->>'count_as_of' then raise exception 'first page snapshot time differs from cutoff';end if;
 if r::text like '%SECRET%' or r::text like '%'||student::text||'%' or r::text ilike '%receipt%' or r::text ilike '%payhere%' or r::text ilike '%email%' then raise exception 'private data in list';end if;
 if (r->'items'->0->>'payment_id')<>(r->'items'->0->>'order_id') then raise exception 'payment id is order id';end if;

 -- Filters.
 if jsonb_array_length(pg_temp.pl(finance,fs,'aal2',50,null,null,null,'approved',null,null,null,pre)->'items')<>2 then raise exception 'status filter';end if;
 if jsonb_array_length(pg_temp.pl(finance,fs,'aal2',50,null,null,null,null,'bank_transfer',null,null,pre)->'items')<>3 then raise exception 'method filter';end if;
 if jsonb_array_length(pg_temp.pl(finance,fs,'aal2',50,null,null,null,'pending','online',null,null,lower(pre))->'items')<>4 then raise exception 'combined filter/case-insensitive prefix';end if;
 -- Counts ignore the status filter and the prefix, honour method.
 r:=pg_temp.pl(finance,fs,'aal2',50,null,null,null,'approved','bank_transfer',null,null,pre);
 if (r->'counts'->>'total')::bigint-(b->>'total')::bigint<>3 then raise exception 'method counts % %',r->'counts',b;end if;

 -- Keyset pagination: no gaps or duplicates, stable order with equal created_at.
 loop
  r:=pg_temp.pl(finance,fs,'aal2',4,cursor_c,cursor_i,cursor_a,null,null,null,null,pre);
  if jsonb_array_length(r->'items')>4 then raise exception 'page size exceeded';end if;
  for item in select * from jsonb_array_elements(r->'items') loop
   if (item->>'payment_id')::uuid=any(seen) then raise exception 'duplicate row across pages';end if;
   if prev_created is not null and (item->>'created_at')>prev_created then raise exception 'order violated';end if;
   prev_created:=item->>'created_at';seen:=seen||(item->>'payment_id')::uuid;
  end loop;
  n:=n+1;exit when not (r->>'has_more')::boolean or n>5;
  item:=r->'items'->(jsonb_array_length(r->'items')-1);
  cursor_c:=(item->>'created_at')::timestamptz;cursor_i:=(item->>'payment_id')::uuid;cursor_a:=(r->>'as_of')::timestamptz;
 end loop;
 if cardinality(seen)<>9 or n<>3 then raise exception 'pagination coverage % pages, % rows',n,cardinality(seen);end if;
 if (r->>'has_more')::boolean then raise exception 'last page has_more';end if;
 r:=pg_temp.pl(finance,fs,'aal2',4,now()-interval '100 years',gen_random_uuid(),now(),null,null,null,null,pre);
 if jsonb_array_length(r->'items')<>0 or (r->>'has_more')::boolean then raise exception 'empty page';end if;
 -- A cursor boundary from the future is invalid; rows created after as_of are excluded from later pages.
 begin perform pg_temp.pl(finance,fs,'aal2',50,now(),gen_random_uuid(),now()+interval '1 day');raise exception 'future as_of';exception when invalid_parameter_value then null;end;
 r:=pg_temp.pl(finance,fs,'aal2',50,now()-interval '100 years',gen_random_uuid(),now()-interval '5 minutes 30 seconds',null,null,null,null,pre);
 if jsonb_array_length(r->'items')<>0 or (r->'counts'->>'total')::bigint-(b->>'total')::bigint<>4 then raise exception 'as_of boundary ignored %',r->'counts';end if;

 -- Asia/Colombo midnight boundaries are inclusive/exclusive exactly.
 perform pg_temp.mk(student,c,pre||'-d1','online',100,'2026-01-01T18:29:59.999999Z');
 perform pg_temp.mk(student,c,pre||'-d2','online',100,'2026-01-01T18:30:00Z');
 perform pg_temp.mk(student,c,pre||'-d3','online',100,'2026-01-02T18:29:59.999999Z');
 perform pg_temp.mk(student,c,pre||'-d4','online',100,'2026-01-02T18:30:00Z');
 r:=pg_temp.pl(finance,fs,'aal2',50,null,null,null,null,null,'2026-01-02','2026-01-02',pre||'-d');
 if jsonb_array_length(r->'items')<>2 or (r->'items'->0->>'order_number')<>pre||'-d3' or (r->'items'->1->>'order_number')<>pre||'-d2' then raise exception 'colombo boundaries %',r->'items';end if;
 if (r->'counts'->>'total')::bigint-(w->>'total')::bigint<>2 then raise exception 'date-window counts';end if;

 -- Detail.
 r:=public.csapaylist_admin_payment_detail(finance,fs,'aal2',o6);
 if r->'item'->>'amount_minor'<>'9007199254740993' or r->'item'->>'status'<>'approved' or r::text like '%SECRET%' then raise exception 'detail';end if;
 select array_agg(k order by k) into keys from jsonb_object_keys(r) k;
 if keys is distinct from array['as_of','item'] then raise exception 'detail keys';end if;
 begin perform public.csapaylist_admin_payment_detail(finance,fs,'aal2',gen_random_uuid());raise exception 'missing detail';exception when no_data_found then null;end;

 -- Reproduce the real rejection workflow: rejection resets its order to pending_payment.
 -- Seed only historical inspected evidence; review, retry preparation and finalization use trusted operations.
 insert into app_private.order_bank_instructions(order_id,bank_account_version_id,instruction_snapshot)
 select o3,id,jsonb_build_object('bank_name',bank_name,'account_holder',account_holder,'account_number',account_number,'branch_name',branch_name,'currency_code',currency_code)
 from app_private.bank_account_versions where id=bank_version;
 insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,uploaded_by,validation_status,validated_at,checksum_sha256,mime_type,size_bytes)
 values(receipt,'bank_receipt','supabase','bank-receipts',student::text||'/'||o3::text||'/historical.png',student,'validated',now(),repeat('a',64),'image/png',100);
 insert into public.bank_transfer_submissions(id,order_id,submitted_by,receipt_asset_id,status,created_at,submitted_at)
 values(submission,o3,student,receipt,'submitted',now()-interval '6 minutes',now()-interval '5 minutes');
 b:=pg_temp.pl(finance,fs,'aal2',1)->'counts';
 perform public.csa112_review_bank_transfer(finance,fs,'aal2','paylist-reject-'||tag,submission,'reject',null,'Synthetic unmatched credit',null);
 if (select status from public.orders where id=o3)<>'pending_payment' then raise exception 'rejection did not reset order';end if;
 r:=pg_temp.pl(finance,fs,'aal2',50,null,null,null,'rejected',null,null,null,pre||'-3');
 if jsonb_array_length(r->'items')<>1 or r->'items'->0->>'status'<>'rejected'
  or (r->'counts'->>'rejected')::bigint<>(b->>'rejected')::bigint+1
  or (r->'counts'->>'processing')::bigint<>(b->>'processing')::bigint-1
  or (r->'counts'->>'pending')::bigint<>(b->>'pending')::bigint
  or public.csapaylist_admin_payment_detail(finance,fs,'aal2',o3)->'item'->>'status'<>'rejected'
 then raise exception 'rejected bank payment lost from list/detail/counts';end if;

 upload:=public.csa108_prepare_receipt(student,ss,'aal1','paylist-retry-'||tag,o3,repeat('a',64),100,'image/png','png');
 r:=pg_temp.pl(finance,fs,'aal2',50,null,null,null,'pending',null,null,null,pre||'-3');
 if jsonb_array_length(r->'items')<>1 or r->'items'->0->>'status'<>'pending'
  or public.csapaylist_admin_payment_detail(finance,fs,'aal2',o3)->'item'->>'status'<>'pending'
 then raise exception 'older rejection overrides newer preparation';end if;
 insert into storage.objects(bucket_id,name) values('bank-receipts',upload->>'object_path');
 perform public.csa109_finalize_receipt(student,ss,'aal1',(upload->>'upload_id')::uuid,repeat('a',64),100,'image/png','synthetic-paylist-inspection');
 r:=pg_temp.pl(finance,fs,'aal2',50,null,null,null,'processing',null,null,null,pre||'-3');
 if jsonb_array_length(r->'items')<>1 or r->'items'->0->>'status'<>'processing' then raise exception 'older rejection overrides newer submission';end if;

 -- A continuation has a fixed older creation cutoff, but facts use this statement's live snapshot.
 snapshot_time:=statement_timestamp()-interval '30 seconds';
 b:=pg_temp.pl(finance,fs,'aal2',50,now(),gen_random_uuid(),snapshot_time,null,null,null,null,pre||'-3');
 perform public.csa112_review_bank_transfer(finance,fs,'aal2','paylist-approve-'||tag,(upload->>'submission_id')::uuid,'approve',
  jsonb_build_object('destination_account_id',bank_account,'bank_transaction_id','paylist-credit-'||tag,'amount_minor','250000',
   'currency','LKR','settled_at',now()-interval '1 minute','source','bank_statement','order_reference',pre||'-3','bank_credit_confirmed',true),null,null);
 r:=pg_temp.pl(finance,fs,'aal2',50,now(),gen_random_uuid(),snapshot_time,null,null,null,null,pre||'-3');
 if r->>'as_of' is distinct from b->>'as_of' or (r->>'as_of')::timestamptz is distinct from snapshot_time
  or (r->>'count_as_of')::timestamptz is distinct from statement_timestamp()
  or (r->>'count_as_of')::timestamptz<=(r->>'as_of')::timestamptz
  or (r->'counts'->>'processing')::bigint<>(b->'counts'->>'processing')::bigint-1
  or (r->'counts'->>'approved')::bigint<>(b->'counts'->>'approved')::bigint+1
  or r->'items'->0->>'status'<>'approved'
  or public.csapaylist_admin_payment_detail(finance,fs,'aal2',o3)->'item'->>'status'<>'approved'
 then raise exception 'continuation snapshot or terminal paid precedence failed';end if;

 -- Fail closed (these poison the global scope, so they run last): a paid order whose only
 -- settlement is sandbox is not approved; refunded orders are unsupported.
 o10:=pg_temp.mk(student,c,pre||'-s','online',100,now()-interval '1 minute');
 insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
  values(o10,'online',100,'LKR','payhere','synthetic','sandbox','SECRET-SANDBOX-'||tag,'provider_retrieval','synthetic',now()-interval '30 seconds');
 update public.orders set status='paid',paid_at=clock_timestamp() where id=o10;
 begin perform pg_temp.pl(finance,fs,'aal2');raise exception 'sandbox-only paid listed';exception when object_not_in_prerequisite_state then null;end;
 begin perform public.csapaylist_admin_payment_detail(finance,fs,'aal2',o10);raise exception 'sandbox-only paid detail';exception when object_not_in_prerequisite_state then null;end;
 update public.orders set status='cancelled',cancelled_at=clock_timestamp() where id=o10;
 -- Settlements normally pin paid/refunded; bypass only inside this rolled-back fixture.
 begin
  o11:=pg_temp.mk(student,c,pre||'-r','online',100,now()-interval '1 minute');
  insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
   values(o11,'online',100,'LKR','payhere','synthetic','production','SECRET-REFUND-'||tag,'provider_retrieval','synthetic',now()-interval '30 seconds');
  update public.orders set status='refunded',paid_at=clock_timestamp() where id=o11;
  begin perform pg_temp.pl(finance,fs,'aal2');raise exception 'refunded listed as zero/empty';exception when object_not_in_prerequisite_state then null;end;
 end;

 -- Revocation, expiry and removed account are enforced on every call.
 update public.user_roles set revoked_at=clock_timestamp() where user_id=finance;
 begin perform pg_temp.pl(finance,fs,'aal2');raise exception 'stale finance token';exception when insufficient_privilege then null;end;
 update auth.sessions set not_after=clock_timestamp()-interval '1 second' where id=ads;
 begin perform pg_temp.pl(admin,ads,'aal2');raise exception 'expired session';exception when insufficient_privilege then null;end;
end; $$;
select 'ok 1 - admin payment list: authority, MFA, grants, validation, mapping, counts, pagination, privacy, fail-closed';
rollback;
