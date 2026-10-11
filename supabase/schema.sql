-- Running Journey app: Supabase schema (v1)
-- Run in Supabase SQL editor. Auth uses Supabase Auth (auth.users).

create extension if not exists "pgcrypto";

-- Runner profile
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  home_lat double precision,
  home_lng double precision,
  hemisphere text not null default 'south' check (hemisphere in ('north','south')),
  created_at timestamptz not null default now()
);

-- A race (a POI on the journey trail)
create table public.races (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  race_date date not null,
  status text not null default 'planned' check (status in ('planned','completed','dnf','dns')),
  distance_km numeric(6,2),
  finish_time_seconds integer,
  overall_position integer,
  age_group_position integer,
  location_name text,
  lat double precision,
  lng double precision,
  notes text,
  created_at timestamptz not null default now()
);
create index races_user_date_idx on public.races (user_id, race_date);

-- Photos attached to a race (files live in Storage bucket 'race-photos')
create table public.race_photos (
  id uuid primary key default gen_random_uuid(),
  race_id uuid not null references public.races(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  caption text,
  created_at timestamptz not null default now()
);
create index race_photos_race_idx on public.race_photos (race_id);

-- Row Level Security: each runner only sees their own journey
alter table public.profiles enable row level security;
alter table public.races enable row level security;
alter table public.race_photos enable row level security;

create policy "own profile" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());
create policy "own races" on public.races
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own photos" on public.race_photos
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Storage bucket (private); files stored under <user_id>/<race_id>/<file>
insert into storage.buckets (id, name, public)
values ('race-photos', 'race-photos', false)
on conflict (id) do nothing;

create policy "own photo files read" on storage.objects
  for select using (bucket_id = 'race-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photo files write" on storage.objects
  for insert with check (bucket_id = 'race-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photo files delete" on storage.objects
  for delete using (bucket_id = 'race-photos' and (storage.foldername(name))[1] = auth.uid()::text);
