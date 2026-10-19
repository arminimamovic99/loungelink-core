-- Snapshot the price at order time on order_items (BUG-3).
--
-- Previously order_items only stored product_id, so every total (admin
-- revenue, waiter "Za naplatu", per-order totals) was computed by joining
-- the *current* live product price. Editing a product's price in
-- /admin/products silently changed the totals of every past order,
-- including closed/archived ones already reported on.

alter table public.order_items
add column if not exists unit_price numeric(10, 2);

-- Backfill from the current product price. product_id is "on delete
-- restrict" against products, so every historical row has a matching
-- product row to backfill from.
update public.order_items oi
set unit_price = p.price
from public.products p
where p.id = oi.product_id
  and oi.unit_price is null;

alter table public.order_items
alter column unit_price set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'order_items_unit_price_check'
      and conrelid = 'public.order_items'::regclass
  ) then
    alter table public.order_items
    add constraint order_items_unit_price_check check (unit_price >= 0);
  end if;
end $$;
