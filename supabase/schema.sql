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

-- Friends: every runner gets a short friend code; friends can see each other's
-- runner card and races. Run once in the Supabase SQL editor (also appended to
-- schema.sql for new projects).

-- 1. Friend codes -----------------------------------------------------------
alter table public.profiles add column if not exists friend_code text;

create or replace function public.gen_friend_code()
returns text
language plpgsql
security definer set search_path = public
as $$
declare c text;
begin
  loop
    c := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    exit when not exists (select 1 from public.profiles where friend_code = c);
  end loop;
  return c;
end $$;

update public.profiles set friend_code = public.gen_friend_code() where friend_code is null;
alter table public.profiles alter column friend_code set default public.gen_friend_code();
create unique index if not exists profiles_friend_code_idx on public.profiles (friend_code);

-- 2. Friendships ------------------------------------------------------------
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester uuid not null references auth.users(id) on delete cascade,
  addressee uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  check (requester <> addressee)
);
create unique index if not exists friendships_pair_idx
  on public.friendships (least(requester, addressee), greatest(requester, addressee));

alter table public.friendships enable row level security;

drop policy if exists "see own friendships" on public.friendships;
drop policy if exists "remove own friendships" on public.friendships;
drop policy if exists "accept requests" on public.friendships;
create policy "see own friendships" on public.friendships
  for select using (auth.uid() in (requester, addressee));
create policy "remove own friendships" on public.friendships
  for delete using (auth.uid() in (requester, addressee));
create policy "accept requests" on public.friendships
  for update using (addressee = auth.uid()) with check (addressee = auth.uid());

-- 3. Helpers (security definer, so they can look across runners safely) -----
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((requester = a and addressee = b) or (requester = b and addressee = a))
  );
$$;

-- Sends a friend request using the other runner's code. If they had already
-- asked you, the request is accepted. Returns the other runner's name.
create or replace function public.add_friend_by_code(p_code text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_other uuid;
  v_name text;
  v_existing public.friendships;
begin
  select id, display_name into v_other, v_name
  from public.profiles where friend_code = upper(trim(p_code));
  if v_other is null then
    raise exception 'No runner found with that code';
  end if;
  if v_other = auth.uid() then
    raise exception 'That is your own code';
  end if;
  select * into v_existing from public.friendships
  where (requester = auth.uid() and addressee = v_other)
     or (requester = v_other and addressee = auth.uid());
  if found then
    if v_existing.status = 'pending' and v_existing.addressee = auth.uid() then
      update public.friendships set status = 'accepted' where id = v_existing.id;
    end if;
  else
    insert into public.friendships (requester, addressee) values (auth.uid(), v_other);
  end if;
  return coalesce(v_name, 'Runner');
end $$;

-- The signed-in runner's friends and pending requests, with names.
create or replace function public.my_friendships()
returns table (friendship_id uuid, other_id uuid, other_name text, status text, incoming boolean)
language sql stable
security definer set search_path = public
as $$
  select f.id,
         o.id,
         coalesce(o.display_name, 'Runner'),
         f.status,
         (f.addressee = auth.uid())
  from public.friendships f
  join public.profiles o
    on o.id = case when f.requester = auth.uid() then f.addressee else f.requester end
  where auth.uid() in (f.requester, f.addressee)
  order by f.created_at;
$$;

-- 4. Friends may read each other's profile, races and profile photo ---------
drop policy if exists "friends read profiles" on public.profiles;
drop policy if exists "friends read races" on public.races;
drop policy if exists "friends read avatars" on storage.objects;

create policy "friends read profiles" on public.profiles
  for select using (public.are_friends(auth.uid(), id));
create policy "friends read races" on public.races
  for select using (public.are_friends(auth.uid(), user_id));
create policy "friends read avatars" on storage.objects
  for select using (
    bucket_id = 'avatars'
    and public.are_friends(auth.uid(), ((storage.foldername(name))[1])::uuid)
  );

-- Reactions: friends can cheer on each other's races. Run once in the Supabase
-- SQL editor (also appended to schema.sql for new projects). Needs 006_friends.sql first.

create table if not exists public.race_reactions (
  race_id uuid not null references public.races(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  emoji text not null check (emoji in ('clap', 'fire', 'muscle', 'party')),
  created_at timestamptz not null default now(),
  primary key (race_id, user_id, emoji)
);

alter table public.race_reactions enable row level security;

-- Runner who owns the race, or their friends, can see and add reactions.
create or replace function public.can_see_race(p_race uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.races r
    where r.id = p_race
      and (r.user_id = auth.uid() or public.are_friends(auth.uid(), r.user_id))
  );
$$;

drop policy if exists "see reactions" on public.race_reactions;
drop policy if exists "add reactions" on public.race_reactions;
drop policy if exists "remove own reactions" on public.race_reactions;
create policy "see reactions" on public.race_reactions
  for select using (public.can_see_race(race_id));
create policy "add reactions" on public.race_reactions
  for insert with check (user_id = auth.uid() and public.can_see_race(race_id));
create policy "remove own reactions" on public.race_reactions
  for delete using (user_id = auth.uid());
-- Places go global: races and bucket-list items keep their own coordinates,
-- region and country, so any town in the world can be pinned on the map.
alter table public.races
  add column if not exists region text,
  add column if not exists country text;

alter table public.bucket_list
  add column if not exists lat double precision,
  add column if not exists lng double precision,
  add column if not exists region text,
  add column if not exists country text;

-- Races saved before this change were all in South Africa.
update public.races set country = 'South Africa'
  where country is null and lat is not null;
