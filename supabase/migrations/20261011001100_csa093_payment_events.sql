-- Only trusted, validated events enter this ledger. Invalid notifications must
-- never reserve a replay key; callback payment_id alone is not verified identity.
begin;
create table app_private.payment_events (
 id uuid primary key default gen_random_uuid(),
 payment_attempt_id uuid not null references public.payment_attempts(id) on delete restrict,
 provider text not null check(provider='payhere'),
 provider_merchant_id text not null check(char_length(provider_merchant_id) between 1 and 100 and provider_merchant_id ~ '[^[:space:]]'),
 provider_environment text not null check(provider_environment in ('sandbox','production')),
 provider_event_id text not null check(char_length(provider_event_id) between 1 and 500 and provider_event_id ~ '[^[:space:]]'),
 event_type text not null check(char_length(event_type) between 1 and 100 and event_type ~ '[^[:space:]]'),
 payload_hash text not null check(payload_hash ~ '^[0-9a-f]{64}$'),
 received_at timestamptz not null default now(),
 processed_at timestamptz,
 processing_status text not null default 'received' check(processing_status in ('received','processed','reconciliation_required','rejected')),
 constraint payment_events_replay_key unique(provider,provider_merchant_id,provider_environment,provider_event_id),
 constraint payment_events_processing_time check((processing_status='received' and processed_at is null) or (processing_status<>'received' and processed_at is not null and processed_at>=received_at))
);
create index payment_events_attempt_idx on app_private.payment_events(payment_attempt_id);
create function app_private.csa093_preserve_event_evidence() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='DELETE' then raise exception using errcode='23514',message='Payment event evidence cannot be deleted.'; end if;
 if row(new.id,new.payment_attempt_id,new.provider,new.provider_merchant_id,new.provider_environment,new.provider_event_id,new.event_type,new.payload_hash,new.received_at)
 is distinct from row(old.id,old.payment_attempt_id,old.provider,old.provider_merchant_id,old.provider_environment,old.provider_event_id,old.event_type,old.payload_hash,old.received_at) then
  raise exception using errcode='23514',message='Payment event evidence is immutable.';
 end if;
 if old.processing_status<>'received' and row(new.processing_status,new.processed_at) is distinct from row(old.processing_status,old.processed_at) then
  raise exception using errcode='23514',message='Final event processing outcome is immutable.';
 end if;
 return new;
end; $$;
create trigger payment_events_preserve_evidence before update or delete on app_private.payment_events for each row execute function app_private.csa093_preserve_event_evidence();
alter table app_private.payment_events enable row level security;
revoke all on app_private.payment_events from public,anon,authenticated,service_role;
revoke all on function app_private.csa093_preserve_event_evidence() from public,anon,authenticated,service_role;
comment on table app_private.payment_events is 'Private validated provider event ledger. Event identity must be independently verified; this table does not authenticate callbacks or grant access. No raw provider payload, card data or secret fields.';
commit;
