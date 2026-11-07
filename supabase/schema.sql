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
-- Subscriptions and the free-plan limits.
--
-- Free plan:  up to 5 races that are not "planned", 1 photo per race.
-- Subscriber: unlimited races, up to 10 photos per race.
-- Planned races and the bucket list are always free.
-- When a subscription ends, a runner with more than 5 races keeps all of them,
-- but they are read-only (viewing and deleting work; adding and editing do not)
-- until the runner subscribes again or deletes down to 5.

create table if not exists public.subscriptions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  active boolean not null default false,
  plan text,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

drop policy if exists "read own subscription" on public.subscriptions;
create policy "read own subscription" on public.subscriptions
  for select using (user_id = auth.uid());
-- No insert/update policies: only the server (RevenueCat webhook, service role)
-- writes this table.

create or replace function public.is_subscriber(uid uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.subscriptions s
    where s.user_id = uid and s.active
      and (s.expires_at is null or s.expires_at > now())
  );
$$;

create or replace function public.enforce_race_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  lim constant int := 5;
  cnt int;
  was_counted boolean;
  will_count boolean;
begin
  -- The SQL editor and the service role are not limited.
  if auth.uid() is null or public.is_subscriber(new.user_id) then
    return new;
  end if;

  will_count := new.status <> 'planned';
  select count(*) into cnt from public.races
    where user_id = new.user_id and status <> 'planned'
      and (tg_op = 'INSERT' or id <> new.id);

  if tg_op = 'INSERT' then
    if cnt > lim then raise exception 'read_only'; end if;
    if will_count and cnt >= lim then raise exception 'free_limit'; end if;
    return new;
  end if;

  was_counted := old.status <> 'planned';
  if cnt + (case when was_counted then 1 else 0 end) > lim then
    raise exception 'read_only';
  end if;
  if will_count and not was_counted and cnt >= lim then
    raise exception 'free_limit';
  end if;
  return new;
end;
$$;

drop trigger if exists races_limit on public.races;
create trigger races_limit
  before insert or update on public.races
  for each row execute function public.enforce_race_limit();

create or replace function public.enforce_photo_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  cnt int;
  lim int;
begin
  if auth.uid() is null then return new; end if;
  lim := case when public.is_subscriber(new.user_id) then 10 else 1 end;
  select count(*) into cnt from public.race_photos where race_id = new.race_id;
  if cnt >= lim then raise exception 'photo_limit'; end if;
  return new;
end;
$$;

drop trigger if exists race_photos_limit on public.race_photos;
create trigger race_photos_limit
  before insert on public.race_photos
  for each row execute function public.enforce_photo_limit();

-- To give yourself a subscription while testing (run in the SQL editor):
--   insert into public.subscriptions (user_id, active, plan, expires_at)
--   values ('YOUR-USER-ID', true, 'test', now() + interval '30 days')
--   on conflict (user_id) do update set active = true, expires_at = excluded.expires_at;
-- Account types: free, premium (given unlimited access, e.g. testers or
-- friends) and admin (the creator). Paid subscribers stay "free" here; their
-- access comes from the subscriptions table.
alter table public.profiles
  add column if not exists account_type text not null default 'free'
  check (account_type in ('free', 'premium', 'admin'));

-- Runners must not be able to promote themselves. Only the SQL editor and the
-- service role (where auth.uid() is null) can change account_type.
create or replace function public.protect_account_type()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null then
    if tg_op = 'INSERT' then
      new.account_type := 'free';
    else
      new.account_type := old.account_type;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_account_type on public.profiles;
create trigger profiles_protect_account_type
  before insert or update on public.profiles
  for each row execute function public.protect_account_type();

-- Premium and admin accounts get the same unlimited access as subscribers.
create or replace function public.is_subscriber(uid uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = uid and p.account_type in ('premium', 'admin')
  ) or exists (
    select 1 from public.subscriptions s
    where s.user_id = uid and s.active
      and (s.expires_at is null or s.expires_at > now())
  );
$$;

-- Make yourself the admin (run once, in the SQL editor):
--   update public.profiles set account_type = 'admin'
--   where id = (select id from auth.users where email = 'YOUR-EMAIL');
-- Give a friend or tester unlimited access the same way with 'premium'.
-- The medal a runner collected at a race: gold, silver or bronze.
alter table public.races
  add column if not exists medal text check (medal in ('gold', 'silver', 'bronze'));
-- Lets a signed-in runner delete their own account. Deleting the auth user
-- removes everything that belongs to them (profile, races, photo rows,
-- bucket list, friendships, reactions, subscription row) because those tables
-- all cascade from auth.users. The app removes the stored photo files first.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
-- Yearly goals a runner sets for themselves (distance in km and number of races).
alter table public.profiles
  add column if not exists goal_km integer check (goal_km is null or (goal_km > 0 and goal_km <= 100000)),
  add column if not exists goal_races integer check (goal_races is null or (goal_races > 0 and goal_races <= 1000));
