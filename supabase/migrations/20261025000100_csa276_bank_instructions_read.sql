-- COM-012: recover the immutable destination bound to an unpaid bank order.
begin;
create function public.csa276_read_bank_instructions(p_actor uuid,p_session_id uuid,p_aal text,p_order uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if p_actor is null or p_session_id is null or p_order is null then
   raise exception using errcode='22023',message='Invalid read request.';
 end if;
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,false);
 select jsonb_build_object('order_id',o.id,'order_number',o.order_number,
   'course',jsonb_build_object('id',o.course_id,'title',o.course_title_snapshot),
   'amount_minor',o.amount_minor,'currency_code',o.currency_code,
   'payment_method',o.payment_method,'status',o.status,
   'next_action','show_bank_instructions','bank_instructions',i.instruction_snapshot)
 into result from public.orders o join app_private.order_bank_instructions i on i.order_id=o.id
 where o.id=p_order and o.buyer_id=p_actor and o.payment_method='bank_transfer' and o.status='pending_payment';
 if result is null then raise exception using errcode='P0002',message='Order unavailable.'; end if;
 return result;
end; $$;
revoke all on function public.csa276_read_bank_instructions(uuid,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.csa276_read_bank_instructions(uuid,uuid,text,uuid) to service_role;
commit;
