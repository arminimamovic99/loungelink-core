-- Fix print_jobs role mismatch (BUG-2).
--
-- app/api/print/route.ts only ever allowed the 'shisha' role to queue a
-- print job (matching who can see the Print button, on /station/shisha,
-- which 'shisha' and 'admin' can both view), but this insert policy only
-- allowed 'waiter' or 'admin'. Neither role could successfully queue a job:
-- shisha passed the app check and failed RLS, admin passed RLS and failed
-- the app check. Aligning both to shisha + admin.
--
-- This only touches the INSERT policy. A separate worker (outside this
-- repo) reads/updates print_jobs via the service-role key, which bypasses
-- RLS entirely and is unaffected by this change.

drop policy if exists "print_jobs_waiter_admin_insert" on public.print_jobs;
create policy "print_jobs_shisha_admin_insert"
on public.print_jobs
for insert
with check (public.has_role('shisha') or public.has_role('admin'));