-- Goals are kept per year, so past years keep their targets and the app can
-- show a history. Any goal already saved on the profile becomes this year's.
create table if not exists public.yearly_goals (
  user_id uuid not null references auth.users (id) on delete cascade,
  year integer not null check (year between 2000 and 2100),
  goal_km integer check (goal_km is null or (goal_km > 0 and goal_km <= 100000)),
  goal_races integer check (goal_races is null or (goal_races > 0 and goal_races <= 1000)),
  primary key (user_id, year)
);

alter table public.yearly_goals enable row level security;

drop policy if exists "own goals" on public.yearly_goals;
create policy "own goals" on public.yearly_goals
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

insert into public.yearly_goals (user_id, year, goal_km, goal_races)
select id, extract(year from now())::int, goal_km, goal_races
from public.profiles
where goal_km is not null or goal_races is not null
on conflict (user_id, year) do nothing;
-- Running clubs: one official record per club, so two runners from the same
-- club end up in the same place even if one of them mistypes the name.
create extension if not exists pg_trgm;

-- A cleaned-up version of a club name used to spot duplicates: lower case, no
-- dots or punctuation, and the common words "athletic(s)", "running", "club",
-- "runners", "ac", "sac" and "rc" ignored. "Sea Point A.C" and "Sea Point
-- Athletic Club" give the same key.
create or replace function public.club_key(n text)
returns text language sql immutable as $$
  select regexp_replace(
    regexp_replace(
      regexp_replace(lower(coalesce(n, '')), '\.', '', 'g'),
      '\m(athletic|athletics|running|club|runners|ac|sac|rc)\M', ' ', 'g'),
    '[^a-z0-9]', '', 'g')
$$;

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 2 and 60),
  area text,
  province text,
  country text not null default 'South Africa',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create unique index if not exists clubs_key_unique
  on public.clubs (country, public.club_key(name));
create index if not exists clubs_name_trgm
  on public.clubs using gin (name gin_trgm_ops);

alter table public.clubs enable row level security;

drop policy if exists "clubs readable" on public.clubs;
create policy "clubs readable" on public.clubs
  for select to authenticated using (true);
-- New clubs are added through find_or_create_club below; changing or removing
-- clubs (merging duplicates) is done in the SQL editor.

alter table public.profiles
  add column if not exists club_id uuid references public.clubs (id) on delete set null;

-- Suggestions while typing: prefix and contains matches first, then similar
-- spellings. "exact" is true when the club is the same after cleaning up.
create or replace function public.search_clubs(q text)
returns table (id uuid, name text, area text, members bigint, score real, exact boolean)
language sql stable security definer set search_path = public as $$
  select c.id, c.name, c.area,
         (select count(*) from public.profiles p where p.club_id = c.id) as members,
         greatest(similarity(c.name, q),
                  similarity(public.club_key(c.name), public.club_key(q)))::real as score,
         public.club_key(c.name) = public.club_key(q) as exact
  from public.clubs c
  where auth.uid() is not null
    and char_length(btrim(q)) >= 2
    and (c.name ilike '%' || btrim(q) || '%'
         or similarity(c.name, q) > 0.3
         or similarity(public.club_key(c.name), public.club_key(q)) > 0.4)
  order by (c.name ilike btrim(q) || '%') desc, score desc, c.name
  limit 8
$$;

-- Returns the club with this name (after cleaning up), creating it if needed.
create or replace function public.find_or_create_club(p_name text, p_area text default null)
returns table (id uuid, name text)
language plpgsql security definer set search_path = public as $$
declare
  n text := btrim(p_name);
  rec public.clubs;
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  if char_length(n) < 2 or char_length(n) > 60 or public.club_key(n) = '' then
    raise exception 'invalid club name';
  end if;
  select * into rec from public.clubs c
   where c.country = 'South Africa' and public.club_key(c.name) = public.club_key(n);
  if rec.id is not null then
    return query select rec.id, rec.name;
    return;
  end if;
  insert into public.clubs (name, area, created_by)
  values (n, nullif(btrim(p_area), ''), auth.uid())
  returning * into rec;
  return query select rec.id, rec.name;
end;
$$;

revoke all on function public.search_clubs(text) from public, anon;
revoke all on function public.find_or_create_club(text, text) from public, anon;
grant execute on function public.search_clubs(text) to authenticated;
grant execute on function public.find_or_create_club(text, text) to authenticated;

