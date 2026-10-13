-- Deferred checks run after a trusted RPC has returned to the restricted API role.
-- Read invariant records as the existing trusted owner, never grant API table access.
begin;
alter function app_private.csa096_require_paid_settlement() security definer;
alter function app_private.csa096_require_paid_settlement() set search_path = '';
alter function app_private.csa096_require_grant_fulfillment() security definer;
alter function app_private.csa096_require_grant_fulfillment() set search_path = '';
revoke all on function app_private.csa096_require_paid_settlement(),
 app_private.csa096_require_grant_fulfillment() from public,anon,authenticated,service_role;
commit;
