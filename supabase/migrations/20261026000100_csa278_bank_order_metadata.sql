-- COM-013: additive owner-only order metadata. Finance queue and authority stay unchanged.
begin;
create or replace function public.csa179_read_bank_transfer(p_actor uuid,p_session_id uuid,p_aal text,p_order uuid default null,p_queue boolean default false)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb; order_row public.orders%rowtype;
begin
 if p_actor is null or p_session_id is null or p_queue is null or (p_queue and p_order is not null) or (not p_queue and p_order is null) then
 raise exception using errcode='22023',message='Invalid read request.'; end if;
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,p_queue);
 if p_queue then
 select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into result from (
 select b.id as submission_id,b.order_id,o.order_number,o.course_title_snapshot as course_title,
 o.amount_minor::text as amount_minor,o.currency_code as currency,b.status,b.submitted_at,
 b.public_rejection_reason as rejection_reason
 from public.bank_transfer_submissions b join public.orders o on o.id=b.order_id
 where b.status in ('submitted','under_review') and o.status='pending_verification' and o.buyer_id<>p_actor
 order by b.submitted_at,b.id limit 100) t;
 return jsonb_build_object('items',result);
 end if;
 select * into order_row from public.orders where id=p_order and buyer_id=p_actor and payment_method='bank_transfer';
 if not found then raise exception using errcode='P0002',message='Order unavailable.'; end if;
 select jsonb_build_object('order_id',order_row.id,'order_number',order_row.order_number,'course_title',order_row.course_title_snapshot,
 'status',b.status,'submission_id',b.id,'submitted_at',b.submitted_at,'rejection_reason',b.public_rejection_reason)
 into result from public.bank_transfer_submissions b where b.order_id=order_row.id order by b.created_at desc,b.id desc limit 1;
 return coalesce(result,jsonb_build_object('order_id',order_row.id,'order_number',order_row.order_number,'course_title',order_row.course_title_snapshot,'status','awaiting_receipt')) || jsonb_build_object('amount_minor',order_row.amount_minor::text,'currency',order_row.currency_code,'order_created_at',order_row.created_at);
end; $$;
revoke all on function public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean) from public,anon,authenticated;
grant execute on function public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean) to service_role;
commit;