-- Western Province Athletics affiliated clubs (published club list, to start
-- the list). Runners can add any club that is missing.
insert into public.clubs (name, area, province) values
  ('Airports Athletics Club', null, 'Western Cape'),
  ('Adventist Athletics Club', 'Langa, Cape Town', 'Western Cape'),
  ('Afrika Tikkun Athletics Club', 'Hyde Park, Johannesburg', 'Gauteng'),
  ('Asics Athletic Club', 'Claremont', 'Western Cape'),
  ('Atlantis Harriers A.C', 'Atlantis', 'Western Cape'),
  ('Atlantic Athletic Club', 'Clifton, Cape Town', 'Western Cape'),
  ('ATC Running Club', 'Green Point', 'Western Cape'),
  ('ARD Athletic Club', 'Kenwyn', 'Western Cape'),
  ('Aurecon W.C R/W Club', 'Cape Town', 'Western Cape'),
  ('Bellville Athletic Club (Track)', 'Bellville', 'Western Cape'),
  ('Bellville Athletic Club (Road)', 'Bellville', 'Western Cape'),
  ('Bishops Running Club', 'Rondebosch', 'Western Cape'),
  ('BOKAAP Athletics', 'Cape Town', 'Western Cape'),
  ('Bonteheuwel Athletic Club', 'Belhar', 'Western Cape'),
  ('Born 2 Run Athletic Club', 'Parklands', 'Western Cape'),
  ('Bottelary Athletics Club', 'Belhar', 'Western Cape'),
  ('Boxer Athletics Club', 'Durbanville', 'Western Cape'),
  ('Brackenfell Athletic Club', 'Brackenfell', 'Western Cape'),
  ('Brimstone Itheko S.A.C', 'Rondebosch', 'Western Cape'),
  ('Cape Multi-Sport', 'Eversdal', 'Western Cape'),
  ('Capricorn Athletic Club', 'Steenberg', 'Western Cape'),
  ('Carbineers Western Province', 'Pinelands', 'Western Cape'),
  ('Celtic Harriers', 'Clareinch', 'Western Cape'),
  ('Central Athletics Club', 'Newlands', 'Western Cape'),
  ('Century City Athletic Club', 'Century City', 'Western Cape'),
  ('Correctional Services A.C', 'Tokai', 'Western Cape'),
  ('C.P.U.T Athletic Club', 'Cape Town', 'Western Cape'),
  ('Chaeli Sports & Recreation Club', 'Plumstead', 'Western Cape'),
  ('Chillie Running Club WP', 'Parklands', 'Western Cape'),
  ('Defence Athletics Club', 'Cape Town', 'Western Cape'),
  ('Durbanville Athletic Club', 'Durbanville', 'Western Cape'),
  ('DALRRD Athletic Club WP', 'Mowbray', 'Western Cape'),
  ('Easterns Kraaifontein A.C', 'Kraaifontein', 'Western Cape'),
  ('Edgemead Runners', 'Bothasig', 'Western Cape'),
  ('Eerste River Athletic Club', 'Eerste River', 'Western Cape'),
  ('Elsies River Athletic Club', 'Matroosfontein', 'Western Cape'),
  ('Farnese Athletic Club', 'Strandfontein', 'Western Cape'),
  ('Fish Hoek A.C', 'Fish Hoek', 'Western Cape'),
  ('Fit 2000 (W.P) A.C', 'Noordhoek', 'Western Cape'),
  ('Foresters Running Club', 'Steenberg', 'Western Cape'),
  ('Goodwood Harriers Running Club', 'Goodwood', 'Western Cape'),
  ('Groot Constantia', 'Constantia', 'Western Cape'),
  ('Harfield Harriers', 'Newlands', 'Western Cape'),
  ('Helderberg Harriers', 'Somerset West', 'Western Cape'),
  ('Herbalife Sports Club', 'Fish Hoek', 'Western Cape'),
  ('Hewat Athletic Club', 'Steenberg', 'Western Cape'),
  ('Hout Bay Harriers', 'Hout Bay', 'Western Cape'),
  ('In Touch Walk / Run', 'Kuils River', 'Western Cape'),
  ('KENFAC SAC', 'Cape Town', 'Western Cape'),
  ('Khayelitsha Athletic Club', 'Khayelitsha', 'Western Cape'),
  ('Kuils River Runners Club', 'Kuils River', 'Western Cape'),
  ('Langa Athletic Club', 'Plumstead', 'Western Cape'),
  ('Lwandle Athletic Club', 'Strand', 'Western Cape'),
  ('Mamre Athletic Club', 'Mamre', 'Western Cape'),
  ('Mandela Park Running Club', 'Khayelitsha', 'Western Cape'),
  ('Manoni Sports Club', 'Khayelitsha', 'Western Cape'),
  ('Mates Mountain & Trail Enthusiast', 'Mowbray', 'Western Cape'),
  ('Mazars Athletics Club', 'Century City', 'Western Cape'),
  ('Melkbos Athletic Club', 'Melkbosstrand', 'Western Cape'),
  ('Metropolitan Athletic Club', 'Bellville', 'Western Cape'),
  ('Mfuleni Athletic Club', 'Mfuleni', 'Western Cape'),
  ('Mitchell''s Plain Titans', 'Mitchells Plain', 'Western Cape'),
  ('MSA MULTISPORT', 'Lansdowne', 'Western Cape'),
  ('Multi - Sport Maniacs', 'Table View', 'Western Cape'),
  ('Midas Spartans A.C', 'Brooklyn, Cape Town', 'Western Cape'),
  ('Murray & Roberts Running Club', 'Bedfordview', 'Gauteng'),
  ('My Training Day Athletics Club', 'Meadowridge', 'Western Cape'),
  ('Nantes Athletic Club', 'Pinelands', 'Western Cape'),
  ('Nedbank A.C', 'Kraaifontein', 'Western Cape'),
  ('Ogilvy & Mather Runners Club', 'Woodstock', 'Western Cape'),
  ('Old Mutual Athletic Club', 'Mutual Park', 'Western Cape'),
  ('Ommiedraai Friends A.C', 'Glosderry', 'Western Cape'),
  ('Open Box Running Club', 'Tokai', 'Western Cape'),
  ('Pick ''n Pay Athletic Club', 'Kenilworth', 'Western Cape'),
  ('Pinelands Athletic Club', 'Howard Place', 'Western Cape'),
  ('Parliament of RSA Athletic Club', 'Cape Town', 'Western Cape'),
  ('Phoenix Athletics Club', 'Bothasig', 'Western Cape'),
  ('Ravensmead Athletic Club', 'Ravensmead', 'Western Cape'),
  ('RCS Gugulethu A.C', 'Gugulethu', 'Western Cape'),
  ('Resbank Athletic Club', 'Cape Town', 'Western Cape'),
  ('Run / Walk for Life', 'Edgemead', 'Western Cape'),
  ('Sanlam Road Running Club', 'Highbury', 'Western Cape'),
  ('SACS Old Boys Running Club', 'Newlands', 'Western Cape'),
  ('SA Police Athletic Club', 'De Tuin', 'Western Cape'),
  ('Satori Athletic Club', 'Noordhoek', 'Western Cape'),
  ('South Peninsula AC', 'Retreat', 'Western Cape'),
  ('Somerset Striders A.C', 'Somerset West', 'Western Cape'),
  ('Southern Striders A.C', 'Bergvliet', 'Western Cape'),
  ('Spartan Harriers', 'Meadowridge', 'Western Cape'),
  ('Stragglers Athletic Club', 'Strandfontein', 'Western Cape'),
  ('Strand Athletic Club', 'Strand', 'Western Cape'),
  ('Thomas Mbiza Athletic Club', 'Simon''s Town', 'Western Cape'),
  ('Top Form Athletic Club', 'Belthorn', 'Western Cape'),
  ('Totalsports VOB Running Club', 'Constantia', 'Western Cape'),
  ('Tygerberg Athletic Club', 'Goodwood', 'Western Cape'),
  ('Ultra-Athletic Club', 'Mitchells Plain', 'Western Cape'),
  ('University of Cape Town A.C', 'Rondebosch', 'Western Cape'),
  ('University of Western Cape AC', 'Bellville', 'Western Cape'),
  ('Velocity Athletic Club', 'Pella', 'Western Cape'),
  ('Vodacom Striders W.P', 'Cape Town', 'Western Cape'),
  ('Walmers Athletics Club', 'Walmer Estate, Woodstock', 'Western Cape'),
  ('West Coast Athletic Club', 'Bloubergstrand', 'Western Cape'),
  ('Western Province Cricket Club', 'Newlands', 'Western Cape'),
  ('Wild Runner Athletic Club', 'Constantia', 'Western Cape'),
  ('Zandvlei Athletic Club', 'Muizenberg', 'Western Cape')
on conflict do nothing;

-- Existing runners who typed a club name: create or match the club and link it.
insert into public.clubs (name, created_by)
select distinct on (public.club_key(p.club)) btrim(p.club), p.id
from public.profiles p
where p.club is not null and public.club_key(p.club) <> ''
  and char_length(btrim(p.club)) between 2 and 60
on conflict do nothing;

update public.profiles p
set club_id = c.id
from public.clubs c
where p.club is not null
  and c.country = 'South Africa'
  and public.club_key(c.name) = public.club_key(p.club);
