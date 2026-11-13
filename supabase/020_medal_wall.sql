-- Medal wall: a runner's photographed medals, hung on a wall in the app.
-- Run once in the Supabase SQL editor. Safe to run again.

create table if not exists public.medal_photos (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  race_id      uuid references public.races (id) on delete set null,
  storage_path text not null,
  metal        text not null default 'gold'
               check (metal in ('gold', 'silver', 'bronze', 'titanium')),
  ribbon       text not null default 'blue'
               check (ribbon in ('blue', 'green', 'red', 'purple', 'orange',
                                 'yellow', 'pink', 'black')),
  created_at   timestamptz not null default now()
);

create index if not exists medal_photos_user_idx
  on public.medal_photos (user_id, created_at);

alter table public.medal_photos enable row level security;

-- A runner sees and changes only their own medals, and may only link a medal
-- to one of their own races.
drop policy if exists "own medals" on public.medal_photos;
create policy "own medals" on public.medal_photos
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and (
      race_id is null
      or exists (
        select 1 from public.races r
        where r.id = race_id and r.user_id = auth.uid()
      )
    )
  );

-- Free plan: 5 medals on the wall. Subscribers: up to 200.
create or replace function public.enforce_medal_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  cnt int;
  lim int;
begin
  if auth.uid() is null then return new; end if;
  lim := case when public.is_subscriber(new.user_id) then 200 else 5 end;
  select count(*) into cnt from public.medal_photos where user_id = new.user_id;
  if cnt >= lim then raise exception 'medal_limit'; end if;
  return new;
end;
$$;

drop trigger if exists medal_photos_limit on public.medal_photos;
create trigger medal_photos_limit
  before insert on public.medal_photos
  for each row execute function public.enforce_medal_limit();

-- Private bucket for the medal pictures: <user_id>/<file>.png, small PNG or
-- JPEG only (the app sends an 800 px circle cut-out).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('medal-photos', 'medal-photos', false, 2097152,
        array['image/png', 'image/jpeg'])
on conflict (id) do update
  set file_size_limit = 2097152,
      allowed_mime_types = array['image/png', 'image/jpeg'];

drop policy if exists "own medal files read" on storage.objects;
drop policy if exists "own medal files write" on storage.objects;
drop policy if exists "own medal files delete" on storage.objects;

create policy "own medal files read" on storage.objects
  for select using (
    bucket_id = 'medal-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own medal files write" on storage.objects
  for insert with check (
    bucket_id = 'medal-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own medal files delete" on storage.objects
  for delete using (
    bucket_id = 'medal-photos' and (storage.foldername(name))[1] = auth.uid()::text);
