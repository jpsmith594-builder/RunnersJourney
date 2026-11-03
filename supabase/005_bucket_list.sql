-- Race bucket list: races a runner wants to complete one day.
-- Run once in the Supabase SQL editor (also appended to schema.sql for new projects).

create table if not exists public.bucket_list (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  name text not null,
  location_name text,
  distance_km numeric,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists bucket_list_user_idx on public.bucket_list (user_id, created_at);

alter table public.bucket_list enable row level security;

drop policy if exists "own bucket list" on public.bucket_list;
create policy "own bucket list" on public.bucket_list
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
