-- CSA136: no client grants; bindings require out-of-band trusted Mux attestation.
begin;
create table app_private.video_playback_bindings (
 media_asset_id uuid primary key references app_private.media_assets(id) on delete restrict,
 mux_asset_id text not null check(mux_asset_id ~ '^[A-Za-z0-9]{1,255}$'),
 playback_id text not null unique check(playback_id ~ '^[A-Za-z0-9]{1,255}$'),
 playback_policy text not null check(playback_policy='signed'),
 provider_verified_at timestamptz not null,
 provider_attestation_sha256 text not null check(provider_attestation_sha256 ~ '^[0-9a-f]{64}$'),
 revoked_at timestamptz,
 check(mux_asset_id<>playback_id)
);
alter table app_private.video_playback_bindings enable row level security;
revoke all on app_private.video_playback_bindings from public,anon,authenticated,service_role;
create function public.csa136_authorize_video(p_actor uuid,p_session_id uuid,p_aal text,p_lesson uuid,p_token_exp bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare course uuid; playback text; grant_end timestamptz; session_end timestamptz; expiry bigint; t timestamptz:=clock_timestamp();
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,false);
 if p_token_exp is null or p_token_exp<=extract(epoch from t) then raise exception using errcode='42501',message='Current token required.'; end if;
 select c.id into course from public.lessons l join public.course_sections s on s.id=l.section_id join public.courses c on c.id=s.course_id
 where l.id=p_lesson and l.lesson_type='video' and l.is_published and s.is_published and c.status='published';
 if course is null then raise exception using errcode='42501',message='Access denied.'; end if;
 perform pg_advisory_xact_lock(hashtext(p_actor::text),hashtext(course::text));
 if not app_private.csa117_has_access(p_actor,course) then raise exception using errcode='42501',message='Access denied.'; end if;
 select b.playback_id into playback from app_private.lesson_assets a
 join app_private.media_assets m on m.id=a.media_asset_id
 join app_private.video_playback_bindings b on b.media_asset_id=m.id
 where a.lesson_id=p_lesson and a.usage='video' and m.asset_type='course_video' and m.storage_provider='mux'
 and m.validation_status='validated' and m.validated_at is not null and m.deleted_at is null
 and m.external_asset_id=b.mux_asset_id and b.playback_policy='signed' and b.revoked_at is null and b.provider_verified_at<=t
 order by a.position limit 1;
 if playback is null then raise exception using errcode='42501',message='Access denied.'; end if;
 select case when bool_or(g.valid_until is null) then null else max(g.valid_until) end into grant_end
 from public.enrollment_grants g where g.user_id=p_actor and g.course_id=course and g.invalidated_at is null and g.valid_from<=t and (g.valid_until is null or g.valid_until>t)
 and (g.source_type='admin_grant' or exists(select 1 from public.orders o join app_private.verified_settlements v on v.id=g.settlement_id and v.order_id=o.id
 where o.id=g.source_order_id and o.buyer_id=p_actor and o.course_id=course and o.status='paid' and o.paid_at=g.valid_from));
 select not_after into session_end from auth.sessions where id=p_session_id and user_id=p_actor;
 expiry:=floor(least(extract(epoch from t)+300,p_token_exp,extract(epoch from grant_end),extract(epoch from session_end)));
 if expiry<=extract(epoch from clock_timestamp()) then raise exception using errcode='42501',message='Access denied.'; end if;
 return jsonb_build_object('lesson_id',p_lesson,'playback_id',playback,'expires_at',expiry);
end; $$;
revoke all on function public.csa136_authorize_video(uuid,uuid,text,uuid,bigint) from public,anon,authenticated;
grant execute on function public.csa136_authorize_video(uuid,uuid,text,uuid,bigint) to service_role;
comment on table app_private.video_playback_bindings is 'Provision only after trusted Mux API confirms asset ownership, signed playback membership and absence of public playback IDs; retain evidence digest. No application write seam.';
commit;
