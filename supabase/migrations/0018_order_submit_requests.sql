-- Codify the order_submit_requests table (idempotency keys for createOrderAction).
--
-- This table was created directly against production (outside of migrations)
-- when the idempotency feature shipped, so this migration reproduces its
-- exact live structure rather than introducing a new design. RLS is
-- intentionally left disabled, matching production: every read/write goes
-- through the service-role admin client in app/actions/order-actions.ts,
-- never through a user-scoped client.

create table if not exists public.order_submit_requests (
  request_id uuid primary key,
  created_by_user uuid not null references auth.users(id) on delete restrict,
  table_id uuid not null references public.tables(id) on delete restrict,
  order_id uuid references public.orders(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists order_submit_requests_created_by_user_idx
on public.order_submit_requests (created_by_user, created_at desc);

create index if not exists order_submit_requests_order_id_idx
on public.order_submit_requests (order_id);
