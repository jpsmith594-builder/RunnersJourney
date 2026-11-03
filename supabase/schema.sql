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

-- Auto-create profile on signup

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profiles for any users that signed up before the trigger existed
insert into public.profiles (id, display_name)
select id, split_part(email, '@', 1) from auth.users
on conflict (id) do nothing;

-- Runner profile fields + avatar storage (see 003_profile_card.sql)
alter table public.profiles add column if not exists club text;
alter table public.profiles add column if not exists home_town text;
alter table public.profiles add column if not exists favourite_distance text;
alter table public.profiles add column if not exists avatar_path text;

-- Private bucket for profile photos; files live under <user_id>/<file>
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

drop policy if exists "own avatar read" on storage.objects;
drop policy if exists "own avatar insert" on storage.objects;
drop policy if exists "own avatar update" on storage.objects;
drop policy if exists "own avatar delete" on storage.objects;

create policy "own avatar read" on storage.objects
  for select using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own avatar insert" on storage.objects
  for insert with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own avatar update" on storage.objects
  for update using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own avatar delete" on storage.objects
  for delete using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- Gender and age (see 004_gender_age.sql)

alter table public.profiles add column if not exists gender text;
alter table public.profiles add column if not exists birth_year integer;

alter table public.profiles drop constraint if exists profiles_gender_check;
alter table public.profiles add constraint profiles_gender_check
  check (gender is null or gender in ('male', 'female', 'non_binary', 'undisclosed'));

alter table public.profiles drop constraint if exists profiles_birth_year_check;
alter table public.profiles add constraint profiles_birth_year_check
  check (birth_year is null or birth_year between 1900 and 2100);

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
